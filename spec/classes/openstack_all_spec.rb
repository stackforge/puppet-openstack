require 'spec_helper'

describe 'openstack::all' do

  # minimum set of default parameters
  let :params do
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
      :quantum               => false
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
      :concat_basedir         => '/var/lib/puppet/concat'
    }
  end

  context 'with required parameters' do

    it 'configures horizon' do
      should contain_class('horizon').with(
        :secret_key        => 'secret_key',
        :cache_server_ip   => '127.0.0.1',
        :cache_server_port => '11211',
        :horizon_app_links => false
      )
    end

    context 'when disabling horizon' do
      before do
        params.merge!(:horizon => false)
      end
      it { should_not contain_class('horizon') }
    end

    context 'with cinder' do
      before do
        params.merge!(
          :cinder               => true,
          :cinder_user_password => 'cinder_ks_passw0rd',
          :cinder_db_password   => 'cinder_db_passw0rd'
        )
      end

      it 'configures cinder' do
        should contain_class('cinder::base').with(
          :verbose         => 'False',
          :sql_connection  => "mysql://cinder:cinder_db_passw0rd@127.0.0.1/cinder?charset=utf8",
          :rabbit_password => 'rabbit_pw'
        )
        should contain_class('cinder::api').with(
          :keystone_password => 'cinder_ks_passw0rd'
        )
        should contain_class('cinder::scheduler')
        should contain_class('cinder::volume')
        should contain_class('cinder::volume::iscsi').with(
          :iscsi_ip_address => '127.0.0.1',
          :volume_group     => 'cinder-volumes'
        )
      end
    end
  end

  context 'when auto assign floating ip is assigned' do
    before do
      params.merge!(:auto_assign_floating_ip => 'true')
    end
    it { should contain_nova_config('DEFAULT/auto_assign_floating_ip').with(:value => 'True')}
  end

  context 'nova' do
    it { should_not contain_resources('nova_config').with_purge(true) }
  end
end
