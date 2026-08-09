require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc 'Check the gem against the live IANA ACME error registry'
task :spec_iana_registry do
  sh({ 'RUN_IANA_REGISTRY_SPEC' => '1' }, 'bundle exec rspec spec/iana_registry_spec.rb')
end

task default: [:spec]
