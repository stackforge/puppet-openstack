require 'spec_helper'

describe 'openstack::cinder::storage' do

  let :params do
    {
      :db_password     => 'db_password',
      :rabbit_password => 'rabpass'
    }
  end

  let :facts do
    { :osfamily => 'Redhat' }
  end

  it 'should configure cinder and cinder::volume using defaults and required parameters' do
    should contain_class('cinder').with(
      :sql_connection      => "mysql://cinder:#{params[:db_password]}@127.0.0.1/cinder?charset=utf8",
      :rabbit_userid       => 'guest',
      :rabbit_password     => params[:rabbit_password],
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
    before do
      params.merge!(
        :volume_driver => 'netapp'
      )
    end
    it { should_not contain_class('cinder::volume::iscsi') }
  end

  describe 'when setting up test volumes for iscsi' do
    before do
      params.merge!(
        :setup_test_volume => true
      )
    end
    it { should contain_class('cinder::setup_test_volume').with(
      :volume_name => 'cinder-volumes'
    )}
    describe 'when volume_group is set' do
      before do
        params.merge!(:volume_group => 'foo')
      end
      it { should contain_class('cinder::setup_test_volume').with(
        :volume_name => 'foo'
      )}
    end
  end

end
