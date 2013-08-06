require 'spec_helper'

describe 'openstack::auth_file' do

  describe "when only passing default class parameters" do

    let :params do
      { :admin_password => 'admin' }
    end

    it 'should create a openrc file' do
      verify_contents(subject, '/root/openrc', [
        'export OS_NO_CACHE=true',
        'export OS_TENANT_NAME=admin',
        'export OS_USERNAME=admin',
        'export OS_PASSWORD=admin',
        'export OS_AUTH_URL=http://127.0.0.1:5000/v2.0/',
        'export OS_AUTH_STRATEGY=keystone',
        'export OS_REGION_NAME=RegionOne',
        'export CEILOMETER_ENDPOINT_TYPE=publicURL',
        'export CINDER_ENDPOINT_TYPE=publicURL',
        'export GLANCE_ENDPOINT_TYPE=publicURL',
        'export HEAT_ENDPOINT_TYPE=publicURL',
        'export KEYSTONE_ENDPOINT_TYPE=publicURL',
        'export NOVA_ENDPOINT_TYPE=publicURL',
        'export QUANTUM_ENDPOINT_TYPE=publicURL'
      ])
    end
  end

  describe 'when overridding parameters' do

    let :params do
      {
        :controller_node          => '127.0.0.2',
        :keystone_admin_token     => 'keystone',
        :ceilometer_endpoint_type => 'privateURL',
        :cinder_endpoint_type     => 'privateURL',
        :glance_endpoint_type     => 'privateURL',
        :heat_endpoint_type       => 'privateURL',
        :keystone_endpoint_type   => 'privateURL',
        :nova_endpoint_type       => 'privateURL',
        :quantum_endpoint_type    => 'privateURL',
      }
    end

    it 'should create a openrc file' do
      verify_contents(subject, '/root/openrc', [
        'export OS_SERVICE_TOKEN=keystone',
        'export OS_SERVICE_ENDPOINT=http://127.0.0.2:35357/v2.0/',
        'export CEILOMETER_ENDPOINT_TYPE=privateURL',
        'export CINDER_ENDPOINT_TYPE=privateURL',
        'export GLANCE_ENDPOINT_TYPE=privateURL',
        'export HEAT_ENDPOINT_TYPE=privateURL',
        'export KEYSTONE_ENDPOINT_TYPE=privateURL',
        'export NOVA_ENDPOINT_TYPE=privateURL',
        'export QUANTUM_ENDPOINT_TYPE=privateURL'
      ])
    end
  end
end
