module VcsrepoHelpers

  def expects_chdir
    Dir.expects(:chdir).with(resource.value(:path)).at_least_once.yields
  end
  
  def expects_mkdir
    Dir.expects(:mkdir).with(resource.value(:path)).at_least_once
  end

  
end
