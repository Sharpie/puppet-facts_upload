require 'json'
require 'securerandom'

# Using a random string allows this test to be re-run against staged Beaker VMs
# without past successes showing up as false positives.
RANDOM_VALUE = SecureRandom.base64.freeze

step 'Test Puppet Facts upload' do
  on(hosts, 'mkdir -p /etc/facter/facts.d')
  create_remote_file(hosts,
                     '/etc/facter/facts.d/test_fact.txt',
                     "facts_upload_test_value=#{RANDOM_VALUE}")

  on(hosts, puppet('facts', 'upload'))
  sleep(1) # Give PDB some time to process the upload
end

step 'Check PuppetDB for uploaded facts' do
  hosts.each do |host|
    host_fqdn = on(master, '/opt/puppetlabs/bin/facter fqdn').stdout.chomp
    query = "curl http://localhost:8080/pdb/query/v4/nodes/#{host_fqdn}/facts/facts_upload_test_value"

    stored_facts = JSON.parse(on(master, query).stdout.chomp)
    assert_equal(RANDOM_VALUE, stored_facts.first['value'])
  end
end
