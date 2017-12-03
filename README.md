Puppet Facts Upload
===================

[![Build Status](https://travis-ci.org/Sharpie/puppet-facts_upload.svg?branch=master)](https://travis-ci.org/Sharpie/puppet-facts_upload)

**NOTE:** This module is currently a rough draft and should not be used.

This project re-implements the `puppet facts upload` command and part of the
associated `pupept/v3/facts` endpoint that [was removed][PUP-2560]. along with
the inventory service in Puppet 4.0. These pieces of functionality were useful
for keeping facts updated outside of catalog compilation.

[PUP-2560]: https://tickets.puppetlabs.com/browse/PUP-2560

Re-adding the command and endpoint enables two key use cases:

  - The ability to run agents off of cached catalogs. Facts become stale in this
    configuration as they are only updated when a fresh catalog is compiled.

  - The ability to submit updated facts at the end of an agent run. This allows
    facts to reflect any changes made during catalog application and keeps fact
    data as fresh as possible for PuppetDB queries.
