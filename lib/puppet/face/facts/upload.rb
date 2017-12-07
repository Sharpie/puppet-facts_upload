require 'puppet/face/facts'
require 'puppet/indirector/facts/rest'

Puppet::Face.define(:facts, '0.0.1') do
  action(:upload) do
    summary "Upload local facts to the puppet master."
    description <<-'EOT'
      Reads facts from the local system using the `facter` terminus, then
      saves the returned facts using the rest terminus.
    EOT
    returns "Nothing."
    notes <<-'EOT'
      This action requires that the puppet master's `auth.conf` file
      allow save access to the `facts` REST terminus. Puppet agent does
      not use this facility, and it is turned off by default. See
      <http://docs.puppetlabs.com/guides/rest_auth_conf.html> for more details.
    EOT
    examples <<-'EOT'
      Upload facts:

      $ puppet facts upload
    EOT

    render_as :json

    when_invoked do |options|
      Puppet::Node::Facts.indirection.terminus_class = :facter
      facts = Puppet::Node::Facts.indirection.find(Puppet[:certname])

      Puppet::Node::Facts.indirection.terminus_class = :rest
      server = Puppet::Node::Facts::Rest.server
      Puppet.notice "Uploading facts for '#{Puppet[:certname]}' to: '#{server}'"

      Puppet::Node::Facts.indirection.save(facts)
    end
  end
end
