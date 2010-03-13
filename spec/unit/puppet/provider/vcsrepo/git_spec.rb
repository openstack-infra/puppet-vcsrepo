require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

provider_class = Puppet::Type.type(:vcsrepo).provider(:git)

describe provider_class do

  before :each do
    @resource = stub("resource")
    @provider = provider_class.new(@resource)
    @path = '/tmp/vcsrepo'
  end

  describe 'when creating' do
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

  describe 'when destroying' do
    it "it should remove the directory" do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      FileUtils.expects(:rm_rf).with(@path)
      @provider.destroy
    end
  end

  describe "when checking existence" do
    it "should check for the directory" do
      @resource.expects(:value).with(:path).returns(@path)
      File.expects(:directory?).with(@path)
      @provider.exists?
    end
  end

  describe "when checking the revision property" do
    context "when given a non-SHA ref as the resource revision" do
      context "when its SHA is not different than the curent SHA" do
        it "should return the ref" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
          @resource.expects(:value).with(:revision).returns('a-tag').at_least_once
          @provider.expects(:git).with('rev-parse', 'a-tag').returns('currentsha')
          Dir.expects(:chdir).with(@path).twice.yields
          @provider.revision.should == 'a-tag'
        end
      end
      context "when its SHA is different than the current SHA" do
        it "should return the current SHA" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
          @resource.expects(:value).with(:revision).returns('a-tag').at_least_once
          @provider.expects(:git).with('rev-parse', 'a-tag').returns('othersha')
          Dir.expects(:chdir).with(@path).twice.yields
          @provider.revision.should == 'currentsha'
        end          
      end
    end
    context "when given a SHA ref as the resource revision" do
      context "when it is the same as the current SHA" do
        it "should return it" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
          @resource.expects(:value).with(:revision).returns('currentsha').at_least_once
          @provider.expects(:git).with('rev-parse', 'currentsha').returns('currentsha')
          Dir.expects(:chdir).with(@path).twice.yields
          @provider.revision.should == 'currentsha'
        end
      end
      context "when it is not the same as the current SHA" do
        it "should return the current SHA" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
          @resource.expects(:value).with(:revision).returns('othersha').at_least_once
          @provider.expects(:git).with('rev-parse', 'othersha').returns('othersha')
          Dir.expects(:chdir).with(@path).twice.yields
          @provider.revision.should == 'currentsha'
        end
      end
    end
  end
  
  describe "when setting the revision property" do
    it "should use 'git fetch' and 'git reset'" do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      @provider.expects('git').with('fetch', 'origin')
      Dir.expects(:chdir).with(@path).at_least_once.yields
      @provider.expects('git').with('reset', '--hard', 'carcar')
      @provider.revision = 'carcar'
    end
  end

end
