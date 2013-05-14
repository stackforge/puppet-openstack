require 'spec_helper'

describe 'openstack::horizon' do

  let :required_params do
    { :secret_key => 'super_secret' }
  end

  let :params do
    required_params
  end

  let :facts do
    {
      :osfamily       => 'Redhat',
      :memorysize     => '1GB',
      :processorcount => '1',
      :concat_basedir => '/tmp',
      :operatingsystemrelease => '5'
    }
  end

  it 'should configure horizon and memcache using default parameters and secret key' do
    should contain_class('memcached').with(
      :listen_ip => '127.0.0.1',
      :tcp_port  => '11211',
      :udp_port  => '11211'
    )
    should contain_class('horizon').with(
      :cache_server_ip       => '127.0.0.1',
      :cache_server_port     => '11211',
      :secret_key            => 'super_secret',
      :horizon_app_links     => false,
      :keystone_host         => '127.0.0.1',
      :keystone_scheme       => 'http',
      :keystone_default_role => 'Member',
      :django_debug          => 'False',
      :api_result_limit      => 1000
    )
  end

end
