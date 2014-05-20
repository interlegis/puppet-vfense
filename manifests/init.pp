#init.pp
#Require: puppetlabs-apt

class vfense (
	
) {
  class { 'vfense::agent':
    
  }    
}
