test_name 'Install FOSS Components' do
  extend Beaker::HostPrebuiltSteps
  confine :to, :type => 'foss'

  # TODO: Currently installs the latest Puppet 5 components. This pre-suite
  # should be parameterized to match versions with various builds of PE.

  step 'Install Puppet Agent' do
    install_puppet_agent_on(hosts, puppet_collection: 'puppet5')
  end

  step 'Install Puppet Server' do
    install_package(master, 'puppetserver')
    on(master, puppet('resource', 'service', 'puppetserver', 'ensure=running'))
    create_remote_file(master, '/etc/puppetlabs/puppet/autosign.conf', "*\n")
    on(master, 'chown puppet /etc/puppetlabs/puppet/autosign.conf')
  end

  step 'Install PuppetDB' do
    on(master, puppet('module', 'install', 'puppetlabs/puppetdb'))
    apply_manifest_on(master, <<-EOM)
      class {'puppetdb':
        manage_firewall => false,
      }

      class {'puppetdb::master::config':
        puppet_service_name => 'puppetserver',
        manage_routes => true,
        manage_storeconfigs => true,
        manage_report_processor => true,
        enable_reports => true,
      }

      if fact('os.family') =~ /(?i:redhat)/ {
        # Postgres drags in iptables on RedHat. So, pre-empt it by ensuring
        # firewall is shut down.
        class {'firewall': ensure => stopped}
      }
      EOM
  end
end
