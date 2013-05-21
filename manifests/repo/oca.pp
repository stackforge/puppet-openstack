# OpenStack Cloud Archive repo (supports either Folsom or Grizzly)
class openstack::repo::oca(
  $release = 'grizzly'
) {
  include apt::update

  apt::source { 'openstack-cloud-archive':
    location          => "http://ubuntu-cloud.archive.canonical.com/ubuntu",
    release           => "precise-updates/${release}",
    repos             => "main",
    required_packages => 'ubuntu-cloud-keyring',
  }

  Exec['apt_update'] -> Package<||>
}
