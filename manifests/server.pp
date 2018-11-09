# Slots the facts_upload extension JAR into a Puppet Server install. Use this
# class by adding it to the "PE Masters" group or otherwise applying it to a
# node running PE or Open Source Puppet Server.
class facts_upload::server (
  Enum['present', 'absent'] $ensure = 'present',
) {
  if fact('pe_server_version') =~ String {
    # PE configuration
    if (versioncmp(fact('pe_server_version'), '2016.4.10') < 0) {
      fail('The facts_upload::server class does not support PE versions older than 2016.4.10')
    } elsif (versioncmp(fact('pe_server_version'), '2016.5.0') >= 0) and
            (versioncmp(fact('pe_server_version'), '2017.3.0') < 0) {
      # TODO: The plugin actually works fine, just need to add the right Java
      #       classpath twiddling to support these.
      fail('The facts_upload::server class does not support PE versions 2016.5 -- 2017.2')
    } elsif (versioncmp(fact('pe_server_version'), '2018.1.0') >= 0) {
      warning("The facts_upload::server class does not support PE version 2018.1 or newer and should be removed from: ${trusted['certname']}")
      $_ensure = absent
    } else {
      $_ensure = $ensure
    }

    if (versioncmp(fact('pe_server_version'), '2017.1.0') < 0) {
      $_puppetserver_service = Service['pe-puppetserver']
    } else {
      $_puppetserver_service = Exec['pe-puppetserver service full restart']
    }

    if (versioncmp(fact('pe_server_version'), '2017.3.0') < 0) {
      # PE Versions older than 2017.3 need some extra resources to ensure
      # a directory for the JAR file is present and the CLASSPATH is
      # configured to find it.
      file {'/opt/puppetlabs/server/data/puppetserver/jars':
        ensure => directory,
        owner  => 'pe-puppet',
        group  => 'pe-puppet',
        mode   => '0700',
      }

      # FIXME: Due to EZBake packaging changes this actually isn't sufficient
      #        for 2016.5, 2017.1, 2017.2, and some older versions of 2016.4.
      #        Support for the cli-defaults file was backported to 2016.4.10.
      file {'/opt/puppetlabs/server/apps/puppetserver/cli/cli-defaults.sh':
        ensure  => $_ensure,
        owner   => 'pe-puppet',
        group   => 'pe-puppet',
        mode    => '0755',
        content => 'CLASSPATH="${CLASSPATH}:/opt/puppetlabs/server/data/puppetserver/jars/*"',
        require => File['/opt/puppetlabs/server/data/puppetserver/jars'],
      }
    }

    if $_ensure == 'present' {
      puppet_enterprise::trapperkeeper::bootstrap_cfg { 'facts-upload-service':
        namespace => 'puppetlabs.services.facts-upload.facts-upload-service',
        container => 'puppetserver',
        require   => Package['pe-puppetserver']
      }
    }
  } else {
    # FOSS configuration
    $_puppetserver_service = Service['puppetserver']
    # FIXME: Fail if Puppet Server 2.6 -- 5.2 isn't in use.
    $_ensure = $ensure

    file {'/etc/puppetlabs/puppetserver/services.d/facts_upload.cfg':
      ensure  => $_ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "puppetlabs.services.facts-upload.facts-upload-service/facts-upload-service\n",
      notify  => $_puppetserver_service,
    }
  }

  file {'/opt/puppetlabs/server/data/puppetserver/jars/facts-upload.jar':
    ensure => $_ensure,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/facts_upload/facts-upload.jar',
    backup => false,
    notify => $_puppetserver_service,
  }

  puppet_authorization::rule {'node fact upload':
    ensure               => $_ensure,
    match_request_path   => '^/puppet/v3/facts/([^/]+)$',
    match_request_type   => 'regex',
    match_request_method => 'put',
    allow                => '$1',
    sort_order           => 601,
    path                 => '/etc/puppetlabs/puppetserver/conf.d/auth.conf',
    notify               => $_puppetserver_service,
  }
}
