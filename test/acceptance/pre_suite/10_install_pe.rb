require 'beaker-pe'

test_name 'Install PE' do
  confine :to, :type => 'pe'

  step 'Install PE prereqs' do
    if master[:hypervisor] == 'docker'
      # TODO: Prereq for CentOS 7. Map out additonal PE master platforms:
      #  - CentOS 6
      #  - Ubuntu 16.04
      #  - Ubuntu 14.04
      #  - Sles 12
      #  - SLES 11
      hosts.each do |h|
        install_package(h, 'cronie')
      end
    end
  end

  step 'Install Puppet Enterprise' do
    install_pe_on(hosts, answers: {
      'puppet_enterprise::puppet_master_host': '%{::trusted.certname}',
      'pe_install::puppet_master_dnsaltnames': ['%{::trusted.certname}',
                                                "#{master.hostname}",
                                                'puppet']})
    create_remote_file(master, '/etc/puppetlabs/puppet/autosign.conf', "*\n")
    on(master, 'chown pe-puppet /etc/puppetlabs/puppet/autosign.conf')
  end
end
