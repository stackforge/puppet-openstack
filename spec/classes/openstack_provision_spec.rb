require 'spec_helper'

describe 'openstack::provision' do

  let :facts do
    {
    :osfamily => 'Debian'
    }
  end

  describe 'should be possible to override resize_available' do
    let :params do
      {
        :configure_tempest         => true,
        :resize_available          => true,
        :change_password_available => true,
        :tempest_repo_revision     => 'stable/grizzly'
      }
    end

    it { should contain_class('tempest').with(
      :resize_available          => true,
      :change_password_available => true,
      :tempest_repo_revision     => 'stable/grizzly'
    ) }

  end

end
