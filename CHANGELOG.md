# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]


## [1.0.2] - 2018-02-21
### Added

  - Print name of server receiving upload to messages logged by
    `puppet facts upload`.

### Fixed

  - Use SSL and server settings from the `agent` section of `puppet.conf
    when running `puppet facts upload`.

  - Use Puppet's `node_name_value` and `node_name_fact` settings to match
    behavior with `puppet agent` and `puppet apply`.


## [1.0.1] - 2017-12-06
### Fixed

  - Ruby patch code is only applied once per JRuby which prevents a
    "stack level too deep" error caused by applying the patch multiple
    times.


## [1.0.0] - 2017-12-05
### Added

  - A `/puppet/v3/facts` API endpoint for Puppet Server that responds to PUT
    requests only.

  - A `Puppet::Node::Facts::Rest` indirector terminus that sends requests from
    agents to the `/puppet/v3/facts` API endpoint of the `server` the agent is
    configure to talk with.

  - A `facts_upload::server` class that configures Puppet Server 5.1.z or
    PE 2017.3.z to mount the above.

  - A `puppet facts upload` face that fetches facts from Facter and then
    uploads them to the `/puppet/v3/facts` API endpoint of the `server` the
    agent is configured to talk with.

  - Tests. Tests. Tests.


[Unreleased]: https://github.com/Sharpie/puppet-facts_upload/compare/1.0.2...HEAD
[1.0.2]: https://github.com/Sharpie/puppet-facts_upload/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/Sharpie/puppet-facts_upload/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/Sharpie/puppet-facts_upload/compare/5620a62...1.0.0
