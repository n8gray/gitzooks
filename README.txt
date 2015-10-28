Some Git Hooks
==============
By Nathan Gray

This is going to be a collection of git hooks that I find useful.  For now there are two.

Commit Exclusions
-----------------

I use this to reject any commit that adds the text "NOCOMMIT".  This allows me to throw crazy hacks into my code without fear that I'll overlook them at commit time.

Git Local Revision Number Hook
------------------------------

This is a git update hook that assigns each commit a monotonically increasing local revision number.  You can think of it a bit like bringing a little bit of subversiony goodness to git.  (He he he.)  Seriously, this kind of thing makes sense when you have a central authoritative repository and a need to communicate with users who don't use git (e.g. the QA department) and it can make git an easier sell in corporate environments.

To set this up on the server, install this script (or symlink it) to hooks/update in the bare git repo on your server.  Note that this is only designed to work on bare repos that are not committed to directly!

The revision numbers are attached to commits using git notes.  This requires a bit of setup if you want to see them on the client side.  We'll assume the authoritative repo is a remote called "origin".

1. Set up your client repo to pull notes from origin by adding this line to the [remote "origin"] section of the client's .git/config file:
    fetch = +refs/notes/*:refs/notes/origin/*

2. Set up your client repo to display all notes when showing git logs by adding a new section to the .git/config file:
  [notes]
      displayRef = *

3. After doing a push you won't find out what revision(s) the pushed commit(s) were assigned until your next pull.

