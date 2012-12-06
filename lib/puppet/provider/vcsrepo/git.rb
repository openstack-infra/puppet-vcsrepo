require File.join(File.dirname(__FILE__), '..', 'vcsrepo')

Puppet::Type.type(:vcsrepo).provide(:git, :parent => Puppet::Provider::Vcsrepo) do
  desc "Supports Git repositories"

  ##TODO modify the commands below so that the su - is included
  optional_commands :git => 'git',
                    :su => 'su'
  defaultfor :git => :exists
  has_features :bare_repositories, :reference_tracking, :ssh_identity, :multiple_remotes, :user

  def create
    if !@resource.value(:source)
      init_repository(@resource.value(:path))
    else
      clone_repository(@resource.value(:source), @resource.value(:path))
      if @resource.value(:revision)
        if @resource.value(:ensure) == :bare
          notice "Ignoring revision for bare repository"
        else
          checkout
        end
      end
      if @resource.value(:ensure) != :bare
        update_submodules
      end
    end
    update_owner_and_excludes
  end

  def destroy
    FileUtils.rm_rf(@resource.value(:path))
  end

  def latest?
    #notice "in latest?"
    update_references
    return self.head_revision == self.latest
    #notice "end of latest?"
  end

  def latest
    #notice "In Latest"
    if @resource.value(:revision)
      #notice "We've requested an explicit revision"
      if tag_revision?(@resource.value(:revision))
        #notice "tag #{@resource.value(:revision)}"
        return get_revision(@resource.value(:revision))
      elsif remote_branch_revision?(@resource.value(:revision))
        #notice "branch #{@resource.value(:revision)}"
        return get_revision("remotes/#{@resource.value(:remote)}/#{@resource.value(:revision)}")
      end
    else
      #notice "we just want the latest thing"
      return get_revision('FETCH_HEAD')
    end
  end

  def head_revision
    #notice "in head_revision"
    return get_revision('HEAD')
  end

  def revision
    #notice "in revision"
    return @resource.value(:revision) || self.head_revision
  end

  def revision=(desired)
    checkout(desired)
    if local_branch_revision?(desired)
      #notice "revision=local_branch_revision? #{desired}"
      # reset instead of pull to avoid merge conflicts. assuming remote is
      # authoritative.
      # might be worthwhile to have an allow_local_changes param to decide
      # whether to reset or pull when we're ensuring latest.
      at_path { git_with_identity('reset', '--hard', "#{@resource.value(:remote)}/#{desired}") }
    else
      at_path { git_with_identity('reset', '--hard', "#{desired}") }
    end
    if @resource.value(:ensure) != :bare
      update_submodules
    end
    update_owner_and_excludes
  end

  def bare_exists?
    bare_git_config_exists? && !working_copy_exists?
  end

  def working_copy_exists?
    File.directory?(File.join(@resource.value(:path), '.git'))
  end

  def exists?
    working_copy_exists? || bare_exists?
  end

  def update_references
    at_path do
      git_with_identity('fetch', '--tags', @resource.value(:remote))
      git_with_identity('fetch', @resource.value(:remote))
      update_owner_and_excludes
    end
  end

  private

  def bare_git_config_exists?
    File.exist?(File.join(@resource.value(:path), 'config'))
  end

  def clone_repository(source, path)
    check_force
    args = ['clone']
    if @resource.value(:ensure) == :bare
      args << '--bare'
    end
    if !File.exist?(File.join(@resource.value(:path), '.git'))
      args.push(source, path)
      git_with_identity(*args)
    else
      notice "Repo has already been cloned"
    end
  end

  def check_force
    if path_exists?
      if @resource.value(:force)
        notice "Removing %s to replace with vcsrepo." % @resource.value(:path)
        destroy
      else
        raise Puppet::Error, "Could not create repository (non-repository at path)"
      end
    end
  end

  def init_repository(path)
    check_force
    if @resource.value(:ensure) == :bare && working_copy_exists?
      convert_working_copy_to_bare
    elsif @resource.value(:ensure) == :present && bare_exists?
      convert_bare_to_working_copy
    else
      # normal init
      FileUtils.mkdir(@resource.value(:path))
      args = ['init']
      if @resource.value(:ensure) == :bare
        args << '--bare'
      end
      at_path do
        git_with_identity(*args)
      end
    end
  end

  # Convert working copy to bare
  #
  # Moves:
  #   <path>/.git
  # to:
  #   <path>/
  def convert_working_copy_to_bare
    notice "Converting working copy repository to bare repository"
    FileUtils.mv(File.join(@resource.value(:path), '.git'), tempdir)
    FileUtils.rm_rf(@resource.value(:path))
    FileUtils.mv(tempdir, @resource.value(:path))
  end

  # Convert bare to working copy
  #
  # Moves:
  #   <path>/
  # to:
  #   <path>/.git
  def convert_bare_to_working_copy
    notice "Converting bare repository to working copy repository"
    FileUtils.mv(@resource.value(:path), tempdir)
    FileUtils.mkdir(@resource.value(:path))
    FileUtils.mv(tempdir, File.join(@resource.value(:path), '.git'))
    if commits_in?(File.join(@resource.value(:path), '.git'))
      reset('HEAD')
      git_with_identity('checkout', '-f')
      update_owner_and_excludes
    end
  end

  def commits_in?(dot_git)
    Dir.glob(File.join(dot_git, 'objects/info/*'), File::FNM_DOTMATCH) do |e|
      return true unless %w(. ..).include?(File::basename(e))
    end
    false
  end

  def checkout(revision = @resource.value(:revision))
    if tag_revision?(revision)
      if !local_branch_revision?("tag/#{revision}")
        at_path { git_with_identity('checkout', '-b', "tag/#{revision}", "#{revision}") }
      else
        at_path { git_with_identity('checkout', '--force', "tag/#{revision}") }
      end
    elsif remote_branch_revision?(revision) && !local_branch_revision?(revision)
        at_path { git_with_identity('checkout', '-b', revision, '--track', "#{@resource.value(:remote)}/#{revision}") }
    else
      at_path { git_with_identity('checkout', '--force', revision) }
    end
  end

  def reset(desired)
    at_path do
      git_with_identity('reset', '--hard', desired)
    end
  end

  def update_submodules
    at_path do
      git_with_identity('submodule', 'init')
      git_with_identity('submodule', 'update')
      git_with_identity('submodule', 'foreach', 'git', 'submodule', 'init')
      git_with_identity('submodule', 'foreach', 'git', 'submodule', 'update')
    end
  end

  def remote_branch_revision?(revision = @resource.value(:revision))
    # git < 1.6 returns '#{@resource.value(:remote)}/#{revision}'
    # git 1.6+ returns 'remotes/#{@resource.value(:remote)}/#{revision}'
    branch = at_path { branches.grep /(remotes\/)?#{@resource.value(:remote)}\/#{revision}/ }
    if branch.length > 0
      return branch
    end
  end

  def local_branch_revision?(revision = @resource.value(:revision))
    at_path { branches.include?(revision) }
  end

  def tag_revision?(revision = @resource.value(:revision))
    at_path { tags.include?(revision) }
  end

  def branches
    at_path { git_with_identity('branch', '-a') }.gsub('*', ' ').split(/\n/).map { |line| line.strip }
  end

  def on_branch?
    at_path { git_with_identity('branch', '-a') }.split(/\n/).grep(/\*/).first.to_s.gsub('*', '').strip
  end

  def tags
    at_path { git_with_identity('tag', '-l') }.split(/\n/).map { |line| line.strip }
  end

  def set_excludes
    at_path { open('.git/info/exclude', 'w') { |f| @resource.value(:excludes).each { |ex| f.write(ex + "\n") }}}
  end

  def get_revision(rev)
    #notice "in get_revision #{rev}"
    if !working_copy_exists?
      create
    end
    return at_path { git_with_identity('rev-parse', rev).strip }
  end

  def update_owner_and_excludes
    if @resource.value(:owner) or @resource.value(:group)
      set_ownership
    end
    if @resource.value(:excludes)
      set_excludes
    end
  end

  def git_with_identity(*args)
    if @resource.value(:identity)
      Tempfile.open('git-helper') do |f|
        f.puts '#!/bin/sh'
        f.puts "exec ssh -oStrictHostKeyChecking=no -oPasswordAuthentication=no -oKbdInteractiveAuthentication=no -oChallengeResponseAuthentication=no -i #{@resource.value(:identity)} $*"
        f.close

        FileUtils.chmod(0755, f.path)
        env_save = ENV['GIT_SSH']
        ENV['GIT_SSH'] = f.path

        ret = git(*args)

        ENV['GIT_SSH'] = env_save

        return ret
      end
    elsif @resource.value(:user)
      su(@resource.value(:user), '-c', "git #{args.join(' ')}" )
    else
      #notice "git #{args.join(' ')}"
      git(*args)
    end
  end
end
