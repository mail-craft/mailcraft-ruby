# frozen_string_literal: true

require_relative 'mailcraft/version'
require_relative 'mailcraft/error'
require_relative 'mailcraft/http_client'
require_relative 'mailcraft/resources'

# Official Ruby SDK for the MailCraft email API.
#
#   mailcraft = MailCraft::Client.new(api_key: ENV['MAILCRAFT_API_KEY'])
#   mailcraft.emails.send(from: 'hello@yourdomain.com', to: 'person@example.com',
#                         subject: 'Welcome!', html: '<p>Thanks for signing up.</p>')
module MailCraft
  class Client
    attr_reader :emails, :domains, :senders, :contacts, :lists, :segments, :properties,
                :templates, :template_folders, :campaigns, :webhooks, :suppressions, :metrics

    # @param api_key [String] create one under Settings > API keys
    # @param base_url [String] override for staging or self-hosting
    # @param timeout [Numeric] seconds
    # @param transport [#call, nil] replaces the HTTP layer (used in tests)
    def initialize(api_key:, base_url: HttpClient::DEFAULT_BASE_URL, timeout: 30, transport: nil)
      if api_key.nil? || api_key.to_s.empty?
        raise ArgumentError, 'An API key is required. Find yours under Settings > API Keys.'
      end

      http = HttpClient.new(api_key: api_key, base_url: base_url, timeout: timeout, transport: transport)

      @emails = Resources::Emails.new(http)
      @domains = Resources::Domains.new(http)
      @senders = Resources::Senders.new(http)
      @contacts = Resources::Contacts.new(http)
      @lists = Resources::Lists.new(http)
      @segments = Resources::Segments.new(http)
      @properties = Resources::Properties.new(http)
      @templates = Resources::Templates.new(http)
      @template_folders = Resources::TemplateFolders.new(http)
      @campaigns = Resources::Campaigns.new(http)
      @webhooks = Resources::Webhooks.new(http)
      @suppressions = Resources::Suppressions.new(http)
      @metrics = Resources::Metrics.new(http)
    end
  end
end
