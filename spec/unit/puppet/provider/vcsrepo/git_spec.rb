require 'pathname'; Pathname.new(__FILE__).realpath.ascend { |x| begin; require (x + 'spec_helper.rb'); break; rescue LoadError; end }

describe_provider :vcsrepo, :git, :resource => {:path => '/tmp/vcsrepo'} do
  
  context 'when creating' do
    context "when a source is given", :resource => {:source => 'git://example.com/repo.git'} do
      context "when ensure => present", :resource => {:ensure => :present} do
        context "when a revision is given", :resource => {:revision => 'abcdef'} do
          it "should execute 'git clone' and 'git reset --hard'" do
            provider.expects('git').with('clone', resource.value(:source), resource.value(:path))
            expects_chdir
            provider.expects('git').with('reset', '--hard', 'abcdef')
            provider.create
          end
        end
        
        context "when a revision is not given" do
          it "should just execute 'git clone'" do
            provider.expects(:git).with('clone', 'git://example.com/repo.git', resource.value(:path))
            provider.create
          end
        end
      end
      
      context "when ensure => bare", :resource => {:ensure => :bare} do
        context "when a revision is given", :resource => {:revision => 'abcdef'} do
          it "should just execute 'git clone --bare'" do
            subject.expects(:git).with('clone', '--bare', 'git://example.com/repo.git', resource.value(:path))
            subject.create
          end
        end
        
        context "when a revision is not given" do
          it "should just execute 'git clone --bare'" do
            subject.expects(:git).with('clone', '--bare', 'git://example.com/repo.git', resource.value(:path))
            subject.create
          end
        end
      end
    end
    
    context "when a source is not given" do
      context "when ensure => present", :resource => {:ensure => :present} do
        context "when the path does not exist" do
          it "should execute 'git init'" do
            expects_mkdir
            expects_chdir
            provider.expects(:bare_exists?).returns(false)
            File.expects(:directory?).with(resource.value(:path)).returns(false)
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
            File.expects(:directory?).with(resource.value(:path)).returns(true)
            provider.expects(:bare_exists?).returns(false)
            proc { provider.create }.should raise_error(Puppet::Error)
          end
        end
      end
      
      context "when ensure = bare", :resource => {:ensure => :bare} do
        context "when the path does not exist" do
          it "should execute 'git init --bare'" do
            expects_chdir
            expects_mkdir
            File.expects(:directory?).with(resource.value(:path)).returns(false)
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
            File.expects(:directory?).with(resource.value(:path)).returns(true)
            provider.expects(:working_copy_exists?).returns(false)
            proc { provider.create }.should raise_error(Puppet::Error)
          end
        end
      end
    end
    
    context 'when destroying' do
      it "it should remove the directory" do
        FileUtils.expects(:rm_rf).with(resource.value(:path))
        provider.destroy
      end
    end
    
    context "when checking the revision property" do
      context "when given a non-SHA ref as the resource revision", :resource => {:revision => 'a-tag'} do
        context "when its SHA is not different than the current SHA" do
          it "should return the ref" do
            expects_chdir
            provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
            provider.expects(:git).with('rev-parse', 'a-tag').returns('currentsha')
            provider.revision.should == 'a-tag'
          end
        end
        
        context "when its SHA is different than the current SHA" do
          it "should return the current SHA" do
            expects_chdir
            provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
            provider.expects(:git).with('rev-parse', 'a-tag').returns('othersha')
            provider.revision.should == 'currentsha'
          end
        end
      end
      
      context "when given a SHA ref as the resource revision" do
        context "when it is the same as the current SHA", :resource => {:revision => 'currentsha'} do
          it "should return it" do
            expects_chdir
            provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
            provider.expects(:git).with('rev-parse', 'currentsha').returns('currentsha')
            provider.revision.should == 'currentsha'
          end
        end
        
        context "when it is not the same as the current SHA", :resource => {:revision => 'othersha'} do
          it "should return the current SHA" do
            expects_chdir
            provider.expects(:git).with('rev-parse', 'HEAD').returns('currentsha')
            provider.expects(:git).with('rev-parse', 'othersha').returns('othersha')
            provider.revision.should == 'currentsha'
          end
        end
      end
    end
    
    context "when setting the revision property" do
      it "should use 'git fetch' and 'git reset'" do
        expects_chdir
        provider.expects('git').with('fetch', 'origin')
        provider.expects('git').with('reset', '--hard', 'carcar')
        provider.revision = 'carcar'
      end
    end
    
    context "when updating references" do
      it "should use 'git fetch --tags'" do
        expects_chdir
        provider.expects('git').with('fetch', '--tags', 'origin')
        provider.update_references
      end
    end
    
  end
end
