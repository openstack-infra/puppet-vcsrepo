Using vcsrepo with Mercurial
============================

To create a blank repository
----------------------------

Define a `vcsrepo` without a `source` or `revision`:

    vcsrepo { "/path/to/repo":
      ensure   => present,
      provider => hg
    }

To clone/pull & update a repository
----------------------------

To get the default branch tip:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => hg,
        source   => "http://hg.example.com/myrepo"
    }

For a specific changeset, use `revision`:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => hg,
        source   => "http://hg.example.com/myrepo"
        revision => '21ea4598c962'
    }

You can also set `revision` to a tag:

    vcsrepo { "/path/to/repo":
        ensure   => present,
        provider => hg,
        source   => "http://hg.example.com/myrepo"
        revision => '1.1.2'
    }
