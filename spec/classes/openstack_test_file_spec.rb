require 'spec_helper'

describe 'openstack::test_file' do
  it do
    should contain_file('/tmp/test_nova.sh').with_mode('0751')
  end
end
