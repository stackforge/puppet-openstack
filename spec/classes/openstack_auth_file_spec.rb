require 'spec_helper'

describe 'openstack::auth_file' do

  let :default_params do
    {
      :admin_password        => 'admin',
      :controller_node       => '127.0.0.1',
      :keystone_admin_token  => 'keystone_admin_token',
      :admin_user            => 'admin',
      :admin_tenant          => 'admin',
      :use_no_cache          => 'true',
    }
  end


  describe "when using default class parameters" do
    let :params do
      default_params
    end
    it {
      should contain_class('openstack::auth_file').with({
        :admin_password        => 'admin',
        :controller_node       => '127.0.0.1',
        :keystone_admin_token  => 'keystone_admin_token',
        :admin_user            => 'admin',
        :admin_tenant          => 'admin',
        :use_no_cache          => 'true'
      })
    contain_file('/root/openrc').with_content(
        '
        export OS_NO_CACHE=true
        export OS_TENANT_NAME=admin
        export OS_USERNAME=admin
        export OS_PASSWORD=admin
        export OS_AUTH_URL="http://127.0.0.1:5000/v2.0/"
        export OS_AUTH_STRATEGY=keystone
        export SERVICE_TOKEN=keystone_admin_token
        export SERVICE_ENDPOINT=http://127.0.0.1:35357/v2.0/
        '
    )}
  end

  describe 'when overridding' do

    let :params do
        default_params.merge({
          :admin_password        => 'nova',
          :controller_node       => '127.0.0.2',
          :keystone_admin_token  => 'keystone',
          :admin_user            => 'nova',
          :admin_tenant          => 'nova',
          :use_no_cache          => 'false',
        })
    end

    it {
      should contain_class('openstack::auth_file').with({
        :admin_password        => 'nova',
        :controller_node       => '127.0.0.2',
        :keystone_admin_token  => 'keystone',
        :admin_user            => 'nova',
        :admin_tenant          => 'nova',
        :use_no_cache          => 'false'
      })
    contain_file('/root/openrc').with_content(
        '
        export OS_NO_CACHE=false
        export OS_TENANT_NAME=nova
        export OS_USERNAME=nova
        export OS_PASSWORD=nova
        export OS_AUTH_URL="http://127.0.0.2:5000/v2.0/"
        export OS_AUTH_STRATEGY=keystone
        export SERVICE_TOKEN=keystone
        export SERVICE_ENDPOINT=http://127.0.0.2:35357/v2.0/
        '
    )}
  end
end
