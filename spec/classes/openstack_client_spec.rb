require 'spec_helper'

describe 'openstack::client' do

  let :default_params do
    {
      :ceilometer => false,
      :cinder     => true,
      :glance     => true,
      :keystone   => true,
      :nova       => true,
      :quantum    => true
    }
  end

  let :facts do
    { :osfamily => 'Debian', :operatingsystem => 'Ubuntu' }
  end

  let :params do
    default_params
  end

  it { should_not include_class('ceilometer::client') }
  it { should include_class('cinder::client') }
  it { should include_class('glance::client') }
  it { should include_class('keystone::client') }
  it { should include_class('nova::client') }
  it { should include_class('quantum::client') }

  describe 'without cinder' do
    let :params do
      default_params.merge(:cinder => false)
    end
    it { should_not include_class('cinder::client') }
  end

  describe 'without glance' do
    let :params do
      default_params.merge(:glance => false)
    end
    it { should_not include_class('glance::client') }
  end

  describe 'without keystone' do
    let :params do
      default_params.merge(:keystone => false)
    end
    it { should_not include_class('keystone::client') }
  end

  describe 'without nova' do
    let :params do
      default_params.merge(:nova => false)
    end
    it { should_not include_class('nova::client') }
  end

  describe 'without quantum' do
    let :params do
      default_params.merge(:quantum => false)
    end
    it { should_not include_class('quantum::client') }
  end
end
