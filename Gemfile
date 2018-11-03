source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'rake',    '~> 12.0'

group :acceptance do
  gem 'beaker',                                                     '~> 4.1'
  gem 'beaker-docker',                                              '~> 0.4'
  gem 'beaker-vmpooler',                                            '~> 1.3'
  gem 'beaker-puppet',                                              '~> 1.7'
  gem 'beaker-pe',                                                  '~> 2.0'
  gem 'beaker-hostgenerator',                                       '~> 1.1'

  # Used for the Puppet Module Tool
  gem 'puppet',                                                     '~> 5.3'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"
