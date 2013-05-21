# EPEL repo (RHEL-alikes only, _not_ Fedora)
class openstack::repo::epel {
  include openstack::repo::yum_refresh

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
      before => Yumrepo['epel'],
    }
    Yumrepo['epel'] -> Package<||>
  }
}
