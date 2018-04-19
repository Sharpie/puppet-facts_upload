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
end

step 'Install module on master VM' do
  # The module currently supports Puppet Server 5.1 and 5.2 as native
  # support for uploading facts was added in 5.3.
  change_expectation = if master[:type].start_with?('foss') || master[:pe_ver].start_with?('2017.3')
                         # Should not expect changes on FOSS 5.3, but there is
                         # no built-in fact for reporting FOSS server versions,
                         # so the manifest code can't respond to it.
                         {expect_changes: true}
                       else
                         {catch_changes: true}
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

  apply_manifest_on(master, manifest, **change_expectation) do
    # In addition to no changes, we expect a warning message.
    if change_expectation.has_key?(:catch_changes)
      assert_match(stderr, 'facts_upload::server class only supports PE 2017.3')
    end
  end
end
