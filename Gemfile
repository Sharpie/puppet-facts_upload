source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'rake',    '~> 12.0'

group :acceptance do
  gem 'beaker',                                                     '~> 3.30'
  gem 'beaker-docker',                                              '~> 0.2'
  gem 'beaker-puppet',                                              '~> 0.8'
  gem 'beaker-pe',                                                  '~> 1.26'
  gem 'beaker-hostgenerator',                                       '~> 1.1'

  # Used for the Puppet Module Tool
  gem 'puppet',                                                     '~> 5.3'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"
