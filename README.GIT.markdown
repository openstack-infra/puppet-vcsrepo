Using vcsrepo with Git
======================

To create a blank repository
----------------------------

Define a `vcsrepo` without a `source` or `revision`:

    vcsrepo { "/path/to/repo":
      ensure: present
    }

If you're defining this for a central/"official" repository, you'll
probably want to make it a "bare" repository.  Do this by setting
`ensure` to `bare` instead of `present`:

    vcsrepo { "/path/to/repo":
        ensure: bare
    }

