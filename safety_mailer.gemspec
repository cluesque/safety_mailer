Gem::Specification.new do |s|
  s.name        = "safety_mailer"
  s.version     = "0.0.3"
  s.author      = "Bill Kirtley"
  s.email       = "bill.kirtley@gmail.com"
  s.homepage    = "http://github.com/cluesque/safety_mailer"
  s.summary     = "Restrict email sent by your application to only approved domains or accounts."
  s.description = "Specify a domain (or set of domains, or magic word in email address) email is allowed to go to, and email to all other domains is silently dropped. Useful for testing and staging environments."

  s.files        = Dir["lib/**/*", "[A-Z]*"] - ["Gemfile.lock"]
  s.require_path = "lib"
end