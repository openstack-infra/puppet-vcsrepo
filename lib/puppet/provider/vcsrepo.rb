require 'tmpdir'
require 'digest/md5'

# Abstract
class Puppet::Provider::Vcsrepo < Puppet::Provider

  private

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
