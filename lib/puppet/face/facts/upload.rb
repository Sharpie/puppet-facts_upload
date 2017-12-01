require 'puppet/face/facts'

FACTS_FACE_VERSION = (Puppet::Face.find_action(:facts, :find).face.version.to_s).freeze

Puppet::Face.define(:facts, FACTS_FACE_VERSION) do
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
      Puppet::Node::Facts.indirection.save(facts)
      Puppet.notice "Uploaded facts for '#{Puppet[:certname]}'"
      nil
    end
  end
end
