class openstack::swift::storage-node (
  $swift_zone,
  $swift_hash_suffix    = 'swift_secret',
  $swift_local_net_ip   = $::ipaddress_eth0,
  $storage_type         = 'loopback',
  $storage_base_dir     = '/srv/loopback-device',
  $storage_mnt_base_dir = '/srv/node',
  $storage_devices      = ['1', '2'],
  $storage_weight       = 1,
  $package_ensure       = 'present'
) {

  class { 'swift': 
    swift_hash_suffix => $swift_hash_suffix,
    package_ensure    => $package_ensure,
  }

  case $storage_type {
    'loopback': {
      # create xfs partitions on a loopback device and mount them
      swift::storage::loopback { $storage_devices:
        base_dir     => $storage_base_dir,
        mnt_base_dir => $storage_mnt_base_dir,
        require      => Class['swift'],
      }
    }
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
  }

  define device_endpoint ($swift_local_net_ip, $zone, $weight) {
    @@ring_object_device { "${swift_local_net_ip}:6000/${name}":
      zone   => $swift_zone,
      weight => $weight,
    }
    @@ring_container_device { "${swift_local_net_ip}:6001/${name}":
      zone   => $swift_zone,
      weight => $weight,
    }
    @@ring_account_device { "${swift_local_net_ip}:6002/${name}":
      zone   => $swift_zone,
      weight => $weight,
    }
  }

  device_endpoint { $storage_devices:
    swift_local_net_ip => $swift_local_net_ip,
    zone               => $swift_zone,
    weight             => $storage_weight,
  }

  # collect resources for synchronizing the ring databases
  Swift::Ringsync<<||>>

}
