require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

describe_provider :vcsrepo, :svn, :resource => {:path => '/tmp/vcsrepo'} do

  describe 'creating' do
    context_with_resource :source do
      context_with_resource :revision do
        it "should execute 'svn checkout' with a revision" do
          provider.expects(:svn).with('checkout', '-r',
                                      resource.value(:revision),
                                      resource.value(:source),
                                      resource.value(:path))
          provider.create
        end        
      end
      context_without_resource :revision do
        it "should just execute 'svn checkout' without a revision" do
          provider.expects(:svn).with('checkout',
                                      resource.value(:source),
                                      resource.value(:path))
          provider.create
        end        
      end
    end
    context_without_resource :source do
      context_with_resource :fstype do
        it "should execute 'svnadmin create' with an '--fs-type' option" do
          provider.expects(:svnadmin).with('create', '--fs-type',
                                           resource.value(:fstype),
                                           resource.value(:path))
          provider.create
        end
      end
      context_without_resource :fstype do
        it "should execute 'svnadmin create' without an '--fs-type' option" do
          provider.expects(:svnadmin).with('create', resource.value(:path))
          provider.create
        end
      end
    end
  end

  describe 'destroying' do
    it "it should remove the directory" do
      expects_rm_rf
      provider.destroy
    end
  end

  describe "checking existence" do
    it "should check for the directory" do
      expects_directory?(true, File.join(resource.value(:path), '.svn'))
      provider.exists?
    end
  end

  describe "checking the revision property" do
    before do
      provider.expects('svn').with('info').returns(fixture(:svn_info))
    end
    it "should use 'svn info'" do
      expects_chdir
      provider.revision.should == '4'
    end
  end
  
  describe "setting the revision property" do
    before do
      @revision = '30'
    end
    it "should use 'svn update'" do
      expects_chdir
      provider.expects('svn').with('update', '-r', @revision)
      provider.revision = @revision
    end
  end

end
