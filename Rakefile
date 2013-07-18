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
