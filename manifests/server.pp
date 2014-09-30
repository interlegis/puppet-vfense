#server.pp
#Require: puppetlabs-apt

class vfense::server (
        $dnsname = $fqdn,
	$initialpw = '!vFense01',	
) {
  include apt

  apt::source { 'rethintkdb':
    location   => 'http://download.rethinkdb.com/apt',
    repos      => 'main',
    key        => 'A7E00EF33A8F2399',
    key_server => 'keyserver.ubuntu.com',
  }

  if !defined(Package['rethinkdb']) {
    package { 'rethinkdb': 
      ensure  => present, 
      require => Apt::Source['rethintkdb'],
      notify  => Exec['rethinkdb_pip'],
    }
  }

  ensure_packages ( ['python-setuptools', 
                     'python-pip',
                     'python-lxml',
                     'python-pycurl', 
                     'python-redis',
                     'python-openssl', 
                     'python-tornado',
                     'python-beautifulsoup',
                     'python-roman',
                     'python-bcrypt',
                     'python-ipaddr',
                     'python-tz',
                     'python-urlgrabber',
                     'python-netifaces',
                     'redis-server',
                     'nginx-extras',
                     'python-jsonpickle',
                     'openssh-server',
                     'python-simplejson',
                     'patch',
                     'git',
                     'build-essential',
                     'python-dev'])

  ensure_packages( ['rq',
                    'requests',
                    'tornado-redis',
                    'xlrd',
                    'roman',
                    'six',
                    'tornado',
                    'python-dateutil'], { provider => 'pip' })
  ensure_packages ( 'apscheduler', { provider=> 'pip', ensure => '2.1.2' } )
  
  exec { 'rethinkdb_pip':
    command     => 'pip install --upgrade rethinkdb',
    path        => ["/usr/bin", "/usr/sbin"],
    refreshonly => true,
  }

  vcsrepo { '/opt/TopPatch':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/toppatch/vFense',
    revision => 'current',
  }

  file { '/usr/local/lib/python2.7/dist-packages/vFense':
    ensure  => link,
    target  => '/opt/TopPatch/tp/src',
    require => Vcsrepo['/opt/TopPatch'],
    notify  => Exec['initialize vfense'],
  }

  exec { "initialize vfense":
    command     => "python tp/src/scripts/initialize_vFense.py --dnsname=$dnsname --password=${initialpw}",
    path        => ["/usr/bin", "/usr/sbin", "/usr/local/bin"],
    cwd         => '/opt/TopPatch/',
    refreshonly => true,
    require     => [ Vcsrepo['/opt/TopPatch'],
                     Exec['rethinkdb_pip']],
  }

  service { ["nginx", "redis-server", "rethinkdb"] :
    enable  => true,
    ensure  => running,
    require => Exec['initialize vfense'],
  }

  service { "vFense":
    enable => true,
    ensure => running,
    require => [ Service[["nginx", "redis-server", "rethinkdb"]],
                 Exec['initialize vfense'] ],
  }

}
