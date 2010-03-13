vcsrepo { "/tmp/vcstest-git-bare":
  ensure => bare,
  provider => git
}

vcsrepo { "/tmp/vcstest-git-wc":
  ensure => present,
  provider => git
}

vcsrepo { "/tmp/vcstest-git-clone":
  ensure => present,
  provider => git,
  source => "git://github.com/bruce/rtex.git"
} 
