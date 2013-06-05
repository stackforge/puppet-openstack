# This can be used to install only the client libraries

class openstack::client (
  $nova = true,
  $glance = true,
  $quantum = true,
  $cinder = true,
  $keystone = true
) {    
  
  if $nova {
      class { 'nova::client': }
  }
  
  if $glance {
      class { 'glance::params': } ->
      class { 'glance::client': }
  }
  
  if $quantum {
      class { 'quantum::client': }
  }
  
  if $cinder {
      class { 'cinder::client': }
  }
  
  if $keystone {
      class { 'keystone::params': } ->
      class { 'keystone::python': }
  }

}

