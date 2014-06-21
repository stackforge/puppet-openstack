require 'spec_helper'

describe 'openstack::test_file' do
  it do
    is_expected.to contain_file('/tmp/test_nova.sh').with_mode('0751')
    is_expected.to_not contain_file('/tmp/test_nova.sh').with_content(/add-floating-ip/)
    is_expected.to contain_file('/tmp/test_nova.sh').with_content(/floatingip-create/)
  end
end
