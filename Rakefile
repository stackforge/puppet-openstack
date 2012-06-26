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

namespace :github do
  desc 'check all dependeny projects and generate a report about open pull requests'
  task 'pull_request_stats' do
    require 'net/https'
    require 'uri'
    require 'puppet'
    repo_hash = YAML.load_file(File.join(File.dirname(__FILE__), repo_file))
    (repo_hash['repos'] || {})['repo_paths'].keys.each do |url|
      if url =~ /\w+:\/\/github\.com\/(\S+)?\/(\S+)/
        uri = URI.parse("https://api.github.com/repos/#{$1}/#{$2}/pulls")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        pull_requests = PSON.parse(response.body).size
        puts "repo: #{$1}-#{$2}=#{pull_requests}"
      else
        puts "repo: #{url} does not seem to be valid"
      end
    end
  end
end
