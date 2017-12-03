require 'puppet/indirector/facts/yaml'
require 'puppet/network/http/api/indirected_routes'

# NOTE: If JRuby 9k was in use, we could use Module#prepend from Ruby 2.x
# which is a much nicer method of monkeypatching.

class Puppet::Network::HTTP::API::IndirectedRoutes
  alias_method :_unpatched_plurality, :plurality

  def plurality(indirection)
    # This is required because at some point someone thought that making the
    # puppet HTTP handlers sensitive to inflection, but then centralizing all
    # the handling for that sensitivity into a static method was a good idea.
    #
    # I hope that someone catches a nasty case of the hiccoughs.
    return :singular if indirection == "facts"
    # Delegate to original method
    _unpatched_plurality(indirection)
  end
end

class Puppet::Node::Facts::Yaml
  def allow_remote_requests?
    true
  end
end
