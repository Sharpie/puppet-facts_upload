require 'json'

step 'Test Puppet Facts upload' do
  on(hosts, 'mkdir -p /etc/facter/facts.d')
  create_remote_file(hosts, '/etc/facter/facts.d/test_fact.txt', 'test_fact=foo')

  on(hosts, puppet('facts', 'upload'))
end

step 'Check PuppetDB for uploaded facts' do
  hosts.each do |host|
    host_fqdn = on(master, '/opt/puppetlabs/bin/facter fqdn').stdout.chomp
    query = "curl http://localhost:8080/pdb/query/v4/nodes/#{host_fqdn}/facts/test_fact"

    stored_facts = JSON.parse(on(master, query).stdout.chomp)
    assert_equal('foo', stored_facts.first['value'])
  end
end
