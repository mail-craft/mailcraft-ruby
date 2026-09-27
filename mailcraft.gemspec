require_relative 'lib/mailcraft/version'

Gem::Specification.new do |spec|
  spec.name          = 'mailcraft'
  spec.version       = MailCraft::VERSION
  spec.authors       = ['MailCraft']
  spec.summary       = 'Official Ruby SDK for the MailCraft email API'
  spec.description   = 'Transactional email, SMTP relay, marketing campaigns, automations, and contact management.'
  spec.homepage      = 'https://github.com/mail-craft/mailcraft-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0'
  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']
  spec.add_development_dependency 'minitest', '~> 5.0'
end
