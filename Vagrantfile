require 'ipaddr'
require 'resolv'

# Auto generate a unique IP address and hostname
def generate_unused_ip_address(ip_address)
  loop do
    # Ensure that the generated IP address doesn't use reserved values of 0 or 1 for the last octet
    while ip_address.to_s.split('.').last.to_i < 2
      ip_address = ip_address.succ
    end

    begin
      name = Resolv::Hosts.new.getname(ip_address.to_s)
    rescue
      # The address does not exist in DNS - exit the loop
      break
    end

    ip_address = ip_address.succ
  end

  ip_address
end

Vagrant.configure('2') do |config|
  vagrant_root = File.dirname(__FILE__)
  config.vm.box = "ajxb/ubuntu-xenial64"

  # Ensure that database.sql.gz and site.tgz exists in provisioners/packages if NAS not available.

  # The following will load host config from a .host file if it exists, if the .host file does not exist a new IP
  # address / hostname is generated
  # This ensures persistence with the hostname / IP address between up / halt operations
  hostname = nil
  ip_address = nil
  if File.file? "#{vagrant_root}/.host"
    hostconfig = YAML.load_file("#{vagrant_root}/.host")
    ip_address = IPAddr.new hostconfig[:ip_address]
  else
    ip_address = generate_unused_ip_address(IPAddr.new '10.15.0.0')
    hostname = "wpblog-#{ip_address.to_s.split('.').last}.dev.home"
    hostconfig = {hostname: hostname, ip_address: ip_address.to_s}
    File.open("#{vagrant_root}/.host", 'w') {|file| file.write(hostconfig.to_yaml)}
  end

  config.vm.hostname = hostname
  config.vm.network 'private_network', ip: ip_address.to_s
  config.hostsupdater.remove_on_suspend = false

  config.vm.provider :virtualbox do |vb|
    vb.memory = '4096'
    vb.cpus = '2'
  end

  ##############################################################################
  # Vagrant specific provisioning
  ##############################################################################
  config.vm.provision 'shell', inline: '/vagrant/provisioners/script/install.sh'
  config.vm.provision 'shell', inline: '/vagrant/provisioners/script/install-site.sh'
  config.vm.provision :reload

  config.vm.post_up_message = "Hostname : #{hostname}\nIP Address : #{ip_address}"

  config.trigger.after :destroy, stdout: true do
    FileUtils.rm_rf "#{vagrant_root}/www" if File.exist? "#{vagrant_root}/www"
    FileUtils.rm_rf "#{vagrant_root}/tmp" if File.exist? "#{vagrant_root}/tmp"
    File.delete "#{vagrant_root}/.host" if File.file? "#{vagrant_root}/.host"
  end
end
