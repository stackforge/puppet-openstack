#
# Sets up the package repos necessary to use OpenStack
# on RHEL-alikes and Ubuntu
#
class openstack::repo(
  $release = 'grizzly'
) {
  if $release == 'grizzly' {
    if $::osfamily == 'RedHat' {
      class {'openstack::repo::rdo': release => $release }
    } elsif $::operatingsystem == 'Ubuntu' {
      class {'openstack::repo::uca': release => $release }
    }
  } elsif $release == 'folsom' {
    if $::osfamily == 'RedHat' {
      include openstack::repo::epel
    } elsif $::operatingsystem == 'Ubuntu' {
      class {'openstack::repo::uca': release => $release }
    }
  } elsif $release == 'havana' {
    if $::osfamily == 'RedHat' {
      class {'openstack::repo::rdo': release => $release }
    } elsif $::operatingsystem == 'Ubuntu' {
      class {'openstack::repo::uca': release => $release }
    }
  } else {
      notify { "WARNING: openstack::repo parameter 'release' of '${release}' not recognized; please use 'grizzly' or 'folsom'.": }
  }
}
