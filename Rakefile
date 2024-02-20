# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'redis_set_store'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bundler/audit/task'
require 'appraisal/task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Bundler::Audit::Task.new
Appraisal::Task.new

# Remove default and replace with a series of test tasks
task default: []
Rake::Task[:default].clear

if !ENV['APPRAISAL_INITIALIZED'] && !ENV['TRAVIS']
  task default: %w[rubocop bundle:audit appraisal]
else
  task default: :spec
end

desc "Push redis_set_store-#{RedisSetStore::VERSION}.gem to Gemfury.com"
task :gemfury do
  package = "pkg/redis_set_store-#{RedisSetStore::VERSION}.gem"
  if File.exist? package
    system "fury push #{package} --as keylimetoolbox"
  else
    warn "E: gem '#{package}' not found."
    exit 1
  end
end

# Don't push changes to rubygems with `gem push`, because we use gemfury
ENV['gem_push'] = 'no'

desc 'Release to Gemfury'
task :release do
  Rake::Task[:gemfury].invoke
end
