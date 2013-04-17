require 'spec_helper'

describe 'openstack::auth_file' do

  let :default_params do
    {
      :admin_password        => 'admin',
      :controller_node       => '127.0.0.1',
      :keystone_admin_token  => 'keystone_admin_token',
      :admin_user            => 'admin',
      :admin_tenant          => 'admin',
      :disable_keyring       => '1',
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
        :disable_keyring       => '1'
      })
    }
    end

  describe 'the openrc file' do
    let :params do
      default_params
    end
  it do
    should contain_file('/root/openrc')
    end
  end
end
