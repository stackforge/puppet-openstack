require 'spec_helper'

describe 'openstack::nova::controller' do

  let :params do
    {
      :public_address        => '127.0.0.1',
      :db_host               => '127.0.0.1',
      :rabbit_password       => 'rabbit_pass',
      :nova_user_password    => 'nova_user_pass',
      :quantum_user_password => 'quantum_user_pass',
      :nova_db_password      => 'nova_db_pass',
      :quantum               => true
    }
  end

  let :facts do
    {:osfamily => 'Debian' }
  end

  it { should contain_class('openstack::nova::controller') }

  context 'when configuring quantum' do
    it { should contain_class('nova::network::quantum').with(
      :quantum_admin_password    => 'quantum_user_pass',
      :quantum_auth_strategy     => 'keystone',
      :quantum_url               => "http://127.0.0.1:9696",
      :quantum_admin_tenant_name => 'services',
      :quantum_admin_username    => 'quantum',
      :quantum_admin_auth_url    => "http://127.0.0.1:35357/v2.0"
    )}
  end

end
