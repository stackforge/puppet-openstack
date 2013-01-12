require 'spec_helper'

describe 'openstack::keystone' do
  # minimum set of default parameters
  let :default_params do
    {
      :db_host                => '127.0.0.1',
      :db_password            => 'pass',
      :admin_token            => 'token',
      :admin_email            => 'email@address.com',
      :admin_password         => 'pass',
      :glance_user_password   => 'pass',
      :nova_user_password     => 'pass',
      :cinder_user_password   => 'pass',
      :quantum_user_password  => 'pass',
      :swift_user_password    => false,
      :public_address         => '127.0.0.1',
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
    }
  end

  let :params do
    default_params
  end

  describe 'without swift' do
    it { should_not contain_class('swift::keystone::auth') }
  end

  describe 'swift' do
    describe 'without password' do
      let :params do
        default_params.merge(:swift => true)
      end
      it 'should fail when the password is not set' do
        expect do
          subject
        end.to raise_error(Puppet::Error)
      end
    end
    describe 'with password' do
      let :params do
        default_params.merge(:swift => true, :swift_user_password => 'dude')
      end
      it do
        should contain_class('swift::keystone::auth').with(
          :password => 'dude',
          :address  => '127.0.0.1',
          :region   => 'RegionOne'
        )
      end
    end
  end

end
