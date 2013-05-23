require 'spec_helper'

describe 'openstack::nova::controller' do

  let :params do
    {
      :public_address         => '127.0.0.1',
      :db_host                => '127.0.0.1',
      :rabbit_password        => 'rabbit_pass',
      :nova_user_password     => 'nova_user_pass',
      :quantum_user_password  => 'quantum_user_pass',
      :nova_db_password       => 'nova_db_pass',
      :quantum                => true,
      :metadata_shared_secret => 'secret'
    }
  end

  let :facts do
    {:osfamily => 'Debian' }
  end

  it { should contain_class('openstack::nova::controller') }

  context 'when configuring quantum' do

    it 'should configure nova with quantum' do

      should contain_class('nova::rabbitmq').with(
        :userid        => 'openstack',
        :password      => 'rabbit_pass',
        :enabled       => true,
        :virtual_host  => '/'
      )
      should contain_class('nova').with(
        :sql_connection       => 'mysql://nova:nova_db_pass@127.0.0.1/nova',
        :rabbit_userid        => 'openstack',
        :rabbit_password      => 'rabbit_pass',
        :rabbit_virtual_host  => '/',
        :image_service        => 'nova.image.glance.GlanceImageService',
        :glance_api_servers   => '127.0.0.1:9292',
        :verbose              => false,
        :rabbit_host          => '127.0.0.1'
      )

      should contain_class('nova::api').with(
        :enabled                              => true,
        :admin_tenant_name                    => 'services',
        :admin_user                           => 'nova',
        :admin_password                       => 'nova_user_pass',
        :enabled_apis                         => 'ec2,osapi_compute,metadata',
        :auth_host                            => '127.0.0.1',
        :quantum_metadata_proxy_shared_secret => 'secret'
      )

      should contain_class('nova::network::quantum').with(
        :quantum_admin_password    => 'quantum_user_pass',
        :quantum_auth_strategy     => 'keystone',
        :quantum_url               => "http://127.0.0.1:9696",
        :quantum_admin_tenant_name => 'services',
        :quantum_admin_username    => 'quantum',
        :quantum_admin_auth_url    => "http://127.0.0.1:35357/v2.0"
      )

      ['nova::scheduler', 'nova::objectstore', 'nova::cert', 'nova::consoleauth', 'nova::conductor'].each do |x|
        should contain_class(x).with_enabled(true)
      end

      should contain_class('nova::vncproxy').with(
        :host    => '127.0.0.1',
        :enabled => true
      )


    end
  end

end
