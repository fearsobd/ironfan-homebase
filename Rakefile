#
# Rakefile for Chef Server Repository
#
# Author::    Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
# License::   Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rubygems' unless defined?(Gem)
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'chef'
require 'json'
# require 'rspec'
# require 'rspec/core/rake_task'
require 'yard'
require 'git'

def find_current_branch
  Git.open('.').branches.to_s[%r/\* (.*)/,1]
end

# Load constants from rake config file.
$LOAD_PATH.unshift('tasks')
Dir[File.join('tasks', '*.rake')].sort.each{|f| load(f) }

# ---------------------------------------------------------------------------
#
# Chef tasks
#
# Load common, useful tasks from Chef.
# rake -T to see the tasks this loads.
#

# # Detect the version control system and assign to $vcs. Used by the update
# # task in chef_repo.rake (below). The install task calls update, so this
# # is run whenever the repo is installed.
# #
# # Comment out these lines to skip the update.
# if File.directory?(File.join(TOPDIR, ".svn"))
#   $vcs = :svn
# elsif File.directory?(File.join(TOPDIR, ".git"))
#   $vcs = :git
# end

load 'chef/tasks/chef_repo.rake'

#
# Berkshelf
#
desc "Install berkshelf cookbooks locally"
task :berkshelf do |t, args|
  system("bundle exec berks install --path cookbooks")
end

desc "Install berkshelf cookbooks and sync with Chef server"
task :berkshelf_install => [ :berkshelf, :upload_cookbooks_without_metadata ]
task(:upload_cookbooks_without_metadata) { system("knife cookbook upload --all") }

desc "Install berkshelf cookbooks and upload one to the Chef server"
task :berkshelf_upload => [ :berkshelf ]
task :berkshelf_upload, :cookbook do |t, args|
  system("knife cookbook upload #{args.cookbook}")
end

#
# Sync
# 
desc "Sync clusters with Chef and IaaS servers"
task :sync_clusters => FileList[File.join(TOPDIR, 'clusters', '*.rb')].pathmap('knife cluster sync %n')
rule(%r{knife cluster sync \S+\Z}) {|t| system(t.to_s) or raise "#{t} failed" }

desc "Sync current environment with Chef server"
task :sync_environment do
  environment = find_current_branch
  environment = 'development' if environment == 'master'
  command = "knife environment from file #{environment}.rb"
  system(command) or raise "#{command} failed"
end

desc "Sync everything (roles, environment, clusters, and cookbooks)"
task :full_sync => [ :roles, :sync_environment, :sync_clusters, :berkshelf_install ]

#
# Environments
#

desc "Initialize your staging environment"
task :initialize_staging do
  print "Initializing your staging environment will upload and freeze all versions currently in staging. Are you sure you want to continue? (y/n): "
  exit unless STDIN.gets.chomp.downcase == 'y'
  # FIXME: stash any changes
  g = Git.open('.')
  current = find_current_branch
  begin
    g.checkout('staging')
    Rake::Task[:sync_environment].invoke
    Rake::Task[:berkshelf].invoke
    system("knife cookbook upload --all --force --freeze")
    puts "Initialized the staging environment and cookbooks"
  ensure
    g.checkout(current)
  end
  # FIXME: unstash any changes
end

desc "Push the current staging environment to production"
task :push_to_production do
  # FIXME: stash any changes
  g = Git.open('.')
  current = find_current_branch
  begin
    g.checkout('staging')
    g.branch('production').checkout
    g.merge('origin/staging')
    g.push('origin','production')
    puts "Current staging has pushed to production"
  ensure
    g.checkout(current)
  end
  # FIXME: unstash any changes
end

#
# Other
# 
desc "Bundle a single cookbook for distribution"
task :bundle_cookbook => [ :metadata ]
task :bundle_cookbook, :cookbook do |t, args|
  tarball_name      = "#{args.cookbook}.tar.gz"
  temp_dir          = File.join(Dir.tmpdir, "chef-upload-cookbooks")
  temp_cookbook_dir = File.join(temp_dir, args.cookbook)
  tarball_dir       = File.join(TOPDIR, "pkgs")
  FileUtils.mkdir_p(tarball_dir)
  FileUtils.mkdir(temp_dir)
  FileUtils.mkdir(temp_cookbook_dir)
  child_folders = Dir[ "cookbooks/#{args.cookbook}", "*-cookbooks/#{args.cookbook}" ]
  child_folders.each do |folder|
    file_path = File.join(TOPDIR, folder, ".")
    FileUtils.cp_r(file_path, temp_cookbook_dir) if File.directory?(file_path)
  end
  system("tar", "-C", temp_dir, "-cvzf", File.join(tarball_dir, tarball_name), "./#{args.cookbook}")
  FileUtils.rm_rf temp_dir
end


desc "create a simple runit service template"
task :create_runit, :cookbook, :template_name do |t, args|
  cookbook           = args.cookbook
  template_name      = args.template_name || cookbook
  cookbook_roots     = Dir[ "cookbooks", "*-cookbooks" ]
  cookbook_dir       = cookbook_roots.map{|r| Dir[ "#{r}/#{args.cookbook}"] }.flatten.compact.last
  raise "Can't find cookbooks in #{cookbook_roots}" unless cookbook_dir
  #
  template_dir       = File.join(cookbook_dir, 'templates', 'default')
  sv_run_script_file = File.join(template_dir, "sv-#{template_name}-run.erb")
  sv_log_script_file = File.join(template_dir, "sv-#{template_name}-log-run.erb")
  #
  sv_log_script_text = %Q{\#!/bin/sh\nexec svlogd -tt <%= @options[:log_dir] %>}
  sv_run_script_text = %Q{#!/bin/bash
exec 2>&1
cd   <%= @options[:pid_dir] %>
exec chpst -u <%= @options[:user] %> /usr/sbin/#{template_name}
}
  FileUtils.mkdir_p(template_dir)
  if File.exists?(sv_run_script_file) || File.exists?(sv_log_script_file)
    warn "Files #{sv_run_script_file} and/or #{sv_log_script_file} exist -- remove them first"
    exit
  else
    File.open(sv_run_script_file, "w"){|f| f.puts sv_run_script_text }
    File.open(sv_log_script_file, "w"){|f| f.puts sv_log_script_text }
    puts "Created runit scripts #{sv_run_script_file} and #{sv_log_script_file}"
    puts "I bet you'll want to edit the run script, especially the path at the end of the last line"
  end
end

# ---------------------------------------------------------------------------
#
# RSpec -- testing
#
# RSpec::Core::RakeTask.new(:spec) do |spec|
#   spec.pattern = FileList['spec/**/*_spec.rb']
# end
#
# RSpec::Core::RakeTask.new(:rcov) do |spec|
#   spec.pattern = 'spec/**/*_spec.rb'
#   spec.rcov = true
#   spec.rcov_opts = %w[ --exclude .rvm --no-comments --text-summary]
# end

# ---------------------------------------------------------------------------
#
# Yard -- documentation
#
YARD::Rake::YardocTask.new

# ---------------------------------------------------------------------------

task :default => :spec
