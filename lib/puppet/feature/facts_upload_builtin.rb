require 'puppet/version'
require 'puppet/util/feature'
require 'puppet/util/package'

# The `puppet facts upload` action was re-added in Puppet 5.5.0. This feature
# is used as a guard in puppet/face/facts/upload.rb to prevent overwriting
# the native action.
Puppet.features.add(:facts_upload_builtin) do
  (Puppet::Util::Package.versioncmp(Puppet::PUPPETVERSION, '5.5.0') >= 0)
end
