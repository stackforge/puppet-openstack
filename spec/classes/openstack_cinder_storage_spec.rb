require 'spec_helper'

describe 'openstack::cinder::storage' do


  let :required_params do
    {
      :sql_connection  => 'mysql://a:b:c:d',
      :rabbit_password => 'rabpass'
    }
  end

  let :params do
    required_params
  end

  let :facts do
    { :osfamily => 'Redhat' }
  end

  it 'should configure cinder and cinder::volume using defaults and required parameters' do
    should contain_class('cinder').with(
      :sql_connection      => required_params[:sql_connection],
      :rabbit_userid       => 'guest',
      :rabbit_password     => required_params[:rabbit_password],
      :rabbit_host         => '127.0.0.1',
      :rabbit_port         => '5672',
      :rabbit_hosts        => nil,
      :rabbit_virtual_host => '/',
      :package_ensure      => 'present',
      :api_paste_config    => '/etc/cinder/api-paste.ini',
      :verbose             => false
    )
    should contain_class('cinder::volume').with(
      :package_ensure => 'present',
      :enabled        => true
    )
    should contain_class('cinder::volume::iscsi').with(
      :iscsi_ip_address => '127.0.0.1',
      :volume_group     => 'cinder-volumes'
    )
    should_not contain_class('cinder::setup_test_volume')
  end

  describe 'with a volume driver other than iscsi' do
    let :params do
      required_params.merge(
        :volume_driver => 'netapp'
      )
    end
    it { should_not contain_class('cinder::volume::iscsi') }
  end

  describe 'when setting up test volumes for iscsi' do
    let :params do
      required_params.merge(
        :setup_test_volume => 'setup_test_volume'
      )
    end
    it { should contain_class('cinder::setup_test_volume') }
  end

end
