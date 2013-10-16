#
# Sets up the package repos necessary to use OpenStack
# on RHEL-alikes and Ubuntu
#
class openstack::repo(
  $release = 'grizzly'
) {
  case $release {
    'havana', 'grizzly': {
      if $::osfamily == 'RedHat' {
        include openstack::repo::rdo
      } elsif $::operatingsystem == 'Ubuntu' {
        class {'openstack::repo::uca': release => $release }
      }
    }
    'folsom': {
      if $::osfamily == 'RedHat' {
        include openstack::repo::epel
      } elsif $::operatingsystem == 'Ubuntu' {
        class {'openstack::repo::uca': release => $release }
      }
    }
    default: {
      notify { "WARNING: openstack::repo parameter 'release' of '${release}' not recognized; please use one of 'havana', 'grizzly' or 'folsom'.": }
    }
  }
}
