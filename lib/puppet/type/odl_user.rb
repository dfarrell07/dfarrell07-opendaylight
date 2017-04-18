Puppet::Type.newtype(:odl_user) do

  ensurable

  newparam(:username, :namevar => true) do
    desc "Username to configure in ODL IDM with admin role"
    newvalues(/^\w+$/)
  end

  newproperty(:password) do
    desc "Password for this user"
    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Passwords must be a string"
      end
    end

    def change_to_s(current, desire)
      "Password changed"
    end
  end

end
