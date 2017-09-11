# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/xenial64"


  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-add-repository ppa:brightbox/ruby-ng
    sudo apt-get update
    sudo apt-get install -y ruby2.3
    wget https://github.com/PowerShell/PowerShell/releases/download/v6.0.0-beta.6/powershell_6.0.0-beta.6-1ubuntu1.16.04.1_amd64.deb
    apt-get install -y libunwind8 libcurl3 mono-complete
    dpkg -i powershell_6.0.0-beta.6-1ubuntu1.16.04.1_amd64.deb
  SHELL
end
