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
      install_package(master, 'cronie') if master['hypervisor'] == 'docker'
    end
  end

  step 'Install Puppet Enterprise' do
    install_pe_on(hosts, answers: {
      'puppet_enterprise::puppet_master_host': '%{::trusted.certname}'})
  end
end
