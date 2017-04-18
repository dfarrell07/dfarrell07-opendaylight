Puppet::Type.type(:odl_user).provide(:idm) do

  commands :java => 'java'

  def odl_path
    '/opt/opendaylight'
  end

  def idm_cmd(*args)
    java('-jar', "#{odl_path}/bin/aaa-cli-jar.jar", '--dbd', odl_path, *args)
  end

  def create
    idm_cmd('--newUser', @resource[:username], '-p', @resource[:password])
  end

  def destroy
    idm_cmd('--deleteUser', @resource[:username])
  end

  def exists?
    output = idm_cmd('-l').split("\n")
    output.each do |line|
      if line.eql? @resource[:username]
        return true
      end
    end
    return false
  end

  def password
    return false
  end

  def password=(password)
    destroy
    idm_cmd('--newUser', @resource[:username], '-p', password)
  end

end
