# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'safety_mailer/version'

Gem::Specification.new do |s|
  s.name        = "safety_mailer"
  s.version     = SafetyMailer::VERSION
  s.platform    = Gem::Platform::RUBY
  s.author      = "Bill Kirtley"
  s.email       = "bill.kirtley@gmail.com"
  s.homepage    = "http://github.com/cluesque/safety_opener"
  s.summary     = "Restrict email sent by your application to only approved domains or accounts."
  s.description = "Specify a domain (or set of domains, or magic word in email address) email is allowed to go to, and email to all other domains is silently dropped. Useful for testing and staging environments."

  s.files        = Dir["lib/**/*", "[A-Z]*"] - ["Gemfile.lock"]
  s.require_path = "lib"
end