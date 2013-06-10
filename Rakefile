#!/usr/bin/env rake
require "bundler/gem_tasks"
require 'rspec/core/rake_task'
Bundler::GemHelper.install_tasks

task :console do
  Rake::Task["build"].invoke
  Rake::Task["install"].invoke
  puts "Loading development console..."
  system("irb -r safety_mailer")
end

task :help do
  puts "Available rake tasks: "
  puts "rake console - Run a IRB console with all enviroment loaded"
  puts "rake spec - Run specs"
end

task :spec do
  desc "Run all specs with rcov"
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = "spec/**/*_spec.rb"
  end
end

task :default => [:spec]
