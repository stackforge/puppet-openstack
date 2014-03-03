# Ubuntu Cloud Archive repo (supports either Folsom, Grizzly or Havana)
class openstack::repo::uca(
  $release = 'havana',
  $repo    = 'updates'
) {
  if ($::operatingsystem == 'Ubuntu' and
      $::lsbdistdescription =~ /^.*LTS.*$/) {
    include apt::update

    apt::source { 'ubuntu-cloud-archive':
      location          => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
      release           => "${::lsbdistcodename}-${repo}/${release}",
      repos             => 'main',
      required_packages => 'ubuntu-cloud-keyring',
    }
  }
}
