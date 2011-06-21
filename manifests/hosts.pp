Host { ensure => present }
host { 'puppetmaster':
  ip => '172.20.0.10',
}
host { 'all':
  ip => '172.20.0.11',
}

