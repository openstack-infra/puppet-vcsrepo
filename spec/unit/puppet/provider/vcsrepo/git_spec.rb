require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

describe_provider :vcsrepo, :git, :resource => {:path => '/tmp/vcsrepo'} do
  
  context 'creating' do
    context_with :source do
      context_with :ensure => :present do
        context_with :revision do
          it "should execute 'git clone' and 'git reset --hard'" do
            provider.expects('git').with('clone', resource.value(:source), resource.value(:path))
            expects_chdir
            provider.expects('git').with('reset', '--hard', resource.value(:revision))
            provider.create
          end
        end
        
        context_without :revision do
          it "should just execute 'git clone'" do
            provider.expects(:git).with('clone', resource.value(:source), resource.value(:path))
            provider.create
          end
        end
      end
      
      context_with :ensure => :bare do
        context_with :revision do
          it "should just execute 'git clone --bare'" do
            subject.expects(:git).with('clone', '--bare', resource.value(:source), resource.value(:path))
            subject.create
          end
        end
        
        context_without :revision do
          it "should just execute 'git clone --bare'" do
            subject.expects(:git).with('clone', '--bare', resource.value(:source), resource.value(:path))
            subject.create
          end
        end
      end
    end
    
    context "when a source is not given" do
      context_with :ensure => :present do
        context "when the path does not exist" do
          it "should execute 'git init'" do
            expects_mkdir
            expects_chdir
            expects_directory?(false)
            provider.expects(:bare_exists?).returns(false)
            provider.expects(:git).with('init')
            provider.create
          end
        end
        
        context "when the path is a bare repository" do
          it "should convert it to a working copy" do
            provider.expects(:bare_exists?).returns(true)
            provider.expects(:convert_bare_to_working_copy)
            provider.create
          end
        end
        
        context "when the path is not a repository" do
          it "should raise an exception" do
            expects_directory?(true)
            provider.expects(:bare_exists?).returns(false)
            proc { provider.create }.should raise_error(Puppet::Error)
          end
        end
      end
      
      context_with :ensure => :bare do
        context "when the path does not exist" do
          it "should execute 'git init --bare'" do
            expects_chdir
            expects_mkdir
            expects_directory?(false)
            provider.expects(:working_copy_exists?).returns(false)
            provider.expects(:git).with('init', '--bare')
            provider.create
          end
        end
        
        context "when the path is a working copy repository" do
          it "should convert it to a bare repository" do
            provider.expects(:working_copy_exists?).returns(true)
            provider.expects(:convert_working_copy_to_bare)
            provider.create
          end
        end
        
        context "when the path is not a repository" do
          it "should raise an exception" do
            expects_directory?(true)
            provider.expects(:working_copy_exists?).returns(false)
            proc { provider.create }.should raise_error(Puppet::Error)
          end
        end
      end
    end
    
    context 'destroying' do
      it "it should remove the directory" do
        expects_rm_rf
        provider.destroy
      end
    end
    
    context "checking the revision property" do
      context_with :revision do
        before do
          expects_chdir
          provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
        end
        
        context "when its SHA is not different than the current SHA" do
          it "should return the ref" do
            provider.expects(:git).with('rev-parse', resource.value(:revision)).returns('currentsha')
            provider.revision.should == resource.value(:revision)
          end
        end
        
        context "when its SHA is different than the current SHA" do
          it "should return the current SHA" do
            provider.expects(:git).with('rev-parse', resource.value(:revision)).returns('othersha')
            provider.revision.should == 'currentsha'
          end
        end
      end
    end
    
    context "setting the revision property" do
      it "should use 'git fetch' and 'git reset'" do
        expects_chdir
        provider.expects('git').with('fetch', 'origin')
        provider.expects('git').with('reset', '--hard', 'carcar')
        provider.revision = 'carcar'
      end
    end
    
    context "updating references" do
      it "should use 'git fetch --tags'" do
        expects_chdir
        provider.expects('git').with('fetch', '--tags', 'origin')
        provider.update_references
      end
    end
    
  end
end
