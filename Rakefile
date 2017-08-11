# frozen_string_literal: true

require "bundler/gem_tasks"
require "redis_set_store"
require "rspec/core/rake_task"
require "rubocop/rake_task"
require "bundler/audit/task"
require "appraisal/task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new
Bundler::Audit::Task.new
Appraisal::Task.new

# Remove default and replace with a series of test tasks
task default: []
Rake::Task[:default].clear

if !ENV["APPRAISAL_INITIALIZED"] && !ENV["TRAVIS"]
  task default: %w[rubocop bundle:audit appraisal]
else
  task default: :spec
end
