Puppet::Type.type(:vcsrepo).provide(:svn) do
  desc "Supports Subversion repositories"

  commands :svn      => 'svn',
           :svnadmin => 'svnadmin'

  def create
    if !@resource.value(:source)
      create_repository(@resource.value(:path))
    else
      checkout_repository(@resource.value(:source),
                          @resource.value(:path),
                          @resource.value(:revision))
    end
  end

  def exists?
    File.directory?(@resource.value(:path))
  end

  def destroy
    FileUtils.rm_rf(@resource.value(:path))
  end
  
  def revision
    at_path do
      svn('info')[/^Revision:\s+(\d+)/m, 1]
    end
  end

  def revision=(desired)
    at_path do
      svn('update', '-r', desired)
    end
  end

  private

  def checkout_repository(source, path, revision = nil)
    args = ['checkout']
    if revision
      args.push('-r', revision)
    end
    args.push(source, path)
    svn(*args)
  end

  def create_repository(path)
    args = ['create']
    if @resource.value(:fstype)
      args.push('--fs-type', @resource.value(:fstype))
    end
    args << path
    svnadmin(*args)
  end

  def reset(desired)
    at_path do
      git('reset', '--hard', desired)
    end
  end

  # Note: We don't rely on Dir.chdir's behavior of automatically returning the
  # value of the last statement -- for easier stubbing.
  def at_path(&block) #:nodoc:
    value = nil
    Dir.chdir(@resource.value(:path)) do
      value = yield
    end
    value
  end

end
