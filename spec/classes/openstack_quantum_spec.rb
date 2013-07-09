require 'spec_helper'

describe 'openstack::quantum' do

  let :facts do
    {:osfamily => 'Redhat'}
  end

  let :params do
    {
      :user_password   => 'q_user_pass',
      :rabbit_password => 'rabbit_pass',
      :db_password     => 'bar'
    }
  end

  context 'install quantum with default settings' do
    before do
      params.delete(:db_password)
    end
    it 'should fail b/c database password is required' do
      expect do
        subject
      end.to raise_error(Puppet::Error, /db password must be set/)
    end
  end
  context 'install quantum with default and database password' do
    it 'should perform default configuration' do
      should contain_class('quantum').with(
        :enabled             => true,
        :bind_host           => '0.0.0.0',
        :rabbit_host         => '127.0.0.1',
        :rabbit_hosts        => false,
        :rabbit_virtual_host => '/',
        :rabbit_user         => 'rabbit_user',
        :rabbit_password     => 'rabbit_pass',
        :verbose             => false,
        :debug               => false
      )
      should contain_class('quantum::server').with(
        :auth_host     => '127.0.0.1',
        :auth_password => 'q_user_pass'
      )
      should contain_class('quantum::plugins::ovs').with(
        :sql_connection      => "mysql://quantum:bar@127.0.0.1/quantum?charset=utf8",
        :tenant_network_type => 'gre'
      )
    end
  end

  context 'when server is disabled' do
    before do
      params.merge!(:enable_server => false)
    end
    it 'should not configure server' do
      should_not contain_class('quantum::server')
      should_not contain_class('quantum::plugins::ovs')
    end
  end

  context 'when ovs agent is enabled with all required params' do
    before do
      params.merge!(
        :enable_ovs_agent => true,
        :bridge_uplinks   => ['br-ex:eth0'],
        :bridge_mappings  => ['default:br-ex'],
        :ovs_local_ip     => '10.0.0.2'
      )
    end
    it { should contain_class('quantum::agents::ovs').with(
      :bridge_uplinks   => ['br-ex:eth0'],
      :bridge_mappings  => ['default:br-ex'],
      :enable_tunneling => true,
      :local_ip         => '10.0.0.2',
      :firewall_driver  => 'quantum.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver'
    )}

    context 'without ovs_local_ip' do
      before do
        params.delete(:ovs_local_ip)
      end
      it 'should fail' do
        expect do
          subject
        end.to raise_error(Puppet::Error, /ovs_local_ip parameter must be set/)
      end
    end

  end

  context 'when dhcp agent is enabled' do
    before do
      params.merge!(:enable_dhcp_agent => true)
    end
    it { should contain_class('quantum::agents::dhcp').with(
      :use_namespaces => true
    ) }
  end

  context 'when l3 agent is enabled' do
    before do
      params.merge!(:enable_l3_agent => true)
    end
    it { should contain_class('quantum::agents::l3').with(
      :use_namespaces => true
    ) }
  end

  context 'when metadata agent is enabled' do
    before do
      params.merge!(
        :enable_metadata_agent => true
      )
    end
    it 'should fail' do
      expect do
        subject
      end.to raise_error(Puppet::Error, /metadata_shared_secret parameter must be set/)
    end
    context 'with a shared secret' do
      before do
        params.merge!(
          :shared_secret => 'foo'
        )
      end
      it { should contain_class('quantum::agents::metadata').with(
        :auth_password  => 'q_user_pass',
        :shared_secret  => 'foo',
        :auth_url       => 'http://localhost:35357/v2.0',
        :metadata_ip    => '127.0.0.1'
      ) }
    end
  end

  context 'with invalid db_type' do
    before do
      params.merge!(:db_type => 'foo', :db_password => 'bar')
    end
    it 'should fail' do
      expect do
        subject
      end.to raise_error(Puppet::Error, /Unsupported db type: foo./)
    end
  end

end
