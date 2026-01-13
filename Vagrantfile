# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"
  config.vm.hostname = "cloud-interview"
  config.vm.boot_timeout = 600
  config.vm.network "forwarded_port", guest: 8080, host: 8080 #nginx dev
  config.vm.network "forwarded_port", guest: 8081, host: 8081 #nginx test
  config.vm.network "forwarded_port", guest: 8082, host: 8082 #nginx qa
  config.vm.synced_folder ".", "/vagrant", type: "rsync",
    rsync__exclude: ["Vagrantfile",".git/"]
  config.vm.provision :docker
  config.vm.provision :shell,
    keep_color: true,
    run: "always",
    path: "./run.sh"

end
