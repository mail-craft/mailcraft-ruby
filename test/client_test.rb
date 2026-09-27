# frozen_string_literal: true

require 'minitest/autorun'
require 'json'
require 'socket'
require_relative '../lib/mailcraft'

class FakeTransport
  attr_reader :calls

  def initialize(status, body)
    @status = status
    @body = body
    @calls = []
  end

  def call(method, uri, headers, body)
    @calls << { method: method, uri: uri, headers: headers, body: body && JSON.parse(body) }
    [@status, @body]
  end

  def last
    @calls.last
  end
end

class ClientTest < Minitest::Test
  def client_with(status, body)
    transport = FakeTransport.new(status, body)
    [MailCraft::Client.new(api_key: 'mc_test_key', base_url: 'https://api.test/v1/', transport: transport), transport]
  end

  def test_send_email
    client, transport = client_with(202, '{"data":{"id":"em_1","status":"queued"}}')

    result = client.emails.send(from: 'hello@yourdomain.com', to: 'person@example.com',
                                subject: 'Welcome!', html: '<p>Hi</p>')

    call = transport.last
    assert_equal :post, call[:method]
    assert_equal 'https://api.test/v1/emails', call[:uri].to_s
    assert_equal 'Bearer mc_test_key', call[:headers]['Authorization']
    assert_equal "mailcraft-ruby/#{MailCraft::VERSION}", call[:headers]['User-Agent']
    assert_equal ['person@example.com'], call[:body]['to']
    refute call[:body].key?('text'), 'nil fields should be omitted'
    assert_equal 'em_1', result['data']['id']
  end

  def test_list_sends_limit_and_skips_nil_query
    client, transport = client_with(200, '{"data":[]}')

    client.contacts.list(limit: 5)
    assert_equal 'limit=5', transport.last[:uri].query

    client.contacts.list
    assert_nil transport.last[:uri].query
  end

  def test_validate_escapes_email
    client, transport = client_with(200, '{"valid":true}')

    client.emails.validate('a+b@example.com')

    assert_equal '/v1/emails/validate', transport.last[:uri].path
    assert_equal 'email=a%2Bb%40example.com', transport.last[:uri].query
  end

  def test_template_update_uses_patch_with_only_given_fields
    client, transport = client_with(200, '{"data":{"id":3}}')

    client.templates.update(3, subject: 'New')

    assert_equal :patch, transport.last[:method]
    assert_equal '/v1/templates/3', transport.last[:uri].path
    assert_equal({ 'subject' => 'New' }, transport.last[:body])
  end

  def test_contact_list_membership
    client, transport = client_with(204, '')

    client.contacts.add_to_lists('c_1', [1, 2])
    assert_equal '/v1/contacts/c_1/lists', transport.last[:uri].path
    assert_equal({ 'list_ids' => [1, 2] }, transport.last[:body])

    assert_nil client.contacts.remove_from_list('c_1', 2)
    assert_equal :delete, transport.last[:method]
    assert_equal '/v1/contacts/c_1/lists/2', transport.last[:uri].path
  end

  def test_metrics_and_reputation
    client, transport = client_with(200, '{"data":[]}')

    client.metrics.get(start_date: '2026-01-01', end_date: '2026-01-31')
    assert_equal 'start_date=2026-01-01&end_date=2026-01-31', transport.last[:uri].query

    client.metrics.reputation
    assert_equal '/v1/reputation', transport.last[:uri].path
  end

  def test_template_folders_use_hyphenated_path
    client, transport = client_with(201, '{"data":{"id":1}}')

    client.template_folders.create(name: 'Onboarding')

    assert_equal '/v1/template-folders', transport.last[:uri].path
  end

  def test_business_rule_error
    client, = client_with(402, '{"error":{"type":"plan_limit_reached","message":"Monthly limit reached."}}')

    error = assert_raises(MailCraft::ApiError) { client.campaigns.send(4) }

    assert_equal 402, error.status
    assert_equal 'plan_limit_reached', error.type
    assert_equal 'Monthly limit reached.', error.message
  end

  def test_validation_error
    client, = client_with(422, '{"message":"The email field is required.","errors":{"email":["The email field is required."]}}')

    error = assert_raises(MailCraft::ApiError) { client.contacts.upsert(email: '') }

    assert_equal 422, error.status
    assert_nil error.type
    assert_equal ['The email field is required.'], error.errors['email']
  end

  def test_unparseable_error_body
    client, = client_with(502, '<html>Bad gateway</html>')

    error = assert_raises(MailCraft::ApiError) { client.lists.list }

    assert_equal 502, error.status
    assert_equal 'Request failed with status 502', error.message
  end

  def test_requires_api_key
    assert_raises(ArgumentError) { MailCraft::Client.new(api_key: '') }
  end

  def test_default_transport_makes_a_real_request
    server = TCPServer.new('127.0.0.1', 0)
    port = server.addr[1]
    received = nil

    thread = Thread.new do
      socket = server.accept
      request_line = socket.gets
      headers = {}
      while (line = socket.gets) && line != "\r\n"
        key, value = line.split(': ', 2)
        headers[key.downcase] = value.strip
      end
      body = socket.read(headers['content-length'].to_i)
      received = { request_line: request_line, headers: headers, body: body }
      response = '{"data":{"id":"c_1"}}'
      socket.write("HTTP/1.1 201 Created\r\nContent-Type: application/json\r\nContent-Length: #{response.bytesize}\r\nConnection: close\r\n\r\n#{response}")
      socket.close
    end

    client = MailCraft::Client.new(api_key: 'mc_test_key', base_url: "http://127.0.0.1:#{port}/v1")
    result = client.contacts.upsert(email: 'ada@example.com', first_name: 'Ada')
    thread.join

    assert_equal 'c_1', result['data']['id']
    assert_equal "POST /v1/contacts HTTP/1.1\r\n", received[:request_line]
    assert_equal 'Bearer mc_test_key', received[:headers]['authorization']
    assert_equal({ 'email' => 'ada@example.com', 'first_name' => 'Ada' }, JSON.parse(received[:body]))
  ensure
    server&.close
  end
end
