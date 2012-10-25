require 'spec_helper'

describe 'openstack::controller' do
  let :default_params do
    {
      :private_interface => 'eth0',
      :public_interface  => 'eth1',
      :internal_address  => '127.0.0.1',
      :public_address    => '10.0.0.1',
      :export_resources  => false,
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :concat_basedir  => '/tmp/',
      :puppetversion   => '2.7.x',
      :memorysize      => '2GB',
      :processorcount  => '2'
    }
  end
  let :params do
    default_params
  end

  it { should_not contain_nova_config('auto_assign_floating_ip') }
  describe 'when auto assign floating ip is assigned' do
    let :params do
      default_params.merge(:auto_assign_floating_ip => 'true')
    end
    it { should contain_nova_config('auto_assign_floating_ip').with(:value => 'True')}
  end

  it do
    should contain_class('mysql::server').with(
      :config_hash => {'bind_address' => '0.0.0.0', 'root_password' => 'sql_pass' }
    )
    should contain_class('memcached').with(
      :listen_ip => '127.0.0.1'
    )
  end

  describe 'when enabled' do
    it 'should contain enabled database configs' do
      should contain_class('mysql::server').with(
        :enabled => true
      )
      should contain_class('keystone::db::mysql').with(
        :password => 'keystone_pass'
      )
      should contain_class('glance::db::mysql').with(
        :host     => '127.0.0.1',
        :password => 'glance_pass',
        :before   => ["Class[Glance::Registry]", "Exec[glance-manage db_sync]"]
      )
      should contain_class('nova::db::mysql').with(
        :password      => 'nova_pass',
        :host          => '127.0.0.1',
        :allowed_hosts => '%'
      )
    end
    it 'should contain enabled keystone configs with defaults' do

      should contain_class('keystone').with(
        :admin_token  => 'keystone_admin_token',
        :bind_host    => '0.0.0.0',
        :verbose      => false,
        :debug        => false,
        :catalog_type => 'sql',
        :enabled      => true
      )
      should contain_class('keystone::config::mysql').with(
        :password => 'keystone_pass'
      )
      should contain_class('keystone::roles::admin').with(
        :email    => 'some_user@some_fake_email_address.foo',
        :password => 'ChangeMe'
      )
      should contain_class('keystone::endpoint').with(
        :public_address   => '10.0.0.1',
        :internal_address => '127.0.0.1',
        :admin_address    => '127.0.0.1'
      )
      should contain_class('glance::keystone::auth').with(
        :password         => 'glance_pass',
        :public_address   => '10.0.0.1',
        :internal_address => '127.0.0.1',
        :admin_address    => '127.0.0.1'
        #:before           => ['Class[glance::api]', 'Class[glance::registry]']
      )
      should contain_class('nova::keystone::auth').with(
        :password         => 'nova_pass',
        :public_address   => '10.0.0.1',
        :internal_address => '127.0.0.1',
        :admin_address    => '127.0.0.1'
        #:before           => 'Class[nova::api]'
      )
      should contain_class('glance::api').with(
        :verbose           => false,
        :debug             => false,
        :auth_type         => 'keystone',
        :auth_host         => '127.0.0.1',
        :auth_port         => '35357',
        :keystone_tenant   => 'services',
        :keystone_user     => 'glance',
        :keystone_password => 'glance_pass',
        :enabled           => true
      )
      should contain_class('glance::backend::file')

      should contain_class('glance::registry').with(
        :verbose           => false,
        :debug             => false,
        :auth_type         => 'keystone',
        :auth_host         => '127.0.0.1',
        :auth_port         => '35357',
        :keystone_tenant   => 'services',
        :keystone_user     => 'glance',
        :keystone_password => 'glance_pass',
        :sql_connection    => "mysql://glance:glance_pass@127.0.0.1/glance",
        :enabled           => true
      )
      should contain_class('nova::rabbitmq').with(
        :userid   => 'nova',
        :password => 'rabbit_pw',
        :enabled  => true
      )
      should contain_class('nova').with(
        :sql_connection     => 'mysql://nova:nova_pass@127.0.0.1/nova',
        :rabbit_host        => '127.0.0.1',
        :rabbit_userid      => 'nova',
        :rabbit_password    => 'rabbit_pw',
        :image_service      => 'nova.image.glance.GlanceImageService',
        :glance_api_servers => '10.0.0.1:9292',
        :verbose            => false
      )
      should contain_class('nova::api').with(
        :enabled           => true,
        :admin_tenant_name => 'services',
        :admin_user        => 'nova',
        :admin_password    => 'nova_pass'
      )
      should contain_class('nova::cert').with(:enabled => true)
      should contain_class('nova::consoleauth').with(:enabled => true)
      should contain_class('nova::scheduler').with(:enabled => true)
      should contain_class('nova::objectstore').with(:enabled => true)
      should contain_class('nova::vncproxy').with(:enabled => true)
      should contain_class('horizon').with(
        :secret_key        => 'dummy_secret_key',
        :cache_server_ip   => '127.0.0.1',
        :cache_server_port => '11211',
        :swift             => false,
        :quantum           => false,
        :horizon_app_links => false
     )

    end
    describe 'when overriding params' do
      let :params do
        default_params.merge(
          :keystone_db_password => 'pass',
          :glance_db_password   => 'pass2',
          :nova_db_password     => 'pass3',
          :verbose              => true,
          :keystone_admin_token => 'foo',
          :nova_user_password   => 'pass5',
          :glance_user_password => 'pass6',
          :admin_email          => 'dan@puppetlabs.com',
          :admin_address        => '127.0.0.2',
          :admin_password       => 'pass7',
          :rabbit_user          => 'rabby',
          :rabbit_password      => 'rabby_pw',
          :fixed_range          => '10.0.0.0/24',
          :floating_range       => '11.0.0.0/24',
          :network_manager      => 'nova.network.manager.VlanManager',
          :network_config       => {'vlan_interface' => 'eth4'},
          :num_networks         => 2,
          :secret_key           => 'real_secret_key',
          :cache_server_ip      => '127.0.0.2',
          :cache_server_port    => '11212',
          :swift                => true,
          :quantum              => true,
          :horizon_app_links    => true,
          :glance_api_servers   => '127.0.0.1:9292'
        )
      end
      it 'should override db config' do
        should contain_class('keystone::db::mysql').with(
          :password => 'pass'
        )
        should contain_class('glance::db::mysql').with(
          :password => 'pass2'
        )
        should contain_class('nova::db::mysql').with(
          :password      => 'pass3'
        )
      end

      it 'should override keystone config' do
        should contain_class('keystone').with(
          :verbose     => true,
          :debug       => true,
          :admin_token => 'foo'
        )
        should contain_class('keystone::config::mysql').with(
          :password => 'pass'
        )
        should contain_class('keystone::endpoint').with(
          :admin_address    => '127.0.0.2'
        )
        should contain_class('keystone::roles::admin').with(
          :email    => 'dan@puppetlabs.com',
          :password => 'pass7'
        )
        should contain_class('glance::keystone::auth').with(
          :password         => 'pass6',
          :admin_address    => '127.0.0.2'
        )
        should contain_class('nova::keystone::auth').with(
          :password         => 'pass5',
          :admin_address    => '127.0.0.2'
        )
      end
      it 'should override glance config' do
        should contain_class('glance::api').with(
          :verbose           => true,
          :debug             => true,
          :keystone_password => 'pass6',
          :enabled           => true
        )
        should contain_class('glance::registry').with(
          :verbose           => true,
          :debug             => true,
          :keystone_password => 'pass6',
          :sql_connection    => "mysql://glance:pass2@127.0.0.1/glance",
          :enabled           => true
        )
      end
      it 'should override nova config' do
        should contain_class('nova::rabbitmq').with(
          :userid   => 'rabby',
          :password => 'rabby_pw',
          :enabled  => true
        )
        should contain_class('nova').with(
          :sql_connection     => 'mysql://nova:pass3@127.0.0.1/nova',
          :rabbit_host        => '127.0.0.1',
          :rabbit_userid      => 'rabby',
          :rabbit_password    => 'rabby_pw',
          :image_service      => 'nova.image.glance.GlanceImageService',
          :glance_api_servers => '127.0.0.1:9292',
          :verbose            => true
        )
        should contain_class('nova::api').with(
          :enabled           => true,
          :admin_tenant_name => 'services',
          :admin_user        => 'nova',
          :admin_password    => 'pass5'
        )
        should contain_class('nova::network').with(
          :fixed_range       => '10.0.0.0/24',
          :floating_range    => '11.0.0.0/24',
          :network_manager   => 'nova.network.manager.VlanManager',
          :config_overrides  => {'vlan_interface' => 'eth4'},
          :num_networks      => 2
        )
      end
      describe 'it should override horizon params' do
        it { should contain_class('horizon').with(
          :secret_key        => 'real_secret_key',
          :cache_server_ip   => '127.0.0.2',
          :cache_server_port => '11212',
          :swift             => true,
          :quantum           => true,
          :horizon_app_links => true
        )}
      end
    end
  end

  describe 'when not enabled' do
    let :params do
      default_params.merge(:enabled => false)
    end
    it do
      should contain_class('mysql::server').with(
        :enabled => false
      )
      should_not contain_class('keystone::db::mysql')
      should_not contain_class('glance::db::mysql')
      should_not contain_class('nova::db::mysql')
      should contain_class('keystone::config::mysql')
      should contain_class('keystone').with(:enabled => false)
      should_not contain_class('keystone::roles::admin')
      should_not contain_class('keystone::endpoint')
      should_not contain_class('glance::keystone::auth')
      should_not contain_class('nova::keystone::auth')
      should contain_class('glance::api').with(:enabled => false)
      should contain_class('glance::backend::file')
      should contain_class('glance::registry').with(:enabled => false)
      should contain_class('nova::rabbitmq').with(:enabled => false)
      should contain_class('nova::api').with(:enabled => false)
      should contain_class('nova::cert').with(:enabled => false)
      should contain_class('nova::consoleauth').with(:enabled => false)
      should contain_class('nova::scheduler').with(:enabled => false)
      should contain_class('nova::objectstore').with(:enabled => false)
      should contain_class('nova::vncproxy').with(:enabled => false)
    end
  end

  describe 'nova network config' do

    describe 'when enabled' do

      describe 'when multihost is not set' do

        it {should contain_class('nova::network').with(
          :private_interface => 'eth0',
          :public_interface  => 'eth1',
          :fixed_range       => '10.0.0.0/24',
          :floating_range    => false,
          :network_manager   => 'nova.network.manager.FlatDHCPManager',
          :config_overrides  => {},
          :create_networks   => true,
          :num_networks      => 1,
          :enabled           => true,
          :install_service   => true
        )}

      end
      describe 'when multihost is set' do
        let :params do
          default_params.merge(:multi_host => true)
        end
        it { should contain_nova_config('multi_host').with(:value => 'True')}
        it {should contain_class('nova::network').with(
          :create_networks   => true,
          :enabled           => false,
          :install_service   => false
        )}

      end

    end

    describe 'when not enabled' do

      describe 'when multihost is set' do
        let :params do
          default_params.merge(
            :multi_host => true,
            :enabled    => false
          )
        end

        it {should contain_class('nova::network').with(
          :create_networks   => false,
          :enabled           => false,
          :install_service   => false
        )}

      end
      describe 'when multihost is not set' do
        let :params do
          default_params.merge(
            :multi_host => false,
            :enabled    => false
          )
        end

        it {should contain_class('nova::network').with(
          :create_networks   => false,
          :enabled           => false,
          :install_service   => false
        )}

      end

    end

  end

end
