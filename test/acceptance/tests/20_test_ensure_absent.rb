require 'json'

step 'Test ensure => absent' do
  manifest = <<-EOM
if fact('pe_server_version') =~ String {
  # Pulls in other PE config bits that facts_upload::server hooks into.
  include puppet_enterprise::profile::certificate_authority
} else {
  service{'puppetserver': ensure => running}
}

class{'facts_upload::server': ensure => absent}
EOM
  apply_manifest_on(master, manifest)

  status_check = "curl -k https://127.0.0.1:8140/status/v1/services"
  response = JSON.parse(on(master, status_check).stdout.chomp)
  assert_nil(response['facts-upload-service'])
end
