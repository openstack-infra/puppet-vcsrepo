require 'tmpdir'
require 'digest/md5'

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
    case @resource.value(:ensure)
    when 'present'
      working_copy_exists?
    when 'bare'
      bare_exists?
    else
      path_exists?
    end
  end

  def destroy
    FileUtils.rm_rf(@resource.value(:path))
  end
  
  def revision
    current   = at_path { git('rev-parse', 'HEAD') }
    canonical = at_path { git('rev-parse', @resource.value(:revision)) }
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

  def bare_exists?
    bare_git_config_exists? && !working_copy_exists?
  end

  def working_copy_exists?
    File.directory?(File.join(@resource.value(:path), '.git'))
  end
  
  def path_exists?
    File.directory?(@resource.value(:path))
  end

  def bare_git_config_exists?
    File.exist?(File.join(@resource.value(:path), 'config'))
  end
  
  def clone_repository(source, path)
    git('clone', source, path)
  end

  def fetch
    at_path do
      git('fetch', 'origin')
    end
  end

  def init_repository(path)
    if @resource.value(:ensure) == 'bare' && working_copy_exists?
      convert_working_copy_to_bare
    elsif @resource.value(:ensure) == 'present' && bare_exists?
      convert_bare_to_working_copy
    elsif File.directory?(@resource.value(:path))
      raise Puppet::Error, "Could not create repository (non-repository at path)"
    else
      normal_init
    end
  end

  # Convert working copy to bare
  #
  # Moves:
  #   <path>/.git
  # to:
  #   <path>/
  def convert_working_copy_to_bare
    FileUtils.mv(File.join(@resource.value(:path), '.git'), tempdir)
    FileUtils.rm_rf(@resource.value(:path))
    FileUtils.cp_r(tempdir, @resource.value(:path))
  end

  # Convert bare to working copy
  #
  # Moves:
  #   <path>/
  # to:
  #   <path>/.git
  def convert_bare_to_working_copy
    FileUtils.mv(@resource.value(:path), tempdir)
    FileUtils.mkdir(@resource.value(:path))
    FileUtils.cp_r(tempdir, File.join(@resource.value(:path), '.git'))
    reset('HEAD')
    git('checkout', '-f')
  end

  def normal_init
    FileUtils.mkdir(@resource.value(:path))
    args = ['init']
    if @resource.value(:ensure) == 'bare'
      args << '--bare'
    end
    at_path do
      git(*args)
    end
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

  def tempdir
    @tempdir ||= File.join(Dir.tmpdir, 'vcsrepo-' + Digest::MD5.hexdigest(@resource.value(:path)))
  end

end
