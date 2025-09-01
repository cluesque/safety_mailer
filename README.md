# SafetyMailer

![Logo](assets/logo_ruby_hardhat.png)

Restrict email sent by your application to only approved domains or accounts.

Specify a domain (or set of domains, or magic word in email address) email is allowed to go to, and email to all other domains is silently dropped.

This is useful for testing or staging environments where you want to be certain email to real customers doesn't escape the lab.

Layered on the Mail gem, so Rails >= 3.0 applications (as well as plain ruby apps) can use safety_mailer.

## Installation

Add the gem to your +Gemfile+, specifying groups (probably not production) to include it in.

```ruby
gem "safety_mailer", :group => :development
```

Don't forget to `bundle install` to install

In your environment file `config/environments/development.rb` configure it, and some regular expressions.

```ruby
config.action_mailer.delivery_method = :safety_mailer
config.action_mailer.safety_mailer_settings = {
  allowed_matchers: [ /mydomain.com/, /mytestacct@gmail.com/, /\+safety_mailer@/ ],
  delivery_method: :smtp,
  delivery_method_settings: {
    address: "smtp.mydomain.com",
    port: 25,
    domain: "mydomain.com",
    authentication: :plain,
    user_name: "mydomain_mailer@mydomain.com",
    password: "password"
  }
}
```

## Logging

SafetyMailer supports custom logging to help you monitor email filtering decisions. By default, SafetyMailer will automatically use `Rails.logger` if available, or remain silent if no logger is configured.

### Rails Applications

In Rails applications, SafetyMailer automatically uses `Rails.logger` by default. You'll see log messages like:

```
SafetyMailer: Processing 3 recipient(s) - 2 allowed, 1 suppressed
SafetyMailer: Allowed delivery for user@mydomain.com
SafetyMailer: Suppressed delivery for user@external.com (no matching allowed pattern)
SafetyMailer: Delivering email to 2 allowed recipient(s)
```

### Custom Logger Configuration

You can specify a custom logger in your configuration:

```ruby
require 'logger'

# Create a custom logger
safety_logger = Logger.new(Rails.root.join('log', 'safety_mailer.log'))

config.action_mailer.delivery_method = :safety_mailer
config.action_mailer.safety_mailer_settings = {
  allowed_matchers: [ /mydomain.com/, /mytestacct@gmail.com/ ],
  logger: safety_logger,  # Custom logger
  delivery_method: :smtp,
  # ... other settings
}
```

### Disabling Logging

To disable logging entirely, set the logger to `nil`:

```ruby
config.action_mailer.safety_mailer_settings = {
  allowed_matchers: [ /mydomain.com/ ],
  logger: nil,  # Disable all logging
  delivery_method: :smtp,
  # ... other settings
}
```

### Non-Rails Applications

For non-Rails applications, SafetyMailer remains silent by default. You can enable logging by providing a custom logger:

```ruby
require "safety_mailer"
require "logger"

# Configure with custom logger
custom_logger = Logger.new(STDOUT)

Mail.defaults do
  delivery_method SafetyMailer::Carrier, {
    allowed_matchers: [ /mydomain.com/ ],
    logger: custom_logger,
    delivery_method: :smtp
  }
end
```

Now, email to `anyone@mydomain.com`, `mytestacct@gmail.com`, `bob+safety_mailer@yahoo.com` all get sent, and email to other recipients (like the real users in the production database you copied to a test server) is suppressed.

## Non-Rails

Any user of the Mail gem can configure safety_mailer:

```ruby
require "safety_mailer"
Mail.defaults do
delivery_method SafetyMailer::Carrier, {
... same settings as above
}
end
```

## Non-Mail

If you're not using the Mail gem (or use it sometimes but want to use the same logic / configuration in other contexts), you can filter directly:

```
filtered_array = SafetyMailer::Carrier.new(ActionMailer::Base.safety_mailer_settings).filter(unfiltered_email_addresses)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cluesque/safety_mailer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/cluesque/safety_mailer/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SafetyMailer project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/cluesque/safety_mailer/blob/main/CODE_OF_CONDUCT.md).
