require 'spec_helper'

describe 'openstack::auth_file' do

  describe "when only passing required class parameters" do

    let :params do
      { :admin_password => 'admin' }
    end

    it 'should create a openrc file' do
      should contain_file('/root/openrc').with_content(
  '
  export OS_NO_CACHE=true
  export OS_TENANT_NAME=admin
  export OS_USERNAME=admin
  export OS_PASSWORD=\'admin\'
  export OS_AUTH_URL="http://127.0.0.1:5000/v2.0/"
  export OS_AUTH_STRATEGY=keystone
  export SERVICE_TOKEN=keystone_admin_token
  export SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0/
  '
        )
    end
  end

  describe 'when overridding' do

      let :params do
        {
          :admin_password        => 'nova',
          :controller_node       => '127.0.0.2',
          :keystone_admin_token  => 'keystone',
          :admin_user            => 'nova',
          :admin_tenant          => 'nova',
          :use_no_cache          => false,
        }
      end

      it 'should create a openrc file' do
        should contain_file('/root/openrc').with_content(
  '
  export OS_NO_CACHE=false
  export OS_TENANT_NAME=nova
  export OS_USERNAME=nova
  export OS_PASSWORD=\'nova\'
  export OS_AUTH_URL="http://127.0.0.2:5000/v2.0/"
  export OS_AUTH_STRATEGY=keystone
  export SERVICE_TOKEN=keystone
  export SERVICE_ENDPOINT=http://127.0.0.2:35357/v2.0/
  '
        )
      end
  end
end
