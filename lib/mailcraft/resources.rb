# frozen_string_literal: true

require 'erb'

module MailCraft
  # Resource classes, one per API section. Every method returns the API's
  # decoded JSON (a Hash), or nil for deletes.
  module Resources
    class Base
      def initialize(http)
        @http = http
      end

      private

      def escape(segment)
        ERB::Util.url_encode(segment.to_s)
      end
    end

    class Emails < Base
      # Sends a transactional email. `to` may be a string or an array.
      # Note: this shadows Object#send on this object; use #__send__ for reflection.
      def send(from:, to:, subject:, html: nil, text: nil, cc: nil, bcc: nil, reply_to: nil, headers: nil, tags: nil)
        @http.post('/emails', {
                     from: from, to: Array(to), subject: subject, html: html, text: text,
                     cc: cc, bcc: bcc, reply_to: reply_to, headers: headers, tags: tags,
                   })
      end

      def list(limit: nil)
        @http.get('/emails', limit: limit)
      end

      def get(id)
        @http.get("/emails/#{escape(id)}")
      end

      # Checks an address's format, MX records and disposable domain, without sending.
      def validate(email)
        @http.get('/emails/validate', email: email)
      end
    end

    class Domains < Base
      def create(name:, region: nil)
        @http.post('/domains', { name: name, region: region })
      end

      def list
        @http.get('/domains')
      end

      def get(id)
        @http.get("/domains/#{escape(id)}")
      end

      def verify(id)
        @http.post("/domains/#{escape(id)}/verify")
      end

      def delete(id)
        @http.delete("/domains/#{escape(id)}")
      end
    end

    class Senders < Base
      def create(domain_id:, email:, name:, reply_to: nil)
        @http.post('/senders', { domain_id: domain_id, email: email, name: name, reply_to: reply_to })
      end

      def list
        @http.get('/senders')
      end

      def get(id)
        @http.get("/senders/#{escape(id)}")
      end

      def delete(id)
        @http.delete("/senders/#{escape(id)}")
      end
    end

    class Contacts < Base
      # Creates a contact, or updates it if one exists for this email.
      def upsert(email:, first_name: nil, last_name: nil, status: nil, properties: nil)
        @http.post('/contacts', {
                     email: email, first_name: first_name, last_name: last_name,
                     status: status, properties: properties,
                   })
      end

      def list(limit: nil)
        @http.get('/contacts', limit: limit)
      end

      def get(id)
        @http.get("/contacts/#{escape(id)}")
      end

      def delete(id)
        @http.delete("/contacts/#{escape(id)}")
      end

      def unsubscribe(id)
        @http.post("/contacts/#{escape(id)}/unsubscribe")
      end

      def add_to_lists(id, list_ids)
        @http.post("/contacts/#{escape(id)}/lists", { list_ids: list_ids })
      end

      def lists(id)
        @http.get("/contacts/#{escape(id)}/lists")
      end

      def remove_from_list(id, list_id)
        @http.delete("/contacts/#{escape(id)}/lists/#{escape(list_id)}")
      end
    end

    class Lists < Base
      def create(name:, description: nil, type: nil, segment_id: nil)
        @http.post('/lists', { name: name, description: description, type: type, segment_id: segment_id })
      end

      def list
        @http.get('/lists')
      end

      def get(id)
        @http.get("/lists/#{escape(id)}")
      end

      def delete(id)
        @http.delete("/lists/#{escape(id)}")
      end
    end

    class Segments < Base
      def create(name:, filters:, description: nil)
        @http.post('/segments', { name: name, description: description, filters: filters })
      end

      def list
        @http.get('/segments')
      end

      def get(id)
        @http.get("/segments/#{escape(id)}")
      end

      def delete(id)
        @http.delete("/segments/#{escape(id)}")
      end
    end

    class Properties < Base
      def create(key:, label:, type:, default_value: nil)
        @http.post('/properties', { key: key, label: label, type: type, default_value: default_value })
      end

      def list
        @http.get('/properties')
      end

      def delete(id)
        @http.delete("/properties/#{escape(id)}")
      end
    end

    class Templates < Base
      def create(name:, subject:, **fields)
        @http.post('/templates', { name: name, subject: subject, **fields })
      end

      def list
        @http.get('/templates')
      end

      def get(id)
        @http.get("/templates/#{escape(id)}")
      end

      # Each save becomes a new version. Pass only the fields to change.
      def update(id, **fields)
        @http.patch("/templates/#{escape(id)}", fields)
      end

      def delete(id)
        @http.delete("/templates/#{escape(id)}")
      end
    end

    class TemplateFolders < Base
      def create(name:)
        @http.post('/template-folders', { name: name })
      end

      def list
        @http.get('/template-folders')
      end

      def delete(id)
        @http.delete("/template-folders/#{escape(id)}")
      end
    end

    class Campaigns < Base
      def create(name:, subject:, template_id:, sender_id:, list_id: nil, segment_id: nil)
        @http.post('/campaigns', {
                     name: name, subject: subject, template_id: template_id,
                     sender_id: sender_id, list_id: list_id, segment_id: segment_id,
                   })
      end

      def list
        @http.get('/campaigns')
      end

      def get(id)
        @http.get("/campaigns/#{escape(id)}")
      end

      def send(id)
        @http.post("/campaigns/#{escape(id)}/send")
      end

      def delete(id)
        @http.delete("/campaigns/#{escape(id)}")
      end
    end

    class Webhooks < Base
      def create(url:, events:, description: nil)
        @http.post('/webhooks', { url: url, events: events, description: description })
      end

      def list
        @http.get('/webhooks')
      end

      def delete(id)
        @http.delete("/webhooks/#{escape(id)}")
      end
    end

    class Suppressions < Base
      def add(email:, reason: nil)
        @http.post('/suppressions', { email: email, reason: reason })
      end

      def list(limit: nil)
        @http.get('/suppressions', limit: limit)
      end

      def delete(id)
        @http.delete("/suppressions/#{escape(id)}")
      end
    end

    class Metrics < Base
      # Dates are "YYYY-MM-DD" strings.
      def get(start_date: nil, end_date: nil)
        @http.get('/metrics', start_date: start_date, end_date: end_date)
      end

      def reputation
        @http.get('/reputation')
      end
    end
  end
end
