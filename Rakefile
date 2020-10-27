# frozen_string_literal: true

require 'rake/testtask'

CODE = 'lib/poke_lib'

task :default do
  puts `rake -T`
end

desc 'run tests'
task :spec do
  sh 'ruby spec/pokemon_api_spec.rb'
end

namespace :vcr do
  desc 'delete cassette fixtures'
  task :wipe do
    sh 'rm spec/fixtures/cassettes/*.yml' do |ok, _|
      puts(ok ? 'Cassettes deleted' : 'No cassettes found')
    end
  end
end

namespace :quality do
  desc 'run all quality checks'
  task all: %i[reek flog rubocop]

  task :rubocop do
    sh 'rubocop'
  end

  task :reek do
    sh 'reek'
  end

  task :flog do
    sh "flog #{CODE}"
  end
end