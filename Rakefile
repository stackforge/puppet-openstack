#
# Rakefile to make management of module easier (I hope :) )
#
# I did not do this in puppet b/c it requires the vcsrepo!!
#
#

begin
  require 'yaml'
  require 'puppetlabs_spec_helper/rake_tasks'
rescue LoadError
  puts "!!!!!"
  puts "puppetlabs_spec_helper not found. This may cause some rake tasks to be unavailable."
  puts "!!!!!"
end

repo_file = 'other_repos.yaml'
default_modulepath = '/etc/puppet/modules'

namespace :modules do
  desc 'clone all required modules'
  task :clone do
    repo_hash = YAML.load_file(File.join(File.dirname(__FILE__), repo_file))
    repos = (repo_hash['repos'] || {})
    modulepath = (repo_hash['modulepath'] || default_modulepath)
    repos_to_clone = (repos['repo_paths'] || {})
    branches_to_checkout = (repos['checkout_branches'] || {})
    repos_to_clone.each do |remote, local|
      # I should check to see if the file is there?
      outpath = File.join(modulepath, local)
      output = `git clone #{remote} #{outpath}`
      puts output
    end
    branches_to_checkout.each do |local, branch|
      Dir.chdir(File.join(modulepath, local)) do
        output = `git checkout #{branch}`
      end
      # Puppet.debug(output)
    end
  end

  desc 'see if any of the modules are not up-to-date'
  task 'status' do
    repo_hash = YAML.load_file(File.join(File.dirname(__FILE__), repo_file))
    repos = (repo_hash['repos'] || {})
    modulepath = (repo_hash['modulepath'] || default_modulepath)
    repos_to_clone = (repos['repo_paths'] || {})
    branches_to_checkout = (repos['checkout_branches'] || {})
    repos_to_clone.each do |remote, local|
      # I should check to see if the file is there?
      Dir.chdir(File.join(modulepath, local)) do
        puts "Checking status of #{local}"
        puts `git status`
      end
    end
  end
end
