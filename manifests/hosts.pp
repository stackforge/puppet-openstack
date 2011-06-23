Host { ensure => present }
host { 'puppetmaster':
  ip => '172.20.0.10',
}
host { 'all':
  ip => '172.20.0.11',
}
host { 'db':
  ip => '172.20.0.12'
}
host { 'rabbitmq':
  ip => '172.20.0.13',
}
host { 'controller':
  ip => '172.20.0.14',
}
host { 'compute':
  ip => '172.20.0.15',
}
host { 'glance':
  ip => '172.20.0.16',
}
