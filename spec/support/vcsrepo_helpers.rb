module VcsrepoHelpers

  def expects_chdir(path = resource.value(:path))
    Dir.expects(:chdir).with(path).at_least_once.yields
  end
  
  def expects_mkdir(path = resource.value(:path))
    Dir.expects(:mkdir).with(path).at_least_once
  end

end
