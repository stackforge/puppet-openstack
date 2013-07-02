require 'spec_helper'

describe 'openstack::keystone' do

  # set the parameters that absolutely must be set for the class to even compile
  let :required_params do
    {
      :admin_token            => 'token',
      :db_password            => 'pass',
      :admin_password         => 'pass',
      :glance_user_password   => 'pass',
      :nova_user_password     => 'pass',
      :cinder_user_password   => 'pass',
      :quantum_user_password  => 'pass',
      :public_address         => '127.0.0.1',
      :db_host                => '127.0.0.1',
      :admin_email            => 'root@localhost'
    }
  end

  # set the class parameters to only be those that are required
  let :params do
    required_params
  end

  let :facts do
    { :osfamily => 'Debian', :operatingsystem => 'Ubuntu' }
  end

  describe 'with only required params (and defaults for everything else)' do

    it 'should configure keystone and all default endpoints' do
      should contain_class('keystone').with(
        :verbose        => false,
        :debug          => false,
        :bind_host      => '0.0.0.0',
        :idle_timeout   => '200',
        :catalog_type   => 'sql',
        :admin_token    => 'token',
        :enabled        => true,
        :sql_connection => 'mysql://keystone:pass@127.0.0.1/keystone'
      )
      [ 'glance', 'cinder', 'quantum' ].each do |type|
        should contain_class("#{type}::keystone::auth").with(
          :password         => params["#{type}_user_password".intern],
          :public_address   => params[:public_address],
          :admin_address    => params[:public_address],
          :internal_address => params[:public_address],
          :region           => 'RegionOne'
        )
      end
      should contain_class('nova::keystone::auth').with(
        :password         => params[:nova_user_password],
        :public_address   => params[:public_address],
        :admin_address    => params[:public_address],
        :internal_address => params[:public_address],
        :region           => 'RegionOne',
        :cinder           => true
      )
    end
  end

  describe 'without nova' do

    let :params do
      required_params.merge(:nova => false)
    end

    it { should_not contain_class('nova::keystone::auth') }

  end

  describe 'without swift' do
    it { should_not contain_class('swift::keystone::auth') }
  end

  describe 'swift' do
    describe 'without password' do
      let :params do
        required_params.merge(:swift => true)
      end
      it 'should fail when the password is not set' do
        expect do
          subject
        end.to raise_error(Puppet::Error)
      end
    end
    describe 'with password' do
      let :params do
        required_params.merge(:swift => true, :swift_user_password => 'dude')
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
