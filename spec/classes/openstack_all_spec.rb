require 'spec_helper'

describe 'openstack::all' do

  # minimum set of default parameters
  let :default_params do
    {
      :public_address        => '10.0.0.1',
      :public_interface      => 'eth1',
      :private_interface     => 'eth0',
      :admin_email           => 'some_user@some_fake_email_address.foo',
      :mysql_root_password   => 'foo',
      :admin_password        => 'ChangeMe',
      :rabbit_password       => 'rabbit_pw',
      :keystone_db_password  => 'keystone_pass',
      :keystone_admin_token  => 'keystone_admin_token',
      :glance_db_password    => 'glance_pass',
      :glance_user_password  => 'glance_pass',
      :nova_db_password      => 'nova_pass',
      :nova_user_password    => 'nova_pass',
      :secret_key            => 'secret_key',
      :quantum               => false,
    }
  end

  let :facts do
    {
      :operatingsystem        => 'Ubuntu',
      :osfamily               => 'Debian',
      :operatingsystemrelease => '12.04',
      :puppetversion          => '2.7.x',
      :memorysize             => '2GB',
      :processorcount         => '2',
      :concat_basedir         => '/var/lib/puppet/concat',
    }
  end

  let :params do
    default_params
  end

  context 'config cinder' do
    it 'should contain cinder::volume::iscsi' do
      should contain_class('cinder::volume::iscsi').with(
       :iscsi_ip_address => '127.0.0.1',
       :volume_group     => 'cinder-volumes'
     )
    end

    describe 'when params are overridden' do
      let :params do
        default_params.merge!({
          :volume_group => 'foo-volumes'
        })
      end

      it 'should contain cinder::volume::iscsi' do
        should contain_class('cinder::volume::iscsi').with(
          :iscsi_ip_address => '127.0.0.1',
          :volume_group     => 'foo-volumes'
        )
      end
    end
  end

  context 'config for horizon' do

    it 'should contain enabled horizon' do
      should contain_class('horizon').with(
        :secret_key        => 'secret_key',
        :cache_server_ip   => '127.0.0.1',
        :cache_server_port => '11211',
        :swift             => false,
        :quantum           => false,
        :horizon_app_links => false
      )
    end

    describe 'when horizon is disabled' do
      let :params do
        default_params.merge(:horizon => false)
      end
      it { should_not contain_class('horizon') }
    end
  end
end
