# Wordpress Development Sandbox

## Description

A vagrant machine that provides a full sandboxed development environment for a wordpress site.

## Requires

* vagrant plugin vagrant-hostsupdater
* vagrant plugin vagrant-reload
* vagrant plugin vagrant-triggers

## Usage

1. Ensure a tgz archive of the wordpress site to use exists in the `provisioners/packages` folder with the name `site.tgz`
* Ensure a gz archive of the database to use exists in the `provisioners/packages` folder with the name `database.sql.gz`
* Bring up the vagrant machine, once up you should be able to navigate to the given hostname in a browser to view the site.

## Verified Working With

* vagrant 2.0.1
* VirtualBox 5.1.30
