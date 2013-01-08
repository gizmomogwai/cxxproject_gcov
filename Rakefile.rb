#!/usr/bin/env rake
require "bundler/gem_tasks"

task :package => :spec
task :package => :build

task :clean do
  sh 'rm -rf pkg'
end

task :default => :package

require 'rspec/core/rake_task'

desc "Run unittests"
RSpec::Core::RakeTask.new() do |t|
  t.pattern = 'spec/**/*_spec.rb'
#  if ENV['BUILD_SERVER']
#    t.rspec_opts = '-r ./junit.rb -f JUnit -o build/test_details.xml'
#  end
end

def gems
  ['cxxproject', 'cxx', 'cxxproject_gcov']
end

desc 'prepare acceptance tests'
task :prepare_accept do
  gems.each do |gem|
    cd "../#{gem}" do
      sh 'rm -rf pkg'
      sh 'rake package'
    end
  end
  gems.each do |gem|
    sh "gem install ../#{gem}/pkg/*.gem"
  end
end

desc 'run acceptance tests'
RSpec::Core::RakeTask.new(:accept) do |t|
  t.pattern = 'accept/**/*_spec.rb'
#  if ENV['BUILD_SERVER']
#    t.rspec_opts = '-r ./junit.rb -f JUnit -o build/test_details.xml'
#  end
end
