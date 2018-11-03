require 'json'
require 'rubygems/requirement'

step 'Copy module to master VM' do
  metadata = JSON.parse(File.read('metadata.json'))
  module_tarball = "#{metadata['name']}-#{metadata['version']}.tar.gz"

  # We use this instead of `copy_module_to` from beaker-puppet as the
  # Rakefile contains logic for building a tarball that contains an
  # assembled JAR.
  master.do_scp_to("pkg/#{module_tarball}", "/tmp/#{module_tarball}", {})
  # The uninstall is here to ensure we load in a fresh copy of the
  # module if the tests are being re-run.
  on(master, puppet('module', 'uninstall', 'sharpie-facts_upload'),
    accept_all_exit_codes: true)
  on(master, puppet('module', 'install', "/tmp/#{module_tarball}"))

  # Trigger type generation and reload puppetserver to flush cached types.
  on(master, puppet('generate', 'types'))
  master_service = master[:type].start_with?('foss') ? 'puppetserver' : 'pe-puppetserver'
  bounce_service(master, master_service)
end

step 'Install module on master VM' do
  # The module currently supports Puppet Server 5.1 and 5.2 as native
  # support for uploading facts was added in 5.3.
  expect_service_mounted = if Gem::Requirement.new('< 5.3').satisfied_by?(Gem::Version.new(ENV['PUPPETSERVER_VERSION']))
                             true
                           else
                             false
                           end

  manifest = <<-EOM
if fact('pe_server_version') =~ String {
  # Pulls in other PE config bits that facts_upload::server hooks into.
  include puppet_enterprise::profile::certificate_authority
} else {
  service{'puppetserver': ensure => running}
}

class{'facts_upload::server': }
EOM
  apply_manifest_on(master, manifest)

  status_check = "curl -k https://127.0.0.1:8140/status/v1/services"
  response = JSON.parse(on(master, status_check).stdout.chomp)

  if expect_service_mounted
    refute_nil(response['facts-upload-service'])
  else
    assert_nil(response['facts-upload-service'])
  end
end
