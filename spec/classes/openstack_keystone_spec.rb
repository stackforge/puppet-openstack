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
      :neutron_user_password  => 'pass',
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
      [ 'glance', 'cinder', 'neutron' ].each do |type|
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
        :region           => 'RegionOne'
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

  describe 'address specification' do
    let :test_params do
      required_params.merge(
        :swift => true,
        :swift_user_password => 'pass'
      )
    end

    describe 'supplying admin and internal' do
      let :addresses do
        {
          :public_address => '1.1.1.1',
          :admin_address => '2.2.2.2',
          :internal_address => '3.3.3.3'
        }
      end
      let :params do
        test_params.merge(addresses)
      end

      it do
        should contain_class('keystone::endpoint').with(addresses)

        [ 'glance', 'nova', 'swift', 'cinder', 'neutron' ].each do |type|
          should contain_class("#{type}::keystone::auth").with(addresses)
        end
      end
    end

    describe 'supplying admin only, internal defaults' do
      let :addresses do
        {
          :public_address => '1.1.1.1',
          :admin_address => '2.2.2.2'
        }
      end
      let :expected_addresses do
        {
          :public_address => '1.1.1.1',
          :admin_address => '2.2.2.2',
          :internal_address => '1.1.1.1'
        }
      end

      let :params do
        test_params.merge(addresses)
      end

      it do
        should contain_class('keystone::endpoint').with(expected_addresses)

        [ 'glance', 'nova', 'swift', 'cinder', 'neutron' ].each do |type|
          should contain_class("#{type}::keystone::auth").with(expected_addresses)
        end
      end
    end

    describe 'supplying internal only, admin defaults' do
      let :addresses do
        {
          :public_address => '1.1.1.1',
          :internal_address => '3.3.3.3'
        }
      end
      let :expected_addresses do
        {
          :public_address => '1.1.1.1',
          :admin_address => '1.1.1.1',
          :internal_address => '3.3.3.3'
        }
      end

      let :params do
        test_params.merge(addresses)
      end

      it do
        should contain_class('keystone::endpoint').with(expected_addresses)

        [ 'glance', 'nova', 'swift', 'cinder', 'neutron' ].each do |type|
          should contain_class("#{type}::keystone::auth").with(expected_addresses)
        end
      end
    end

    describe 'per service overrides' do
      let :addresses do
        {
          :public_address => '1.1.1.1',
          :admin_address => '2.2.2.2',
          :internal_address => '3.3.3.3',

          :glance_public_address    => '2.1.1.1',
          :glance_admin_address     => '2.1.1.2',
          :glance_internal_address  => '2.1.1.3',
          :nova_public_address      => '2.1.2.1',
          :nova_admin_address       => '2.1.2.2',
          :nova_internal_address    => '2.1.2.3',
          :cinder_public_address    => '2.1.3.1',
          :cinder_admin_address     => '2.1.3.2',
          :cinder_internal_address  => '2.1.3.3',
          :neutron_public_address   => '2.1.4.1',
          :neutron_admin_address    => '2.1.4.2',
          :neutron_internal_address => '2.1.4.3',
          :swift_public_address     => '2.1.5.1',
          :swift_admin_address      => '2.1.5.2',
          :swift_internal_address   => '2.1.5.3'

        }
      end
      let :params do
        test_params.merge(addresses)
      end

      it do
        should contain_class('keystone::endpoint').with(
          :public_address => '1.1.1.1',
          :admin_address => '2.2.2.2',
          :internal_address => '3.3.3.3'
        )

        should contain_class("glance::keystone::auth").with( 
          :public_address    => '2.1.1.1',
          :admin_address     => '2.1.1.2',
          :internal_address  => '2.1.1.3'
        )
        should contain_class("nova::keystone::auth").with( 
          :public_address      => '2.1.2.1',
          :admin_address       => '2.1.2.2',
          :internal_address    => '2.1.2.3'
        )
        should contain_class("cinder::keystone::auth").with( 
          :public_address    => '2.1.3.1',
          :admin_address     => '2.1.3.2',
          :internal_address  => '2.1.3.3'
        )
        should contain_class("neutron::keystone::auth").with( 
          :public_address   => '2.1.4.1',
          :admin_address    => '2.1.4.2',
          :internal_address => '2.1.4.3'
        )
        should contain_class("swift::keystone::auth").with( 
          :public_address     => '2.1.5.1',
          :admin_address      => '2.1.5.2',
          :internal_address   => '2.1.5.3'
        )           
      end
    end

  end
end
