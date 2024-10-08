.. _bug_reporting-label:

How to report a bug in Lmod
===========================

Lmod has some built-in tools to make debugging possible on your site.
The first feature of Lmod is the configuration report::

   $ module --miniConfig

This reports how Lmod has been configured at build time as well as any
``LMOD_*`` environment variables set.  The second tool is the debug
output also built-in to Lmod::

  $ module -D load foo 2> load.log

The ``-D`` option turns on the debug printing and will report all the
steps that Lmod took to load a module called ``foo``.  Note that the
configuration report is at the top of every debug output.

Steps to report a bug
~~~~~~~~~~~~~~~~~~~~~

#. Test your bug against the latest release from github. Please pull
   the HEAD branch.
#. Try to reduce the problem to the fewest number of modules.  Try 
   for 1 or 2 modulefiles if you can.
#. Run the command that fails.  i.e. ``module -D`` `cmd modulefile ...` 2> ``lmod.log``
#. Combine the lmod.log file, the modulefiles from step 2, and possibly
   the spider cache file into a tar file.
#. Send general questions to the Lmod mailing list. You can join the
   mailing list here: https://sourceforge.net/projects/lmod/lists/lmod-users
#. Or bug reports as an issue at https://github.com/TACC/Lmod/issues 
#. Include the tar file generated above to either location.  Note that
   size of tar file is limited on the mailing so try to keep the tar
   files as small as possible.
