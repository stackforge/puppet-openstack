#
# This manifest installs all of the nova
# components on one node.
import 'hosts.pp'
resources { 'nova_config':
  purge => true,
}
class { 'mysql::server': }
class { 'nova::all':
  db_password => 'password',
  db_name => 'nova',
  db_user => 'nova',
  db_host => 'localhost',

  rabbit_password => 'rabbitpassword',
  rabbit_port => '5672',
  rabbit_userid => 'rabbit_user',
  rabbit_virtual_host => '/',
  rabbit_host => 'localhost',

  image_service => 'nova.image.glance.GlanceImageService',

  glance_host => 'localhost',
  glance_port => '9292',

  libvirt_type => 'qemu',
}
