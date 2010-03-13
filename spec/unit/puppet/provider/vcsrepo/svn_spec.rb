require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

provider_class = Puppet::Type.type(:vcsrepo).provider(:svn)

describe provider_class do

  before do
    @resource = stub("resource")
    @provider = provider_class.new(@resource)
  end

  describe 'when creating'
  describe 'when updating'
  describe 'when destroying'

end
