require 'puppet'
require 'puppet/provider/odl_user/idm'
require 'spec_helper'

provider_class = Puppet::Type.type(:odl_user).provider(:idm)

describe 'Puppet::Type.type(:odl_user).provider(:idm)' do

  let :odl_attrs do
    {
      :username => 'admin',
      :ensure   => 'present',
    }
  end

  let :resource do
    Puppet::Type::Odl_user.new(odl_attrs)
  end

  let :provider do
    provider_class.new(resource)
  end

  describe 'on create' do
    it 'should call idm to create user' do
      provider.expects(:idm_cmd)
      provider.create
    end
  end

  describe "when changing password" do
    it 'should change password' do
      provider.expects(:destroy)
      provider.expects(:idm_cmd)
      provider.password = 'admin'
    end
  end
end
