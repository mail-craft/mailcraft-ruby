# frozen_string_literal: true

module MailCraft
  # Raised for any non-2xx response from the MailCraft API.
  #
  # Covers both error shapes the API returns: {"error" => {"type", "message"}}
  # for business-rule failures (plan limits, suppressed recipients, ...), and
  # {"message", "errors" => {"field" => [...]}} for validation failures (422).
  class ApiError < StandardError
    # @return [Integer] the HTTP status, e.g. 402 or 422
    attr_reader :status
    # @return [String, nil] the business-rule error type, e.g. "plan_limit_reached"
    attr_reader :type
    # @return [Hash{String => Array<String>}] field errors for 422 responses
    attr_reader :errors

    def initialize(message, status:, type: nil, errors: {})
      super(message)
      @status = status
      @type = type
      @errors = errors
    end

    # @param status [Integer]
    # @param body [Hash, nil] the decoded response body
    def self.from_response(status, body)
      body = {} unless body.is_a?(Hash)

      if body['error'].is_a?(Hash)
        new(body['error']['message'] || "Request failed with status #{status}",
            status: status, type: body['error']['type'])
      else
        new(body['message'] || "Request failed with status #{status}",
            status: status, errors: body['errors'] || {})
      end
    end
  end
end
