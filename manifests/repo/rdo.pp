# RDO repo (supports Grizzly and Havana on both RHEL-alikes and Fedora, requires EPEL)
class openstack::repo::rdo(
  $release = 'grizzly'
) {
  include openstack::repo::epel

  if $::osfamily == 'RedHat' {
    $dist = $::operatingsystem ? {
      /(CentOS|RedHat|Scientific|SLC)/ => 'epel',
      'Fedora' => 'fedora',
    }
    # $lsbmajdistrelease is only available with redhat-lsb installed
    $osver = regsubst($::operatingsystemrelease, '(\d+)\..*', '\1')

    yumrepo { 'rdo-release':
      baseurl  => "http://repos.fedorapeople.org/repos/openstack/openstack-${release}/${dist}-${osver}/",
      descr    => 'OpenStack ${release} Repository',
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
      mode   => '0644',
      before => Yumrepo['rdo-release'],
    }
    Yumrepo['rdo-release'] -> Package<||>
  }
}
