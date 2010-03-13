require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

provider_class = Puppet::Type.type(:vcsrepo).provider(:svn)

describe provider_class do

  before :each do
    @resource = stub("resource")
    @provider = provider_class.new(@resource)
    @path = '/tmp/vcsrepo'
  end

  context 'when creating' do
    context "when a source is given" do
      context "and when a revision is given" do
        it "should execute 'svn checkout' with a revision" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @resource.expects(:value).with(:source).returns('svn://example.com/repo').at_least_once
          @resource.expects(:value).with(:revision).returns('1234').at_least_once
          @provider.expects(:svn).with('checkout', '-r', '1234', 'svn://example.com/repo', @path)
          @provider.create
        end        
      end
      context "and when a revision is not given" do
        it "should just execute 'svn checkout' without a revision" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @resource.expects(:value).with(:source).returns('svn://example.com/repo').at_least_once
          @resource.expects(:value).with(:revision).returns(nil).at_least_once
          @provider.expects(:svn).with('checkout','svn://example.com/repo', @path)
          @provider.create
        end        
      end
    end
    context "when a source is not given" do
      context "when a fstype is given" do
        it "should execute 'svnadmin create' with an '--fs-type' option" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @resource.expects(:value).with(:fstype).returns('fsfs').at_least_once
          @resource.expects(:value).with(:source).returns(nil)
          @provider.expects(:svnadmin).with('create', '--fs-type', 'fsfs', @path)
          @provider.create
        end
      end
      context "when a fstype is not given" do
        it "should execute 'svnadmin create' without an '--fs-type' option" do
          @resource.expects(:value).with(:path).returns(@path).at_least_once
          @resource.expects(:value).with(:source).returns(nil)
          @resource.expects(:value).with(:fstype).returns(nil).at_least_once
          @provider.expects(:svnadmin).with('create', @path)
          @provider.create
        end
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

  describe "revision property" do
    context "when checking" do
      it "should use 'svn info'" do
        @resource.expects(:value).with(:path).returns(@path)
        p fixture(:svn_info)[/^Revision:\s+(\d+)/m, 1]
        @provider.expects('svn').with('info').returns(fixture(:svn_info))
        Dir.expects(:chdir).with(@path).yields
        @provider.revision.should == '4'
      end
    end
    context "when setting" do
      it "should use 'svn update'" do
        @resource.expects(:value).with(:path).returns(@path)
        @provider.expects('svn').with('update', '-r', '30')
        Dir.expects(:chdir).with(@path).yields
        @provider.revision = '30'
      end
    end
  end

end
