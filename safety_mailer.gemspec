# frozen_string_literal: true

require_relative 'lib/safety_mailer/version'

Gem::Specification.new do |spec|
  spec.name = 'safety_mailer'
  spec.version = SafetyMailer::VERSION
  spec.authors = ['Bill Kirtley']
  spec.email = ['bill.kirtley@gmail.com']

  spec.summary = 'Restrict email sent by your application to only approved domains or accounts.'
  spec.description = 'Specify a domain (or set of domains, or magic word in email address) email is allowed to go to, and email to all other domains is silently dropped. Useful for testing and staging environments.'
  spec.homepage = 'http://github.com/cluesque/safety_mailer'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.5'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'http://github.com/cluesque/safety_mailer'
  spec.metadata['changelog_uri'] = 'http://github.com/cluesque/safety_mailer/blob/master/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
