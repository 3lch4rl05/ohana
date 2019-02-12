require 'rake'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'yard'
require 'bundler/gem_tasks'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
end

RuboCop::RakeTask.new(:rubocop) do |t|
  t.patterns = ['bin/*', 'lib/**/*.rb', '*.gemspec']
end

YARD::Rake::YardocTask.new

desc 'Run tests'
task tests: %i[rubocop spec]

desc 'Run tests, build, generate docs'
task prepare_install: %i[tests yard build]

desc 'Do it all!'
task all: %i[prepare_install install]

desc 'Default'
task default: %i[all]
