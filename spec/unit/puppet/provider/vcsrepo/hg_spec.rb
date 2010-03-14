require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

provider_class = Puppet::Type.type(:vcsrepo).provider(:hg)

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
        @source = 'http://example.com/hg/repo'
        @resource.expects(:value).with(:source).returns(@source).at_least_once
      end
      context "and when a revision is given" do
        before do
          @revision = '6aa99e9b3ac2'
          @resource.expects(:value).with(:revision).returns(@revision).at_least_once
        end
        it "should execute 'hg clone -u' with the revision" do
          @provider.expects(:hg).with('clone', '-u', @revision, @source, @path)
          @provider.create
        end        
      end
      context "and when a revision is not given" do
        before do
          @resource.expects(:value).with(:revision).returns(nil).at_least_once
        end
        it "should just execute 'hg clone' without a revision" do
          @provider.expects(:hg).with('clone', @source, @path)
          @provider.create
        end        
      end
    end
    context "when a source is not given" do
      before do
        @resource.expects(:value).with(:source).returns(nil).at_least_once
      end
      it "should execute 'hg init'" do
        @provider.expects(:hg).with('init', @path)
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
      File.expects(:directory?).with(File.join(@path, '.hg'))
      @provider.exists?
    end
  end

  describe "when checking the revision property" do
    before do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      Dir.expects(:chdir).with(@path).yields
    end
    context "when given a non-SHA as the resource revision" do
      before do
        @provider.expects(:hg).with('parents').returns(fixture(:hg_parents))
      end
      context "when its SHA is not different than the current SHA" do
        before do
          @resource.expects(:value).with(:revision).returns('0.6').at_least_once
        end
        it "should return the ref" do
          @provider.expects(:hg).with('tags').returns(fixture(:hg_tags))
          @provider.revision.should == '0.6'
        end
      end
      context "when its SHA is different than the current SHA" do
        before do
          @resource.expects(:value).with(:revision).returns('0.5.3').at_least_once
        end
        it "should return the current SHA" do
          @provider.expects(:hg).with('tags').returns(fixture(:hg_tags))
          @provider.revision.should == '34e6012c783a'
        end          
      end
    end
    context "when given a SHA as the resource revision" do
      before do
        @provider.expects(:hg).with('parents').returns(fixture(:hg_parents))
      end
      context "when it is the same as the current SHA" do
        before do
          @resource.expects(:value).with(:revision).returns('34e6012c783a').at_least_once
        end
        it "should return it" do
          @provider.expects(:hg).with('tags').never
          @provider.revision.should == '34e6012c783a'
        end
      end
      context "when it is not the same as the current SHA" do
        before do
          @resource.expects(:value).with(:revision).returns('34e6012c7').at_least_once
        end
        it "should return the current SHA" do
          @provider.expects(:hg).with('tags').returns(fixture(:hg_tags))          
          @provider.revision.should == '34e6012c783a'
        end
      end
    end
  end
  
  describe "when setting the revision property" do
    before do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      @revision = '6aa99e9b3ab1'
    end
    it "should use 'hg update ---clean -r'" do
      Dir.expects(:chdir).with(@path).yields
      @provider.expects('hg').with('pull')
      @provider.expects('hg').with('merge')
      @provider.expects('hg').with('update', '--clean', '-r', @revision)
      @provider.revision = @revision
    end
  end

end
