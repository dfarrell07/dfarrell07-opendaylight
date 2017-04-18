require 'puppet'
require 'puppet/type/odl_user'
require 'spec_helper'

describe 'Puppet::Type.type(:odl_user)' do

  it 'should accept username/password' do
    Puppet::Type.type(:odl_user).new(:username => 'admin', :password => 'admin')
  end

end
