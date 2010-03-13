require 'pathname'

Puppet::Type.newtype(:vcsrepo) do
  desc "A local version control repository"

  ensurable do
    defaultvalues

    newvalue :bare do
      provider.create
    end

    def retrieve
      prov = @resource.provider
      if prov
        if prov.respond_to?(:bare_exists?)
          if prov.respond_to?(:working_copy_exists?) && prov.working_copy_exists?
            :present
          elsif prov.respond_to?(:bare_exists?) && prov.bare_exists?
            :bare
          else
            :absent
          end
        else
          if prov.exists?
            :present
          else
            :absent
          end
        end
      else
        :absent
      end
    end

  end

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
    desc "The source URI for the repository"
  end

  newparam(:fstype) do
    desc "Filesystem type (for providers that support it, eg subversion)"
  end

  newproperty(:revision) do
    desc "The revision of the repository"
    newvalue(/^\S+$/)
  end

  newparam :compression do
    desc "Compression level (used by CVS)"
    validate do |amount|
      unless Integer(amount).between?(0, 6)
        raise ArgumentError, "Unsupported compression level: #{amount} (expected 0-6)"
      end
    end
  end

end
