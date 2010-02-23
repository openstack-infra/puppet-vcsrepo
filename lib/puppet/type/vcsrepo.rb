require 'pathname'

Puppet::Type.newtype(:vcsrepo) do
  desc "A local version control repository"

  ensurable

  newparam(:path) do
    desc "Absolute path to repository"
    isnamevar
    validate do |value|
      path = Pathname.new(value)
      unless path.absolute?
        raise ArgumentError, "Path must be absolute: #{path}"
      end
    end
  end

  newparam(:source) do
    desc "The source URL for the repository"
    validate do |value|
      URI.parse(value)
    end
  end

  newproperty(:revision) do
    desc "The revision of the repository"
    newvalue(/^\S+$/)
  end

end
