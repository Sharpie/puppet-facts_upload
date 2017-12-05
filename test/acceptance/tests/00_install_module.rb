require 'json'

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

  apply_manifest_on(master, <<-EOM)
if fact('pe_server_version') =~ String {
  include puppet_enterprise::profile::master
} else {
  service{'puppetserver': ensure => running}
}

class{'facts_upload::server': }
EOM
end
