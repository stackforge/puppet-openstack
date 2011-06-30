Vagrant::Config.run do |config|

  #vagrant config file for building out multi-node with Puppet :)
  box = 'natty_openstack'
  remote_url_base = ENV['REMOTE_VAGRANT_STORE']

  config.vm.box = "#{box}"

  config.ssh.forwarded_port_key = "ssh"
  ssh_forward = 2222


  config.vm.box = "#{box}"
  config.vm.box_url = "#{remote_url_base}/#{box}.vbox"
  config.vm.customize do |vm|
    vm.memory_size = 768
    vm.cpu_count = 1
  end

  net_base = "172.21.0"

  # the master runs apply to configure itself
  config.vm.define :puppetmaster do |pm|

    pm.vm.forward_port("http", 8140, 8140)
    ssh_forward = ssh_forward + 1
    pm.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    # hard-coding this b/c it is important
    pm.vm.network("#{net_base}.10")
    #pm.vm.provision :puppet do |puppet|
    #  puppet.manifest_file = "master.pp"
    #  puppet.options = ["--certname","puppetmaster", '--modulepath', '/vagrant/modules']
    #end
  end

  config.vm.define :all do |all|
    ssh_forward = ssh_forward + 1
    all.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    all.vm.network("#{net_base}.11")
    all.vm.provision :shell, :path => 'scripts/run-all.sh'
  end

  config.vm.define :db do |mysql|
    ssh_forward = ssh_forward + 1
    mysql.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    mysql.vm.network("#{net_base}.12")
    mysql.vm.provision :shell, :path => 'scripts/run-db.sh'
  end

  config.vm.define :rabbitmq do |rabbit|
    ssh_forward = ssh_forward + 1
    rabbit.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    rabbit.vm.network("#{net_base}.13")
    rabbit.vm.provision :shell, :path => 'scripts/run-rabbitmq.sh'
  end
  config.vm.define :controller do |controller|
    ssh_forward = ssh_forward + 1
    controller.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    controller.vm.network("#{net_base}.14")
    controller.vm.provision :shell, :path => 'scripts/run-controller.sh'
  end
  config.vm.define :compute do |compute|
    ssh_forward = ssh_forward + 1
    compute.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    compute.vm.network("#{net_base}.15")
    compute.vm.provision :shell, :path => 'scripts/run-compute.sh'
  end
  config.vm.define :glance do |glance|
    ssh_forward = ssh_forward + 1
    glance.vm.forward_port('ssh', 22, ssh_forward, :auto => true)
    glance.vm.network("#{net_base}.16")
    glance.vm.provision :shell, :path => 'scripts/run-glance.sh'
  end
end

# vim:ft=ruby
