#agent.pp
#Requires: https://github.com/example42/puppet-wget

class vfense::agent (
	$source = 'https://github.com/vFense/vFenseAgent-nix/releases/download/v0.7.2/VFAgent_0_7_2-deb.tar.gz',
        $user,
        $password,
        $servername,
        $tag = 'default',
        $ensure = 'installed',
 ) {
  
  case $ensure {
    'installed': {
   
      validate_string($user)
      validate_string($password)
      validate_string($servername)
   
      wget::fetch { "vfense-agent":
        source => $source,
        destination => '/usr/local/src/vfense.tar.gz',
        notify => Exec['unpack vfense-agent'],
      } 

      file { '/usr/local/src/vfense-agent':
        ensure => directory,
      }
 
      exec { 'unpack vfense-agent':
        cwd => '/usr/local/src',
        command => '/bin/tar -xvzf /usr/local/src/vfense.tar.gz -C /usr/local/src/vfense-agent --strip-components=1',
        creates => '/usr/local/src/vfense-agent/agent',
        require => File['/usr/local/src/vfense-agent'],
        notify => Exec['vfense-agent install'],
      }
 
      exec { 'vfense-agent install':
        cwd => '/usr/local/src/vfense-agent',
        command => "./install -u '$user' -p '$password' -s '$servername' -c '$tag'",
        creates => '/opt/TopPatch',
        path    => ["/usr/bin", "/usr/sbin", "/usr/local/bin"],
      }

      service { 'tpagentd':
        ensure => running,
        enable => true,
        status => '/usr/bin/test -e /tmp/toppatch_agent.pid',
        require => Exec["vfense-agent install"],
      }
    }
    'absent': {
      file { '/usr/local/src/vfense-agent':
        ensure => 'absent',
        force => true,
        require => Service['tpagentd'],
      }
      file { '/opt/TopPatch':
        recurse => true,
        force => true,
        ensure  => 'absent',
        require => Service['tpagentd'],
      }
      service { 'tpagentd':
        ensure => stopped,
        enable => false,
        status => '/usr/bin/test -e /tmp/toppatch_agent.pid',
      }

    }
  }
}
