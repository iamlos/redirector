require 'bundler/setup'

Bundler::GemHelper.install_tasks

# Test task
require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end