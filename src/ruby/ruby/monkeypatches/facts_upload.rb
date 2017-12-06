# Required to prevent the IndirectedRoutes class from being patched
# twice. Patching twice causes alias_method to set up a loop that
# leads to "stack level too deep" errors for non-Facts requests.
#
# A better way to do this would be to update the JRuby load path to
# include this directory and use a plain `require
# 'monkeypatches/facts_upload'` as require has logic to prevent a file
# from being evaluated twice.
if not defined?($_sharpie_facts_upload_patch)
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

  $_sharpie_facts_upload_patch = true
end
