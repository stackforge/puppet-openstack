require 'spec_helper'

describe 'openstack::glance' do

  let :required_params do
    {
      :db_host        => '127.0.0.1',
      :user_password  => 'glance_user_pass',
      :db_password    => 'glance_db_pass',
      :keystone_host  => '127.0.1.1'
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian'
    }
  end

  let :params do
    required_params
  end

  describe 'with only required parameters' do
    it 'should configure with applicable defaults' do
      should contain_class('glance::api').with(
        :verbose           => 'False',
        :debug             => 'False',
        :auth_type         => 'keystone',
        :auth_port         => '35357',
        :auth_host         => '127.0.1.1',
        :keystone_tenant   => 'services',
        :keystone_user     => 'glance',
        :keystone_password => 'glance_user_pass',
        :sql_connection    => 'mysql://glance:glance_db_pass@127.0.0.1/glance',
        :enabled           => true
      )
      should contain_class('glance::registry').with(
        :verbose           => 'False',
        :debug             => 'False',
        :auth_host         => '127.0.1.1',
        :auth_port         => '35357',
        :auth_type         => 'keystone',
        :keystone_tenant   => 'services',
        :keystone_user     => 'glance',
        :keystone_password => 'glance_user_pass',
        :sql_connection    => 'mysql://glance:glance_db_pass@127.0.0.1/glance',
        :enabled           => true
      )
      should contain_class('glance::backend::file')
    end
  end

  describe 'when configuring swift as the backend' do

    let :params do
      required_params.merge({
        :backend => 'swift',
        :swift_store_user => 'dan',
        :swift_store_key  => '123'
      })
    end

    it 'should configure swift as the backend' do
      should_not contain_class('glance::backend::file')

      should contain_class('glance::backend::swift').with(
        :swift_store_user                    => 'dan',
        :swift_store_key                     => '123',
        :swift_store_auth_address            => 'http://127.0.0.1:5000/v2.0/',
        :swift_store_create_container_on_put => 'true'
      )
    end

  end

end
