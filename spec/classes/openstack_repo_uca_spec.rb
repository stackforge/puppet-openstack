require 'spec_helper'

describe 'openstack::repo::uca' do

  let :facts do
    {
      :osfamily               => 'Debian',
      :operatingsystem        => 'Ubuntu',
      :operatingsystemrelease => '12.04',
      :lsbdistdescription     => 'Ubuntu 12.04.1 LTS',
      :lsbdistcodename        => 'precise',
      :lsbdistid              => 'ubuntu',
    }
  end

  describe 'Ubuntu with defaults' do
    context "with_package_ordering default" do
      it do
        should contain_apt__source('ubuntu-cloud-archive').with(
          :release => 'precise-updates/havana'
        )
      end
    end

    context "with_package_ordering = true" do
      let :params do
        { :enforce_package_ordering => true }
      end

      it do
        should contain_apt__source('ubuntu-cloud-archive').with(
          :release => 'precise-updates/havana'
        )
      end
    end

    context "with_package_ordering = false" do
      let :params do
        { :enforce_package_ordering => false }
      end

      it do
        should contain_apt__source('ubuntu-cloud-archive').with(
          :release => 'precise-updates/havana'
        )
      end
    end
  end

  describe 'Ubuntu and grizzly' do
    let :params do
      { :release => 'havana', :repo => 'proposed' }
    end

    it do
      should contain_apt__source('ubuntu-cloud-archive').with(
        :release => 'precise-proposed/havana'
      )
    end
  end

  describe 'Ubuntu and folsom' do
    let :params do
      { :release => 'folsom', :repo => 'proposed' }
    end

    it do
      should contain_apt__source('ubuntu-cloud-archive').with(
        :release => 'precise-proposed/folsom'
      )
    end
  end

end
