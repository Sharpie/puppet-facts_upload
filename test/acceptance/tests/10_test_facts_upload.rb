require 'json'
require 'securerandom'

# Using a random string allows this test to be re-run against staged Beaker VMs
# without past successes showing up as false positives.
RANDOM_VALUE = SecureRandom.base64.freeze
master_fqdn = on(master, '/opt/puppetlabs/bin/facter fqdn').stdout.chomp

step 'Configure puppet.conf for tests' do
  # Set up puppet.conf such that the agent section contains the only valid
  # hostname for the master.
  on(hosts, puppet('config', 'set', '--section', 'main', 'server', 'test.invalid'))
  on(hosts, puppet('config', 'set', '--section', 'agent', 'server', master_fqdn))
end

step 'Run puppet agent to download plugins' do
  on((agents - [master]), puppet('agent', '-t', '--server', master_fqdn))
end

step 'Test Puppet Facts upload' do
  on(hosts, 'mkdir -p /etc/facter/facts.d')
  create_remote_file(hosts,
                     '/etc/facter/facts.d/test_fact.txt',
                     "facts_upload_test_value=#{RANDOM_VALUE}")

  on(hosts, puppet('facts', 'upload', '--server', master_fqdn)) do
    # Ensure we never override a built-in version of `puppet facts upload`
    assert_no_match(/Warning: Redefining action upload/, stderr)
  end
  sleep(2) # Give PDB some time to process the upload
end

step 'Check PuppetDB for uploaded facts' do
  hosts.each do |host|
    host_fqdn = on(host, '/opt/puppetlabs/bin/facter fqdn').stdout.chomp
    query = "curl http://localhost:8080/pdb/query/v4/nodes/#{host_fqdn}/facts/facts_upload_test_value"

    stored_facts = JSON.parse(on(master, query).stdout.chomp)
    assert_equal(RANDOM_VALUE, stored_facts.first['value'])
  end
end
