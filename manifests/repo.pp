#
# Sets up the package repos necessary to use OpenStack
# on RHEL-alikes and Ubuntu
#
class openstack::repo(
  $release = 'grizzly',
  $repo    = 'updates',
) {
  if $release == 'grizzly' {
    if $::osfamily == 'RedHat' {
      include openstack::repo::rdo
    } elsif $::operatingsystem == 'Ubuntu' {
      class {'openstack::repo::uca':
        release => $release,
        repo    => $repo,
      }
    }
  } elsif $release == 'folsom' {
    if $::osfamily == 'RedHat' {
      include openstack::repo::epel
    } elsif $::operatingsystem == 'Ubuntu' {
      class {'openstack::repo::uca': release => $release }
    }
  } else {
      notify { "WARNING: openstack::repo parameter 'release' of '${release}' not recognized; please use 'grizzly' or 'folsom'.": }
  }
}
