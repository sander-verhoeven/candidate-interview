# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.


Vagrant.configure("2") do |config|
  config.vm.box         = "ubuntu/jammy64"
  config.vm.box_version = "20241002.0.0"
  config.vm.boot_timeout = 600

  # Common rsync for all machines
  config.vm.synced_folder ".", "/vagrant",
    type: "rsync",
    rsync__exclude: ["Vagrantfile", ".git/"]

  {
    "dev"  => 8080,
    "test" => 8081,
    "qa"   => 8082
  }.each do |name, port|
    config.vm.define name do |node|
      node.vm.hostname = "cloud-interview-#{name}"

      # Ports per VM
      node.vm.network "forwarded_port",
        guest: port, host: port, host_ip: "127.0.0.1"

      # Load env per machine
      env_file = ".env.#{name}"
      abort("Missing #{env_file}") unless File.exist?(env_file)
      env_vars = {}
      File.readlines(env_file).each do |line|
        next if line.strip.empty? || line.strip.start_with?("#")
        key, value = line.strip.split("=", 2)
        env_vars[key] = value
      end
      env_vars["APP_ENV"] ||= name

      node.vm.provision :docker
      node.vm.provision :shell,
        keep_color: true,
        run: "always",
        path: "./run.sh",
        env: env_vars
    end
  end
end

