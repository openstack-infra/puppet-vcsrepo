require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

provider_class = Puppet::Type.type(:vcsrepo).provider(:bzr)

describe provider_class do

  before :each do
    @resource = stub("resource")
    @provider = provider_class.new(@resource)
    @path = '/tmp/vcsrepo'
  end

  describe 'when creating' do
    before do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
    end
    context "when a source is given" do
      before do
        @source = 'http://example.com/bzr/repo'
        @resource.expects(:value).with(:source).returns(@source).at_least_once
      end
      context "and when a revision is given" do
        before do
          @revision = 'somerev'
          @resource.expects(:value).with(:revision).returns(@revision).at_least_once
        end
        it "should execute 'bzr clone -r' with the revision" do
          @provider.expects(:bzr).with('branch', '-r', @revision, @source, @path)
          @provider.create
        end
      end
      context "and when a revision is not given" do
        before do
          @resource.expects(:value).with(:revision).returns(nil).at_least_once
        end
        it "should just execute 'bzr clone' without a revision" do
          @provider.expects(:bzr).with('branch', @source, @path)
          @provider.create
        end
      end
    end
    context "when a source is not given" do
      before do
        @resource.expects(:value).with(:source).returns(nil).at_least_once
      end
      it "should execute 'bzr init'" do
        @provider.expects(:bzr).with('init', @path)
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
    before do
      @resource.expects(:value).with(:path).returns(@path)
    end
    it "should check for the directory" do
      File.expects(:directory?).with(File.join(@path, '.bzr'))
      @provider.exists?
    end
  end

  describe "when checking the revision property" do
    before do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      Dir.expects(:chdir).with(@path).yields
      @provider.expects(:bzr).with('version-info').returns(fixture(:bzr_version_info))
      @current_revid = 'menesis@pov.lt-20100309191856-4wmfqzc803fj300x'
      @current_revno = '2634'
    end
    context "when given a non-revid as the resource revision" do
      context "when its revid is not different than the current revid" do
        before do
          @revision = @current_revno
          @resource.expects(:value).with(:revision).returns(@revision).at_least_once
        end
        it "should return the ref" do
          @provider.expects(:bzr).with('revision-info', @revision).returns("#{@current_revno} #{@current_revid}\n")
          @provider.revision.should == @revision
        end
      end
      context "when its revid is different than the current revid" do
        before do
          @revision = '2636'
          @resource.expects(:value).with(:revision).returns(@revision).at_least_once
        end
        it "should return the current revid" do
          @provider.expects(:bzr).with('revision-info', @revision).returns("#{@revision} menesis@pov.lt-20100309191856-4wmfqzc803fj300y\n")
          @provider.revision.should == @current_revid
        end          
      end
    end
    context "when given a revid as the resource revision" do
      context "when it is the same as the current revid" do
        before do
          @revision = @current_revid
          @resource.expects(:value).with(:revision).returns(@revision).at_least_once
        end
        it "should return it" do
          @provider.expects(:bzr).with('revision-info', @revision).returns("#{@current_revno} #{@current_revid}\n")
          @provider.revision.should == @revision
        end
      end
      context "when it is not the same as the current revid" do
        before do
          @revision = 'menesis@pov.lt-20100309191856-4wmfqzc803fj300y'
          @resource.expects(:value).with(:revision).returns(@revision).at_least_once
        end
        it "should return the current revid" do
          @provider.expects(:bzr).with('revision-info', @revision).returns("2636 #{@revision}\n")
          @provider.revision.should == @current_revid
        end
      end
    end
  end
  
  describe "when setting the revision property" do
    before do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      @revision = 'somerev'
    end
    it "should use 'bzr update -r' with the revision" do
      @provider.expects('bzr').with('update', '-r', @revision, @path)
      @provider.revision = @revision
    end
  end

end
