require 'spec_helper'

describe 'openstack::client' do

  let :facts do
    { :osfamily => 'Debian', :operatingsystem => 'Ubuntu' }
  end

  # Ceilometer not included in fixtures yet.
  it { should_not include_class('ceilometer::client') }
  it { should include_class('cinder::client') }
  it { should include_class('glance::client') }
  it { should include_class('keystone::client') }
  it { should include_class('nova::client') }
  it { should include_class('quantum::client') }

  describe 'without cinder' do
    let (:params) { {:cinder => false }}
    it { should_not include_class('cinder::client') }
  end

  describe 'without glance' do
    let (:params) { {:glance => false }}
    it { should_not include_class('glance::client') }
  end

  describe 'without keystone' do
    let (:params) { {:keystone => false }}
    it { should_not include_class('keystone::client') }
  end

  describe 'without nova' do
    let (:params) { {:nova => false }}
    it { should_not include_class('nova::client') }
  end

  describe 'without quantum' do
    let (:params) { {:quantum => false }}
    it { should_not include_class('quantum::client') }
  end
end
