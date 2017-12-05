Puppet Facts Upload
===================

[![Build Status](https://travis-ci.org/Sharpie/puppet-facts_upload.svg?branch=master)](https://travis-ci.org/Sharpie/puppet-facts_upload)

This project re-implements the `puppet facts upload` command and part of the
associated `/puppet/v3/facts` endpoint that [was removed][PUP-2560] along with
the inventory service in Puppet 4.0. These pieces of functionality were useful
for keeping facts updated outside of catalog compilation.

[PUP-2560]: https://tickets.puppetlabs.com/browse/PUP-2560

Re-adding the command and endpoint enables two key use cases:

  - The ability to run agents off of cached catalogs. Facts become stale in this
    configuration as they are only updated when a fresh catalog is compiled.

  - The ability to submit updated facts at the end of an agent run. This allows
    facts to reflect any changes made during catalog application and keeps fact
    data as fresh as possible for PuppetDB queries.


## Requirements

This module has been tested against the following versions of Puppet Server and
Puppet Enterprise running on the following platforms:

  - **Versions:** Puppet Server 5.1.z, PE 2017.3.z
  - **Platforms:** RedHat 6, 7; Ubuntu 14.04, 16.04; SLES 11, 12

The `facts_upload` module is fairly sensitive to the Puppet Server and PE
version numbers as the code hooks into several internal APIs in both Puppet
Server and the `puppet_enterprise` module. The module likely will not work if
your Puppet Server version or platform doesn't fall within the list above.

Puppet Agent support should be much less restrictive. Generally if the agent
can request a catalog from a Puppet Server, it should be able to upload facts
once the `facts_upload` module has been applied to Puppet Server.


## Usage

The `facts_upload` module currently provides one class: `facts_upload::server`.
This class should be applied to all nodes running the `puppetserver` or
`pe-puppetserver` services and will configure the Puppet Server to mount a
`/puppet/v3/facts` endpoint and configures `auth.conf` to allow agents to
upload facts for just their own certnames.

The module also provides some Ruby code which is pluginsynced to agents:

  - `lib/puppet/indirector/facts/rest.rb`
  - `lib/puppet/face/facts/upload.rb`

Agents may run `puppet facts upload` once pluginsync has completed.


## Limitations

This module only provides a subset of the functionality that was removed in
[PUP-2560][PUP-2560]:

  - A `/puppet/v3/facts` API endpoint for Puppet Server that responds to PUT
    requests only.

  - A `Puppet::Node::Facts::Rest` indirector terminus that sends requests from
    agents to the `/puppet/v3/facts` API endpoint of the `server` the agent is
    configure to talk with.

  - A `puppet facts upload` face that fetches facts from Facter and then
    uploads them to the `/puppet/v3/facts` API endpoint of the `server` the
    agent is configured to talk with.

Notably, the following deprecated features have not been restored:

  - Functionality and REST API routes related to the Inventory Service.

  - Functionality and indirector terminii related to  the `store_configs`
    subsystem.


## Development

See the output of `rake -T` for development workflow tasks. More info will be
added to this section in a future release.
