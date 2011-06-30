require 'vagrant'

env=Vagrant::Environment.new(:cwd => File.dirname(__FILE__))
# this captures the regular output to stdout
env.ui = Vagrant::UI::Shell.new(env, Thor::Base.shell.new)
env.load!

# all of the instance to build out for multi-node
instances = [
  :db,
  :rabbitmq,
  :glance,
  :controller,
  :compute
]

namespace :build do
  desc 'build out 5 node openstack cluster'
  task :multi do
    instance.each do |instance|
      build(instance, env)
    end
  end
  desc 'build out openstack on one node'
  task :all do
    build(:all, env)
  end
end

# bring vagrant vm with image name up
def build(instance, env)
  unless vm = env.vms[instance]
    puts "invalid VM: #{instance}"
  else
    if vm.created?
      puts "VM: #{instance} was already created"
    else
      # be very fault tolerant :)
      begin
        # this will always fail
        vm.up(:provision => true)
      rescue Exception => e
        puts e.class
        puts e
      end
    end
  end
end

namespace :test do
  desc 'test multi-node installation'
  task :multi do
    {:glance => ['sudo /vagrant/ext/glance.sh'],
      :controller => ['sudo /vagrant/ext/nova.sh'],
    }.each do |instance, commands|
      test(instance, commands, env)
    end
  end
  desc 'test single node installation'
  task :all do
    test(:all, ['sudo /vagrant/ext/glance.sh', 'sudo /vagrant/ext/nova.sh'], env)
  end
end

def test(instance, commands, env)
  unless vm = env.vms[instance]
    puts "invalid VM: #{instance}"
  else
    puts "testing :#{instance}"
    vm.ssh.execute do |ssh|
      commands.each do |c|
        #puts ssh.methods - Object.methods
        puts ssh.exec!(c)
      end
    end
  end
end
