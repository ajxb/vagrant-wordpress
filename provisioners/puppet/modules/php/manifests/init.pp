class php ( $xdebug_remote_port = 9000 ) {

  include ::apache::mod::php

  $php_packages = [
    'php-bcmath',
    'php-calendar',
    'php-cli',
    'php-ctype',
    'php-curl',
    'php-date',
    'php-dom',
    'php-exif',
    'php-fileinfo',
    'php-ftp',
    'php-gd',
    'php-geoip',
    'php-gettext',
    'php-iconv',
    'php-imap',
    'php-intl',
    'php-json',
    'php-ldap',
    'php-mbstring',
    'php-mcrypt',
    'php-memcache',
    'php-memcached',
    'php-mysqli',
    'php-mysqlnd',
    'php-pgsql',
    'php-posix',
    'php-soap',
    'php-sockets',
    'php-sqlite3',
    'php-tidy',
    'php-tokenizer',
    'php-xdebug',
    'php-xml',
    'php-xmlreader',
    'php-xmlrpc',
    'php-xmlwriter',
    'php-xsl',
    'php-zip',
  ]

  package { $php_packages:
    ensure => 'latest',
  }

  file { '/etc/php/7.0/mods-available/xdebug.ini':
    content => template('php/xdebug.ini.erb'),
    ensure  => 'file',
    group   => 'root',
    mode    => '0644',
    owner   => 'root',
    require => Package['php-xdebug'],
  }

}
