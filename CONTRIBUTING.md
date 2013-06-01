How to contribute
-----------------

To develop and contribute to this module you will need to follow the Openstack Gerrit workflow.  This module and Stackforge in general is on Github for the convenience of forking, cloning, and storing your work in progress.  Issues and pull requests initiated towards the Stackforge repositories will either be deleted or ignored.

1.  Read the Openstack wiki document on the Gerrit workflow: https://wiki.openstack.org/wiki/Gerrit_Workflow
  * First primary goal in reading this document is getting an Openstack Launchpad account setup and assigning the SSH public key you will be using to interact with Gerrit's Git server.
  * Your default SSH public key or the one you use for Github should be fine to reuse.
  * After getting your accounts straightened away the next goal is having `git-review` installed.

2.  Fork stackforge/puppet-openstack on Github.

3.  Clone repository.

    example% mkdir ~/src && cd ~/src
    example% git clone git@github.com:your_github_user/puppet-openstack.git
    example% cd puppet-openstack

4.  Make sure you have the Gerrit specific commit-msg hook that adds change-id to your commit message.

    example% curl https://review.openstack.org/tools/hooks/commit-msg > .git/hooks/commit-msg
    example% chmod +x .git/hooks/commit-msg

5.  Branch and checkout local repository.

    example% git checkout -b my_new_branch

6.  Do work on new branch.

7.  Run tests.
  * It is recommended that you run both the unit tests and do an actual run of the new state of the module by building a fresh instance of openstack.
  * To run all the tests shipped with the openstack module.  Includes all rspec-puppet tests that are used to test Puppet catalog compilation and regular rspec tests used to test the ruby code that makes up the types and providers.

    example% gem install puppetlabs_spec_helper
    example% rspec spec

  * To test an actual build of openstack you can use the [puppet-openstack_dev_env](https://github.com/stackforge/puppet-openstack_dev_env) project, also found on Stackforge (Requires Vagrant and Virtualbox).  Once you have the repository cloned local you can branch the repository and edit the Puppetfile's module source for openstack before you run the `librarian-puppet install` command.

8.  Once your happy with your work, commit and squash any WIP commits.

9.  Issue the `git review` command and submit your changes to Gerrit for review.
  * Each commit will be submitted as a distictly seperate change to Gerrit, available for review.
  * If all changes are part of the same branch then they are treated as dependants, chronologically.  This forcing all changes to be approved before a merge can occur.
