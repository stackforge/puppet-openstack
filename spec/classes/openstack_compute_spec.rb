require 'spec_helper'

describe 'openstack::compute' do

  let :default_params do
    {
      :private_interface     => 'eth0',
      :internal_address      => '0.0.0.0',
      :nova_user_password    => 'nova_pass',
      :rabbit_password       => 'rabbit_pw',
      :sql_connection        => 'mysql://user:pass@host/dbname/',
      :cinder_sql_connection => 'mysql://user:pass@host/dbname/',
      :quantum               => false,
      :fixed_range           => '10.0.0.0/16',
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
    }
  end

  describe "when using default class parameters" do
    let :params do
      default_params
    end
    it {
      should contain_class('nova').with(
        :sql_connection     => 'mysql://user:pass@host/dbname/',
        :rabbit_host        => '127.0.0.1',
        :rabbit_userid      => 'nova',
        :rabbit_password    => 'rabbit_pw',
        :image_service      => 'nova.image.glance.GlanceImageService',
        :glance_api_servers => false,
        :verbose            => 'False'
      )
      should contain_class('nova::compute').with(
        :enabled                        => true,
        :vnc_enabled                    => true,
        :vncserver_proxyclient_address  => '0.0.0.0',
        :vncproxy_host                  => false
      )
      should contain_class('nova::compute::libvirt').with(
        :libvirt_type     => 'kvm',
        :vncserver_listen => '0.0.0.0'
      )
      should contain_nova_config('multi_host').with( :value => 'False' )
      should contain_nova_config('send_arp_for_ha').with( :value => 'False' )
      should_not contain_class('nova::api')
      should contain_class('nova::network').with({
        :enabled           => false,
        :install_service   => false,
        :private_interface => 'eth0',
        :public_interface  => nil,
        :fixed_range       => '10.0.0.0/16',
        :floating_range    => false,
        :network_manager   => 'nova.network.manager.FlatDHCPManager',
        :config_overrides  => {},
        :create_networks   => false,
        :enabled           => false,
        :install_service   => false
      })
    }
  end

  describe "when overriding parameters, but not enabling multi-host or volume management" do
    let :override_params do
      {
        :private_interface   => 'eth1',
        :internal_address    => '127.0.0.1',
        :public_interface    => 'eth2',
        :sql_connection      => 'mysql://user:passwd@host/name',
        :nova_user_password  => 'nova_pass',
        :rabbit_host         => 'my_host',
        :rabbit_password     => 'my_rabbit_pw',
        :rabbit_user         => 'my_rabbit_user',
        :glance_api_servers  => ['controller:9292'],
        :libvirt_type        => 'qemu',
        :vncproxy_host       => '127.0.0.2',
        :vnc_enabled         => false,
        :verbose             => true,
      }
    end
    let :params do
      default_params.merge(override_params)
    end
    it do
      should contain_class('nova').with(
        :sql_connection     => 'mysql://user:passwd@host/name',
        :rabbit_host        => 'my_host',
        :rabbit_userid      => 'my_rabbit_user',
        :rabbit_password    => 'my_rabbit_pw',
        :image_service      => 'nova.image.glance.GlanceImageService',
        :glance_api_servers => ['controller:9292'],
        :verbose            => true
      )
      should contain_class('nova::compute').with(
        :enabled                        => true,
        :vnc_enabled                    => false,
        :vncserver_proxyclient_address  => '127.0.0.1',
        :vncproxy_host                  => '127.0.0.2'
      )
      should contain_class('nova::compute::libvirt').with(
        :libvirt_type     => 'qemu',
        :vncserver_listen => '127.0.0.1'
      )
      should contain_nova_config('multi_host').with( :value => 'False' )
      should contain_nova_config('send_arp_for_ha').with( :value => 'False' )
      should_not contain_class('nova::api')
      should contain_class('nova::network').with({
        :enabled           => false,
        :install_service   => false,
        :private_interface => 'eth1',
        :public_interface  => 'eth2',
        :create_networks   => false,
        :enabled           => false,
        :install_service   => false
      })
    end
  end

  describe "when enabling volume management" do
    let :params do
      default_params.merge({
        :manage_volumes => true
      })
    end

    it do
      should contain_nova_config('multi_host').with({ 'value' => 'False'})
      should_not contain_class('nova::api')
      should contain_class('nova::network').with({
        'enabled' => false,
        'install_service' => false
      })
    end
  end

  describe 'when quantum is false' do
    describe 'configuring for multi host' do
      let :params do
        default_params.merge({
          :multi_host       => true,
          :public_interface => 'eth0',
          :quantum          => false
        })
      end

      it 'should configure nova for multi-host' do
        #should contain_class('keystone::python')
        should contain_nova_config('multi_host').with(:value => 'True')
        should contain_nova_config('send_arp_for_ha').with( :value => 'True')
        should contain_class('nova::network').with({
          'enabled' => true,
          'install_service' => true
        })
      end
      describe 'with defaults' do
        it { should contain_class('nova::api').with(
          :enabled           => true,
          :admin_tenant_name => 'services',
          :admin_user        => 'nova',
          :admin_password    => 'nova_pass'
        )}
      end
    end
    describe 'when overriding network params' do
      let :params do
        default_params.merge({
          :multi_host        => true,
          :public_interface  => 'eth0',
          :manage_volumes    => true,
          :private_interface => 'eth1',
          :public_interface  => 'eth2',
          :fixed_range       => '12.0.0.0/24',
          :network_manager   => 'nova.network.manager.VlanManager',
          :network_config    => {'vlan_interface' => 'eth0'}
        })
      end
      it { should contain_class('nova::network').with({
        :private_interface => 'eth1',
        :public_interface  => 'eth2',
        :fixed_range       => '12.0.0.0/24',
        :floating_range    => false,
        :network_manager   => 'nova.network.manager.VlanManager',
        :config_overrides  => {'vlan_interface' => 'eth0'},
        :create_networks   => false,
        'enabled'          => true,
        'install_service'  => true
      })}
    end
  end

  describe "when configuring for multi host without a public interface" do
    let :params do
      default_params.merge({
        :multi_host => true
      })
    end

    it {
      expect { should raise_error(Puppet::Error) }
    }
  end

  describe "when enabling volume management and using multi host" do
    let :params do
      default_params.merge({
        :multi_host       => true,
        :public_interface => 'eth0',
        :manage_volumes   => true,
      })
    end

    it {
      should contain_nova_config('multi_host').with({ 'value' => 'True'})
      should contain_class('nova::api')
      should contain_class('nova::network').with({
        'enabled' => true,
        'install_service' => true
      })
    }
  end

end
