#
# Sets up the package repos necessary to use OpenStack
# on RHEL-alikes and Ubuntu
#
class openstack::repo(
  $release = 'grizzly'
) {
  if $release == 'grizzly' {
    if $::osfamily == 'RedHat' {
      include openstack::repo_rdo
    } elsif $::operatingsystem == 'Ubuntu' {
      class {'openstack::repo_oca': release => $release }
    }
  } elsif $release == 'folsom' {
    if $::osfamily == 'RedHat' {
      include openstack::repo_epel
    } elsif $::operatingsystem == 'Ubuntu' {
      class {'openstack::repo_oca': release => $release }
    }
  } else {
      notify { "WARNING: openstack::repo parameter 'release' of '${release}' not recognized; please use 'grizzly' or 'folsom'.": }
  }
}

# Make sure to refresh yum database after adding repos and before installing packages
class openstack::yum_refresh {
  exec { 'yum_refresh':
    command     => '/usr/bin/yum clean all',
    refreshonly => true,
  }
  Exec['yum_refresh'] -> Package<||>
}

# EPEL repo (RHEL-alikes only, _not_ Fedora)
class openstack::repo_epel {
  include openstack::yum_refresh

  if $::osfamily == 'RedHat' and $::operatingsystem != 'Fedora' {
    yumrepo { 'epel':
      mirrorlist     => 'https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
      descr          => 'Extra Packages for Enterprise Linux 6 - $basearch',
      enabled        => 1,
      gpgcheck       => 1,
      gpgkey         => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6',
      failovermethod => priority,
      notify         => Exec['yum_refresh']
    }
    file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6':
      source => 'puppet:///modules/openstack/RPM-GPG-KEY-EPEL-6',
      owner  => root,
      group  => root,
      mode   => 644,
    }
    Yumrepo['epel'] -> Package<||>
  }
}

# RDO repo (supports Grizzly on both RHEL-alikes and Fedora, requires EPEL)
class openstack::repo_rdo {
  include openstack::repo_epel

  if $::osfamily == 'RedHat' {
    $dist = $::operatingsystem ? {
      'CentOS' => 'epel',
      'Fedora' => 'fedora',
    }
    # $operatingsystemmajrelease is only available with redhat-lsb installed
    $osver = regsubst($::operatingsystemrelease, '(\d+)\..*', '\1')

    yumrepo { 'rdo-release':
      baseurl  => "http://repos.fedorapeople.org/repos/openstack/openstack-grizzly/${dist}-${osver}/",
      descr    => 'OpenStack Grizzly Repository',
      enabled  => 1,
      gpgcheck => 1,
      gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-Grizzly',
      priority => 98,
      notify   => Exec['yum_refresh'],
    }
    file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-RDO-Grizzly':
      source => 'puppet:///modules/openstack/RPM-GPG-KEY-RDO-Grizzly',
      owner  => root,
      group  => root,
      mode   => 644,
    }
    Yumrepo['rdo-release'] -> Package<||>
  }
}

# Make sure to refresh apt database after adding repos and before installing packages
class openstack::apt_refresh {
  exec { 'apt_refresh':
    command     => '/usr/bin/apt-get update',
    refreshonly => true,
  }
  Exec['apt_refresh'] -> Package<||>
}

# OpenStack Cloud Archive repo (supports either Folsom or Grizzly)
class openstack::repo_oca(
  $release = 'grizzly'
) {
  include openstack::apt_refresh

  apt::source { 'openstack-cloud-archive':
    location          => "http://ubuntu-cloud.archive.canonical.com/ubuntu",
    release           => "precise-updates/${release}",
    repos             => "main",
    required_packages => 'ubuntu-cloud-keyring',
    notify            => Exec['apt_refresh'],
  }

  Apt::Source['openstack-cloud-archive'] -> Package<||>
}
