# mailcraft-ruby

Official Ruby SDK for the [MailCraft](https://mailcraft.host) email API: transactional email, contacts, lists, segments, templates, campaigns, webhooks and more.

Requires Ruby 3.0+. No runtime dependencies (built on `Net::HTTP`).

## Install

```bash
gem install mailcraft
```

Or in your Gemfile:

```ruby
gem 'mailcraft'
```

## Quick start

```ruby
require 'mailcraft'

mailcraft = MailCraft::Client.new(api_key: ENV['MAILCRAFT_API_KEY'])

email = mailcraft.emails.send(
  from: 'hello@yourdomain.com',
  to: ['person@example.com'],   # a string or an array of addresses
  subject: 'Welcome!',
  html: '<p>Thanks for signing up.</p>'
)
puts email['data']['id']
```

Create an API key under **Settings → API keys** in your MailCraft dashboard.

```ruby
mailcraft.contacts.upsert(email: 'ada@example.com', first_name: 'Ada', properties: { plan: 'pro' })
```

## Resources

Every MailCraft SDK has the same resources and methods:

| Resource | Methods |
| --- | --- |
| `emails` | `send`, `list`, `get`, `validate` |
| `domains` | `create`, `list`, `get`, `verify`, `delete` |
| `senders` | `create`, `list`, `get`, `delete` |
| `contacts` | `upsert`, `list`, `get`, `delete`, `unsubscribe`, `add_to_lists`, `lists`, `remove_from_list` |
| `lists` | `create`, `list`, `get`, `delete` |
| `segments` | `create`, `list`, `get`, `delete` |
| `properties` | `create`, `list`, `delete` |
| `templates` | `create`, `list`, `get`, `update`, `delete` |
| `template_folders` | `create`, `list`, `delete` |
| `campaigns` | `create`, `list`, `get`, `send`, `delete` |
| `webhooks` | `create`, `list`, `delete` |
| `suppressions` | `add`, `list`, `delete` |
| `metrics` | `get`, `reputation` |

Responses are the API's JSON as Hashes with string keys. See the [API reference](https://docs.mailcraft.host/api-reference) for every field.

## Errors

Any non-2xx response raises `MailCraft::ApiError`:

```ruby
begin
  mailcraft.domains.create(name: 'acme.com')
rescue MailCraft::ApiError => error
  error.status  # e.g. 402
  error.type    # e.g. "plan_limit_reached" (business-rule errors)
  error.errors  # field errors for 422 validation failures
end
```

## Options

```ruby
MailCraft::Client.new(
  api_key: 'sk_live_...',
  base_url: 'https://api.mailcraft.host/v1', # override for staging or self-hosting
  timeout: 30                                # seconds
)
```

## Development

```bash
ruby -Ilib test/client_test.rb
```

The tests run the real client, both with a fake transport and against a local TCP server through `Net::HTTP`.

## License

MIT
