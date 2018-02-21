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
      <https://puppet.com/docs/puppetserver/latest/config_file_auth.html>
      for more details.
    EOT
    examples <<-'EOT'
      Upload facts:

      $ puppet facts upload
    EOT

    render_as :json

    when_invoked do |options|
      # Use `agent` sections  settings for certificates, Puppet Server URL,
      # etc. instead of `user` section settings.
      Puppet.settings.preferred_run_mode = :agent
      Puppet::Node::Facts.indirection.terminus_class = :facter

      facts = Puppet::Node::Facts.indirection.find(Puppet[:node_name_value])
      unless Puppet[:node_name_fact].empty?
        Puppet[:node_name_value] = facts.values[Puppet[:node_name_fact]]
        facts.name = Puppet[:node_name_value]
      end

      Puppet::Node::Facts.indirection.terminus_class = :rest
      server = Puppet::Node::Facts::Rest.server
      Puppet.notice "Uploading facts for '#{Puppet[:certname]}' to: '#{server}'"

      Puppet::Node::Facts.indirection.save(facts)
    end
  end
end
