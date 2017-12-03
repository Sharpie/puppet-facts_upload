source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'rake', '~> 12.0'

group :acceptance do
  gem 'beaker',                                                     '~> 3.29'
  gem 'beaker-docker',                                              '~> 0.2'
  gem 'beaker-puppet',                                              '~> 0.8'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"
