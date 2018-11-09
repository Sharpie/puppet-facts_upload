# Docker will add the short hostname assigned to a container to /etc/hosts
# which prevents it from having a FQDN despite the best efforts of
# the hack_etc_hosts helper. Puppet farily well looses its mind if a FQDN isn't
# used as certificates start mis-matching accross the board.
#
# This pre-suite scrubs the /etc/hosts file.
test_name 'Ensure Docker networking is sane' do
  extend Beaker::HostPrebuiltSteps
  confine :to, :hypervisor => 'docker'

  step 'Sanitize /etc/hosts' do
    # A variant of hack_etc_hosts that avoids setting empty domain names.
    etc_hosts = "127.0.0.1\tlocalhost localhost.localdomain\n"

    hosts.each do |host|
      ip = host['vm_ip'] || host['ip'].to_s
      hostname = host[:vmhostname] || host.name
      domain = get_domain_name(host)

      if domain.nil? || domain.empty?
        etc_hosts += "#{ip}\t#{hostname}\n"
      else
        etc_hosts += "#{ip}\t#{hostname}.#{domain} #{hostname}\n"
      end
    end

    hosts.each do |host|
      # Truncate the hosts file.
      on(host, ': > /etc/hosts')
      set_etc_hosts(host, etc_hosts)
    end
  end
end

test_name 'Add alias for puppet hostname' do
  extend Beaker::HostPrebuiltSteps
  step 'Add puppet to /etc/hosts' do
    hosts.each do |host|
      set_etc_hosts(host, "#{master['vm_ip']}\tpuppet\n")
    end
  end
end
