require 'spec_helper'

describe 'openstack::compute' do

  let :params do
    {
      :private_interface         => 'eth0',
      :internal_address          => '127.0.0.2',
      :nova_user_password        => 'nova_pass',
      :rabbit_password           => 'rabbit_pw',
      :rabbit_host               => '127.0.0.1',
      :rabbit_virtual_host       => '/',
      :nova_admin_tenant_name    => 'services',
      :nova_admin_user           => 'nova',
      :enabled_apis              => 'ec2,osapi_compute,metadata',
      :nova_db_password          => 'pass',
      :cinder_db_password        => 'cinder_pass',
      :quantum                   => false,
      :fixed_range               => '10.0.0.0/16'
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
    }
  end

  describe "when using default class parameters" do
    it {
      should contain_class('nova').with(
        :sql_connection      => 'mysql://nova:pass@127.0.0.1/nova',
        :rabbit_host         => '127.0.0.1',
        :rabbit_userid       => 'openstack',
        :rabbit_password     => 'rabbit_pw',
        :rabbit_virtual_host => '/',
        :image_service       => 'nova.image.glance.GlanceImageService',
        :glance_api_servers  => false,
        :verbose             => false
      )
      should_not contain_resources('nova_config').with_purge(true)
      should contain_class('nova::compute').with(
        :enabled                        => true,
        :vnc_enabled                    => true,
        :vncserver_proxyclient_address  => '127.0.0.2',
        :vncproxy_host                  => false
      )
      should contain_class('nova::compute::libvirt').with(
        :libvirt_type     => 'kvm',
        :vncserver_listen => '127.0.0.2'
      )
      should contain_nova_config('DEFAULT/multi_host').with( :value => false )
      should contain_nova_config('DEFAULT/send_arp_for_ha').with( :value => false )
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
      should contain_class('openstack::cinder::storage').with(
        :sql_connection      => 'mysql://cinder:cinder_pass@127.0.0.1/cinder',
        :rabbit_password     => 'rabbit_pw',
        :rabbit_userid       => 'openstack',
        :rabbit_host         => '127.0.0.1',
        :rabbit_virtual_host => '/',
        :volume_group        => 'cinder-volumes',
        :iscsi_ip_address    => '127.0.0.1',
        :enabled             => true,
        :verbose             => false,
        :setup_test_volume   => false,
        :volume_driver       => 'iscsi'
      )
    }
  end

  describe "when overriding parameters, but not enabling multi-host or volume management" do
    before do
      params.merge!(
        :private_interface   => 'eth1',
        :internal_address    => '127.0.0.1',
        :public_interface    => 'eth2',
        :nova_user_password  => 'nova_pass',
        :nova_db_user        => 'nova_user',
        :nova_db_name        => 'novadb',
        :rabbit_host         => 'my_host',
        :rabbit_password     => 'my_rabbit_pw',
        :rabbit_user         => 'my_rabbit_user',
        :rabbit_virtual_host => '/foo',
        :glance_api_servers  => ['controller:9292'],
        :libvirt_type        => 'qemu',
        :vncproxy_host       => '127.0.0.2',
        :vnc_enabled         => false,
        :verbose             => true
      )
    end
    it do
      should contain_class('nova').with(
        :sql_connection      => 'mysql://nova_user:pass@127.0.0.1/novadb',
        :rabbit_host         => 'my_host',
        :rabbit_userid       => 'my_rabbit_user',
        :rabbit_password     => 'my_rabbit_pw',
        :rabbit_virtual_host => '/foo',
        :image_service       => 'nova.image.glance.GlanceImageService',
        :glance_api_servers  => ['controller:9292'],
        :verbose             => true
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
      should contain_nova_config('DEFAULT/multi_host').with( :value => false )
      should contain_nova_config('DEFAULT/send_arp_for_ha').with( :value => false )
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

  context 'with cinder' do
    before do
      params.merge!(
        :manage_volumes => false
      )
    end
    it { should_not contain_class('openstack::cinder::storage') }

  end

  context 'with rbd storage' do
    before do
      params.merge!(
          :cinder_volume_driver => 'rbd',
          :cinder_rbd_user      => 'volumes',
          :cinder_rbd_pool      => 'volumes'
      )
    end
    it do
      should contain_class('openstack::cinder::storage').with(
                 :sql_connection      => 'mysql://cinder:cinder_pass@127.0.0.1/cinder',
                 :rabbit_password     => 'rabbit_pw',
                 :rabbit_userid       => 'openstack',
                 :rabbit_host         => '127.0.0.1',
                 :rabbit_virtual_host => '/',
                 :volume_group        => 'cinder-volumes',
                 :iscsi_ip_address    => '127.0.0.1',
                 :enabled             => true,
                 :verbose             => false,
                 :setup_test_volume   => false,
                 :rbd_user            => 'volumes',
                 :rbd_pool            => 'volumes',
                 :volume_driver       => 'rbd'
             )
    end
  end
  
  describe 'when quantum is false' do

    describe 'configuring for multi host' do
      before do
        params.merge!(
          :multi_host       => true,
          :public_interface => 'eth0',
          :quantum          => false
        )
      end

      it 'should configure nova for multi-host' do
        #should contain_class('keystone::python')
        should contain_nova_config('DEFAULT/multi_host').with(:value => true)
        should contain_nova_config('DEFAULT/send_arp_for_ha').with( :value => true)
        should contain_class('nova::network').with({
          'enabled' => true,
          'install_service' => true
        })
        should_not contain_class('openstack::quantum')
      end

      describe 'with defaults' do
        it { should contain_class('nova::api').with(
          :enabled           => true,
          :admin_tenant_name => 'services',
          :admin_user        => 'nova',
          :admin_password    => 'nova_pass',
          :enabled_apis      => 'ec2,osapi_compute,metadata'
        )}
      end
    end

    describe 'when overriding network params' do
      before do
        params.merge!(
          :multi_host        => true,
          :public_interface  => 'eth0',
          :manage_volumes    => true,
          :private_interface => 'eth1',
          :public_interface  => 'eth2',
          :fixed_range       => '12.0.0.0/24',
          :network_manager   => 'nova.network.manager.VlanManager',
          :network_config    => {'vlan_interface' => 'eth0'}
        )
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
    before do
      params.merge!( :multi_host => true )
    end

    it {
      expect { should raise_error(Puppet::Error) }
    }
  end

  describe "when enabling volume management and using multi host" do
    before do
      params.merge!(
        :multi_host       => true,
        :public_interface => 'eth0',
        :manage_volumes   => true
      )
    end

    it {
      should contain_nova_config('DEFAULT/multi_host').with({ 'value' => true})
      should contain_class('nova::api')
      should contain_class('nova::network').with({
        'enabled' => true,
        'install_service' => true
      })
    }
  end

  describe 'when configuring quantum' do
    before do
      params.merge!(
        :internal_address      => '127.0.0.1',
        :public_interface      => 'eth3',
        :quantum               => true,
        :keystone_host         => '127.0.0.3',
        :quantum_host          => '127.0.0.2',
        :quantum_user_password => 'quantum_user_password'
      )
    end

    it 'should configure quantum' do
      should contain_class('openstack::quantum').with(
        :db_host           => '127.0.0.1',
        :ovs_local_ip      => params[:internal_address],
        :rabbit_host       => params[:rabbit_host],
        :rabbit_user       => 'openstack',
        :rabbit_password   => params[:rabbit_password],
        :enable_ovs_agent  => true,
        :firewall_driver   => false,
        :enable_l3_agent   => false,
        :enable_dhcp_agent => false,
        :auth_url          => 'http://127.0.0.1:35357/v2.0',
        :user_password     => params[:quantum_user_password],
        :keystone_host     => params[:keystone_host],
        :enabled           => true,
        :enable_server     => false,
        :verbose           => false
      )

      should contain_class('nova::compute::quantum').with(
        :libvirt_vif_driver => 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver'
      )

      should contain_class('nova::network::quantum').with(
        :quantum_admin_password    => 'quantum_user_password',
        :quantum_auth_strategy     => 'keystone',
        :quantum_url               => "http://127.0.0.2:9696",
        :quantum_admin_tenant_name => 'services',
        :quantum_admin_username    => 'quantum',
        :quantum_admin_auth_url    => "http://127.0.0.3:35357/v2.0"
      )

      should_not contain_class('quantum::server')
      should_not contain_class('quantum::plugins::ovs')
      should_not contain_class('quantum::agents::dhcp')
      should_not contain_class('quantum::agents::l3')
    end
  end

end
