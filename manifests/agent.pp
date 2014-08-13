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
        destination => '/tmp/vfense.tar.gz',
        notify => Exec['unpack vfense-agent'],
      } 

      file { '/tmp/vfense-agent':
        ensure => directory,
      }
 
      exec { 'unpack vfense-agent':
        cwd => '/tmp',
        command => '/bin/tar -xvzf /tmp/vfense.tar.gz -C /tmp/vfense-agent --strip-components=1',
        creates => '/tmp/vfense-agent/agent',
        require => File['/tmp/vfense-agent'],
        notify => Exec['vfense-agent install'],
      }
 
      exec { 'vfense-agent install':
        cwd => '/tmp/vfense-agent',
        command => "./install -u '$user' -p '$password' -s '$servername' -c '$tag'",
        creates => '/opt/TopPatch',
      }
      service { 'tpagentd':
        ensure => running,
        enable => true,
        status => '/usr/bin/test -e /tmp/toppatch_agent.pid',
        require => Exec["vfense-agent install"],
      }
    }
    'absent': {
      file { '/tmp/vfense-agent':
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
