# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

module MailCraft
  # Sends requests to the API and decodes responses. The transport is any
  # object responding to #call(method, uri, headers, body) and returning
  # [status, body_string], so tests can swap out the network.
  class HttpClient
    DEFAULT_BASE_URL = 'https://api.mailcraft.host/v1'

    def initialize(api_key:, base_url: DEFAULT_BASE_URL, timeout: 30, transport: nil)
      @api_key = api_key
      @base_url = base_url.chomp('/')
      @transport = transport || NetHttpTransport.new(timeout: timeout)
    end

    def get(path, query = {})
      request(:get, path, query: query)
    end

    def post(path, body = nil)
      request(:post, path, body: body)
    end

    def patch(path, body = nil)
      request(:patch, path, body: body)
    end

    def delete(path)
      request(:delete, path)
      nil
    end

    private

    def request(method, path, query: {}, body: nil)
      uri = URI("#{@base_url}#{path}")
      query = compact(query)
      uri.query = URI.encode_www_form(query) unless query.empty?

      headers = {
        'Authorization' => "Bearer #{@api_key}",
        'Accept' => 'application/json',
        'User-Agent' => "mailcraft-ruby/#{VERSION}",
      }
      payload = nil
      unless body.nil?
        headers['Content-Type'] = 'application/json'
        payload = JSON.generate(compact(body))
      end

      status, raw = @transport.call(method, uri, headers, payload)
      decoded = decode(raw)

      raise ApiError.from_response(status, decoded) if status >= 400

      decoded
    end

    def decode(raw)
      return nil if raw.nil? || raw.strip.empty?

      JSON.parse(raw)
    rescue JSON::ParserError
      nil
    end

    def compact(hash)
      hash.reject { |_key, value| value.nil? }
    end
  end

  # The default transport, built on Net::HTTP from the standard library.
  class NetHttpTransport
    METHODS = {
      get: Net::HTTP::Get,
      post: Net::HTTP::Post,
      patch: Net::HTTP::Patch,
      delete: Net::HTTP::Delete,
    }.freeze

    def initialize(timeout: 30)
      @timeout = timeout
    end

    def call(method, uri, headers, body)
      request = METHODS.fetch(method).new(uri, headers)
      request.body = body if body

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https',
                                                     open_timeout: @timeout, read_timeout: @timeout) do |http|
        http.request(request)
      end

      [response.code.to_i, response.body]
    end
  end
end
