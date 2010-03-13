Using vcsrepo with CVS
======================

To create a blank repository
----------------------------

Define a `vcsrepo` without a `source` or `revision`:

    vcsrepo { "/path/to/repo":
      ensure => present,
      provider => cvs
    }

To checkout/update from a repository
------------------------------------

To get the current mainline:

    vcsrepo { "/path/to/workspace":
        ensure => present,
        provider => cvs,
        source => ":pserver:anonymous@example.com:/sources/myproj"
    }

You can use the `compression` parameter (it works like CVS `-z`):

    vcsrepo { "/path/to/workspace":
        ensure => present,
        provider => cvs,
        compression => 3,
        source => ":pserver:anonymous@example.com:/sources/myproj"
    }

For a specific tag, use `revision`:

    vcsrepo { "/path/to/workspace":
        ensure => present,
        provider => cvs,
        compression => 3,
        source => ":pserver:anonymous@example.com:/sources/myproj",
        revision => "SOMETAG"
    }
