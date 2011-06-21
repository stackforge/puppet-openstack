Vagrant::Config.run do |config|

  #vagrant config file for building out multi-node with Puppet :)
  box = 'natty'
  remote_url_base = ENV['REMOTE_VAGRANT_STORE']

  config.vm.box = "#{box}"
  config.vm.box_url = "http://faro.puppetlabs.lan/vagrant/#{box}.box"

  config.ssh.forwarded_port_key = "ssh"
  ssh_forward = 2231


  config.vm.box = "#{box}"
  config.vm.box_url = "http://faro.puppetlabs.lan/vagrant/#{box}.vbox"
  config.vm.customize do |vm|
    vm.memory_size = 768
    vm.cpu_count = 1
  end

  net_base = "172.20.0"

  # the master runs apply to configure itself
  config.vm.define :puppetmaster do |pm|

    pm.vm.box = "natty"
    pm.vm.forward_port("http", 8140, 8141)
    ssh_forward = ssh_forward + 1
    pm.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    # hard-coding this b/c it is important
    pm.vm.network("#{net_base}.10")
    pm.vm.provision :puppet do |puppet|
      puppet.manifest_file = "master.pp"
      puppet.options = ["--certname","puppetmaster", '--modulepath', '/vagrant/modules']
    end
  end

  config.vm.define :all do |all|
    all.vm.box = "natty"
    ssh_forward = ssh_forward + 1
    all.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    all.vm.network("#{net_base}.11")
    all.vm.provision :puppet do |puppet|
      puppet.manifests_path = "manifests"
      puppet.manifest_file = "all.pp"
      puppet.options = ['--certname', 'all', '--modulepath', '/vagrant/modules']
    end
  end

  config.vm.define :database do |mysql|
  end

end

# vim:ft=ruby
