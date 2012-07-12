class { 'openstack::compute': 
  sql_connection     => 'mysql://foo:bar@192.168.1.1/nova',
  glance_api_servers => '192.168.1.1:9292',
}
