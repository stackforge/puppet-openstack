#
# Rakefile to make management of module easier (I hope :) )
#
# I did not do this in puppet b/c it requires the vcsrepo!!
#
#

require 'puppet'

repo_file = 'other_repos.yaml' 

namespace :modules do
  desc 'clone all required modules'
  task :clone do
    repo_hash = YAML.load_file(File.join(File.dirname(__FILE__), repo_file))
    repos = (repo_hash['repos'] || {})
    repos_to_clone = (repos['repo_paths'] || {})
    branches_to_checkout = (repos['checkout_branches'] || {})
    repos_to_clone.each do |remote, local|
      # I should check to see if the file is there?
      output = `git clone #{remote} #{local}`
      Puppet.debug(output)
    end
    branches_to_checkout.each do |local, branch|
      Dir.chdir(local) do
        output = `git checkout #{branch}`
      end
      # Puppet.debug(output)
    end
  end

  desc 'see if any of the modules are not up-to-date'
  task 'status' do
    repo_hash = YAML.load_file(File.join(File.dirname(__FILE__), repo_file))
    repos = (repo_hash['repos'] || {})
    repos_to_clone = (repos['repo_paths'] || {})
    branches_to_checkout = (repos['checkout_branches'] || {})
    repos_to_clone.each do |remote, local|
      # I should check to see if the file is there?
      Dir.chdir(local) do
        puts "Checking status of #{local}"
        puts `git status`
      end
    end
  end
end 
