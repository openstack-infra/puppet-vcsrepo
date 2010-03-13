Puppet::Type.type(:vcsrepo).provide(:git) do
  desc "Supports Git repositories"

  commands :git => 'git'

  def create
    if !@resource.value(:source)
      init_repository(@resource.value(:path))
    else
      clone_repository(@resource.value(:source), @resource.value(:path))
      reset(@resource.value(:revision)) if @resource.value(:revision)
    end
  end

  def exists?
    File.directory?(@resource.value(:path))
  end

  def destroy
    FileUtils.rm_rf(@resource.value(:path))
  end
  
  def revision
    current = Dir.chdir(@resource.value(:path)) do
      git('rev-parse', 'HEAD')
    end
    canonical = Dir.chdir(@resource.value(:path)) do
      git('rev-parse', @resource.value(:revision))
    end
    if current == canonical
      @resource.value(:revision)
    else
      current
    end
  end

  def revision=(desired)
    fetch
    reset(desired)
  end

  private

  def clone_repository(source, path)
    git('clone', source, path)
  end

  def fetch
    at_path do
      git('fetch', 'origin')
    end
  end

  def init_repository(path)
    FileUtils.mkdir_p(path)
    at_path do
      git('init')
    end
  end

  def reset(desired)
    at_path do
      git('reset', '--hard', desired)
    end
  end

  def at_path(&block)
    Dir.chdir(@resource.value(:path), &block)
  end

end
