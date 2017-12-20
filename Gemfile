source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gem 'rake',    '~> 12.0'

group :acceptance do
  # Pinned for fixes that allow multiple Docker VMs to be persisted (BKR-1263).
  # TODO: Unpin once the next beaker release ships.
  gem 'beaker',
    git: 'https://github.com/puppetlabs/beaker',
    ref: '58bf28a'
  gem 'beaker-docker',                                              '~> 0.2'
  gem 'beaker-puppet',                                              '~> 0.8'
  gem 'beaker-pe',                                                  '~> 1.26'
  gem 'beaker-hostgenerator',                                       '~> 1.1'

  # Used for the Puppet Module Tool
  gem 'puppet',                                                     '~> 5.3'
end

eval_gemfile "#{__FILE__}.local" if File.exists? "#{__FILE__}.local"
