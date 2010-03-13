vcsrepo { "/tmp/vcstest-hg-init":
  ensure => present,
  provider => hg
}

vcsrepo { "/tmp/vcstest-hg-clone":
  ensure => present,
  provider => hg,
  source => "http://hg.basho.com/riak/",
  revision => '34e6012c783a'
} 
