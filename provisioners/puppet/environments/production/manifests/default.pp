include ntp

###############################################################################
# Parameters
###############################################################################

###############################################################################
# Update package list
###############################################################################
exec { 'refresh-package-list':
  command => '/usr/bin/apt-get update'
}

###############################################################################
# resolvconf
###############################################################################
class {'resolv_conf':
  nameservers => [ '8.8.8.8', '8.8.4.4' ],
  searchpath  => [ 'home' ],
}

###############################################################################
# MySQL
###############################################################################
class { 'mysql::server':
  root_password => 'r00tpa$$w0rd',
}

class { 'mysql::bindings':
  php_enable       => true,
  php_package_name => 'php-mysql'
}

mysql::db { 'wordpress':
  charset  => 'utf8',
  grant    => [ 'ALL' ],
  host     => 'localhost',
  password => 'wordpress',
  user     => 'wordpress',
}

###############################################################################
# Apache
###############################################################################
class { 'apache':
  default_confd_files => true,
  default_mods        => true,
  default_vhost       => false,
  group               => 'vagrant',
  mpm_module          => 'prefork',
  user                => 'vagrant',
}

include apache::mod::rewrite

# Default Host
apache::vhost { $::fqdn:
  directories => [ { path => '/vagrant/www', allow_override => 'ALL' }, ],
  docroot     => '/vagrant/www',
  port        => '80',
  require     => File['/vagrant/www'],
  setenv      => 'WP_ENV dev',
}

file { '/vagrant/www':
  ensure => directory,
}

###############################################################################
# php
###############################################################################
class { 'php':
  notify => Service['apache2'],
}

###############################################################################
# phpMyAdmin
###############################################################################
class { 'phpmyadmin':
  ip_access_ranges => [ "${facts['networking']['interfaces']['enp0s8']['ip']}/${facts['networking']['interfaces']['enp0s8']['netmask']}" ],
  require          => [
    Class['apache'],
    Class['mysql::server'],
  ],
}

phpmyadmin::server{ 'default':
  resource_collect => false,
}

###############################################################################
# Ordering
###############################################################################
Class['resolv_conf'] -> Exec['refresh-package-list']
Exec['refresh-package-list'] -> Package <| |>
