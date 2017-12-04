# Slots a build of the clojure file server into a PE install. Use this class
# by adding it to the "PE Masters" group.
class facts_upload (
  Enum['present', 'absent'] $ensure = 'present',
) {

  # FIXME: Bail if Puppet Server 5.x isn't in use.
  # TODO: Support Puppet Server 2.6 -- 2.8

  file {'/etc/puppetlabs/puppetserver/services.d/facts_upload.cfg':
    ensure => $ensure ? {
      'present' => file,
      'absent'  => absent,
    },
    owner   => 'puppet',
    group   => 'puppet',
    mode    => '0644',
    content => "puppetlabs.services.facts-upload.facts-upload-service/facts-upload-service\n",
    notify  => Service['puppetserver'],
  }

  file {'/opt/puppetlabs/server/data/puppetserver/jars/facts-upload.jar':
    ensure => $ensure ? {
      'present' => file,
      'absent'  => absent,
    },
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/facts_upload/facts-upload.jar',
    backup => false,
    notify => Service['puppetserver'],
  }

  puppet_authorization::rule {'node fact upload':
    ensure               => $ensure,
    match_request_path   => '^/puppet/v3/facts/([^/]+)$',
    match_request_type   => 'regex',
    match_request_method => 'put',
    allow                => '$1',
    sort_order           => 601,
    path                 => '/etc/puppetlabs/puppetserver/conf.d/auth.conf',
    notify               => Service['puppetserver'],
  }
}
