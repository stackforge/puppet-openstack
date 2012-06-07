require 'spec_helper'

describe 'openstack::compute' do

  let :default_params do
    {
      :private_interface => 'eth0',
      :internal_address  => '0.0.0.0',
    }
  end

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
    }
  end
  describe "when using default class paramaters" do
    let :params do
      default_params
    end
    it {
      should contain_nova_config('multi_host').with({ 'value' => 'False' })
      should_not contain_class('nova::api')
      should_not contain_class('nova::volume')
      should_not contain_class('nova::volume::iscsi')
      should contain_class('nova::network').with({
        'enabled' => false,
        'install_service' => false
      })
    }
  end

  describe "when enabling volume management" do
    let :params do
      default_params.merge({
        :manage_volumes => true
      })
    end

    it {
      should contain_nova_config('multi_host').with({ 'value' => 'False'})
      should_not contain_class('nova::api')
      should contain_class('nova::volume')
      should contain_class('nova::volume::iscsi')
      should contain_class('nova::network').with({
        'enabled' => false,
        'install_service' => false
      })
    }
  end

  describe "when configuring for multi host" do
    let :params do
      default_params.merge({
        :multi_host       => true,
        :public_interface => 'eth0'
      })
    end

    it {
      should contain_nova_config('multi_host').with({ 'value' => 'True'})
      should contain_class('nova::api')
      should_not contain_class('nova::volume')
      should_not contain_class('nova::volume::iscsi')
      should contain_class('nova::network').with({
        'enabled' => true,
        'install_service' => true
      })
    }
  end

  describe "when configuring for multi host without a public interface" do
    let :params do
      default_params.merge({
        :multi_host => true
      })
    end

    it {
      expect { should raise_error(Puppet::Error) }
    }
  end

  describe "when enabling volume management and using multi host" do
    let :params do
      default_params.merge({
        :multi_host       => true,
        :public_interface => 'eth0',
        :manage_volumes   => true,
      })
    end

    it {
      should contain_nova_config('multi_host').with({ 'value' => 'True'})
      should contain_class('nova::api')
      should contain_class('nova::volume')
      should contain_class('nova::volume::iscsi')
      should contain_class('nova::network').with({
        'enabled' => true,
        'install_service' => true
      })
    }
  end
end
