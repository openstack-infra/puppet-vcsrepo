require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

provider_class = Puppet::Type.type(:vcsrepo).provider(:cvs)

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
        @source = ":pserver:anonymous@example.com:/sources/myproj"
        @resource.expects(:value).with(:source).returns(@source).at_least_once
        Dir.expects(:chdir).with(File.dirname(@path)).yields
      end
      context "and when a revision is given" do
        before do
          @tag = 'SOMETAG'
          @resource.expects(:value).with(:revision).returns(@tag).at_least_once
          @resource.expects(:value).with(:compression).returns(nil).at_least_once
        end
        it "should execute 'cvs checkout' and 'cvs update -r'" do
          @provider.expects(:cvs).with('-d', @source, 'checkout', '-d', File.basename(@path), File.basename(@source))
          Dir.expects(:chdir).with(@path).yields
          @provider.expects(:cvs).with('update', '-r', @tag, '.')
          @provider.create
        end        
      end
      context "and when a revision is not given" do
        before do
          @resource.expects(:value).with(:revision).returns(nil).at_least_once
          @resource.expects(:value).with(:compression).returns(nil).at_least_once
        end
        it "should just execute 'cvs checkout' without a revision" do
          @provider.expects(:cvs).with('-d', @source, 'checkout', '-d', File.basename(@path), File.basename(@source))
          @provider.create
        end        
      end
      context "when a compression level is given" do
        before do
          @resource.expects(:value).with(:revision).returns(nil).at_least_once
          @resource.expects(:value).with(:compression).returns('3').at_least_once
        end
        it "should just execute 'cvs checkout' without a revision" do
          @provider.expects(:cvs).with('-d', @source, '-z', '3', 'checkout', '-d', File.basename(@path), File.basename(@source))
          @provider.create
        end        
      end
    end
    context "when a source is not given" do
      before do
        @resource.expects(:value).with(:source).returns(nil)
      end
      it "should execute 'cvs init'" do
        @provider.expects(:cvs).with('-d', @path, 'init')
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
    context "when a source is provided" do
      before do
        @resource.expects(:value).with(:source).returns(":pserver:anonymous@example.com:/sources/myproj")
      end
      it "should check for the CVS directory" do
        File.expects(:directory?).with(File.join(@path, 'CVS'))
        @provider.exists?
      end
    end
    context "when a source is not provided" do
      before do
        @resource.expects(:value).with(:source).returns(nil)        
      end
      it "should check for the CVSROOT directory" do
        File.expects(:directory?).with(File.join(@path, 'CVSROOT'))
        @provider.exists?
      end
    end
  end

  describe "when checking the revision property" do
    before do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      @tag_file = File.join(@path, 'CVS', 'Tag')
    end
    context "when CVS/Tag exists" do
      before do
        @tag = 'HEAD'
        File.expects(:exist?).with(@tag_file).returns(true)
      end
      it "should read CVS/Tag" do
        File.expects(:read).with(@tag_file).returns("T#{@tag}")
        @provider.revision.should == @tag
      end
    end
    context "when CVS/Tag does not exist" do
      before do
        File.expects(:exist?).with(@tag_file).returns(false)
      end
      it "assumes MAIN" do
        @provider.revision.should == 'MAIN'        
      end
    end
  end
  
  describe "when setting the revision property" do
    before do
      @resource.expects(:value).with(:path).returns(@path).at_least_once
      @tag = 'SOMETAG'
    end
    it "should use 'cvs update -r'" do
      Dir.expects(:chdir).with(@path).yields
      @provider.expects('cvs').with('update', '-r', @tag, '.')
      @provider.revision = @tag
    end
  end

end
