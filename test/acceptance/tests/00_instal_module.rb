require 'json'

step 'Copy module to master VM' do
  metadata = JSON.parse(File.read('metadata.json'))
  module_tarball = "#{metadata['name']}-#{metadata['version']}.tar.gz"

  # We use this instead of `copy_module_to` from beaker-puppet as the
  # Rakefile contains logic for building a tarball that contains an
  # assembled JAR.
  master.do_scp_to("pkg/#{module_tarball}", "/tmp/#{module_tarball}", {})
  on(master, puppet('module', 'install', "/tmp/#{module_tarball}"))
end
