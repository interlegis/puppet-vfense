#server.pp
#Require: puppetlabs-apt

class vfense::server (
        $dnsname = $fqdn,
	$initialpw = 'vfense',	
) {
  include apt

  apt::ppa { 'ppa:wev/vfense': 
    require => Apt::Key['vfense'],
  }
  apt::ppa { 'ppa:rethinkdb/ppa': 
    require => Apt::Key['rethinkdb'],
  }

  apt::key { 'rethinkdb':
    key => '11D62AD6',
    key_server => 'keyserver.ubuntu.com',
  }

  apt::key { 'vfense':
    key => '5D019DC9',
    key_server => 'keyserver.ubuntu.com',
  }

  if !defined(Package['rethinkdb']) {
    package { 'rethinkdb': 
      ensure => present, 
      require => Apt::Ppa['ppa:rethinkdb/ppa'],
    }
  }

  if !defined(Package['python-dateutil']) {
    package { 'python-dateutil': ensure => present; }
  }

  if !defined(Package['vfense-server']) {
    package { 'vfense-server': 
      ensure => present,
      notify => Exec["initialize vfense"],
      require => Apt::Ppa['ppa:wev/vfense'],
    }
  }

  exec { "initialize vfense":
    command => "python tp/src/scripts/initialize_vFense.py --dnsname=$dnsname --password=${initialpw}",
    cwd => "/opt/TopPatch/",
    refreshonly => true,
  }

  service { ["nginx", "redis-server", "rethinkdb"] :
    enable => true,
    ensure => running,
  }

  service { "vFense":
    enable => true,
    ensure => running,
    require => Service["nginx"],
  }

}
