require File.join(File.dirname(__FILE__), '..', 'vcsrepo')

Puppet::Type.type(:vcsrepo).provide(:hg, :parent => Puppet::Provider::Vcsrepo) do
  desc "Supports Mercurial repositories"

  commands   :hg => 'hg'
  defaultfor :hg => :exists

  def create
    if !@resource.value(:source)
      create_repository(@resource.value(:path))
    else
      clone_repository(@resource.value(:revision))
    end
  end

  def exists?
    File.directory?(File.join(@resource.value(:path), '.hg'))
  end

  def destroy
    FileUtils.rm_rf(@resource.value(:path))
  end
  
  def revision
    at_path do
      hg('parents')[/^changeset:\s+(?:-?\d+):(\S+)/m, 1]
    end
  end

  def revision=(desired)
    at_path do
      hg('pull')
      begin
        hg('merge')
      rescue Puppet::ExecutionFailure
        # If there's nothing to merge, just skip
      end
      hg('update', '--clean', '-r', desired)
    end
  end

  private

  def create_repository(path)
    hg('init', path)
  end

  def clone_repository(revision)
    args = ['clone']
    if revision
      args.push('-u', revision)
    end
    args.push(@resource.value(:source),
              @resource.value(:path))
    hg(*args)
  end

end
