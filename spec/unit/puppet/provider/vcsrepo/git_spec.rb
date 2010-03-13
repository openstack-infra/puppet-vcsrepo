require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

provider_class = Puppet::Type.type(:vcsrepo).provider(:git)

describe provider_class do

  before :each do
    @resource = stub("resource")
    @provider = provider_class.new(@resource)
    @path = '/tmp/vcsrepo'
  end

  context 'when creating' do
    context "when a source is given" do
      context "and when a revision is given" do
        it "should execute 'git clone' and 'git reset'" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @resource.expects(:value).with(:source).returns('git://example.com/repo.git').at_least_once
          @provider.expects(:git).with('clone', 'git://example.com/repo.git', @path)
          @resource.expects(:value).with(:revision).returns('abcdef').at_least_once
          Dir.expects(:chdir).with(@path).yields
          @provider.expects('git').with('reset', '--hard', 'abcdef')
          @provider.create
        end        
      end
      context "and when a revision is not given" do
        it "should just execute 'git clone'" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @resource.expects(:value).with(:source).returns('git://example.com/repo.git').at_least_once
          @resource.expects(:value).with(:revision).returns(nil).at_least_once
          @provider.expects(:git).with('clone', 'git://example.com/repo.git', @path)
          @provider.create
        end        
      end
    end
    context "when a source is not given" do
      it "should execute 'git init'" do
        @resource.expects(:value).with(:path).returns(@path).at_least_once
        @resource.expects(:value).with(:source).returns(nil)
        Dir.expects(:chdir).with(@path).yields
        @provider.expects(:git).with('init')
        @provider.create
      end
    end
  end

  context 'when destroying' do
    it "it should remove the directory" do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      FileUtils.expects(:rm_rf).with(@path)
      @provider.destroy
    end
  end

  context "when checking existence" do
    it "should check for the directory" do
      @resource.expects(:value).with(:path).returns(@path)
      File.expects(:directory?).with(@path)
      @provider.exists?
    end
  end

  context "when checking 'revision' property"

end
