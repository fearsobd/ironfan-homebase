name             "rvm"
maintainer       "Fletcher Nichol"
maintainer_email "fnichol@nichol.ca"
license          "Apache 2.0"
description      "Installs and manages RVM. Includes several LWRPs."
long_description "Please refer to README.md (it's long)."
version          "0.7.0"

recipe "rvm",               "Includes all recipes"
recipe "rvm::system",       "Installs system-wide RVM"
recipe "rvm::vagrant",      "An optional recipe to help if running in a Vagrant virtual machine"
recipe "rvm::gem_package",  "An experimental recipe that patches the gem_package resource"

%w{ debian ubuntu suse centos redhat fedora }.each do |os|
  supports os
end

# if using jruby, java is required on system
recommends  "java"

attribute "rvm/default_ruby",
  :display_name => "Default ruby",
  :description => "The default ruby for RVM. If the RVM ruby is not installed, it will be built as a pre-requisite.",
  :default => "ruby-1.9.2-p180"

attribute "rvm/rubies",
  :display_name => "Installed RVM rubies",
  :description => "A list of RVM rubies to be built and installed. If this list is emptied then no rubies (not even the default) will be built and installed. The default is the an array containing the value of rvm/default_ruby.",
  :type => "array",
  :default => [ "node[:rvm][:default_ruby]" ]

attribute "rvm/install_rubies",
  :display_name => "Can enable or disable installation of a default ruby and additional rubies set attribute metadata.",
  :description => "Can enable or disable installation of a default ruby and additional rubies set attribute metadata. The primary use case for this attribute is when you don't want any rubies installed (but you want RVM installed).",
  :default => "true"

attribute "rvm/global_gems",
  :display_name => "Global gems to be installed in all RVM rubies",
  :description => "A list of gem hashes to be installed into the *global* gemset in each installed RVM ruby. The RVM global.gems files will be added to and all installed rubies will be iterated over to ensure full installation coverage.",
  :type => "array",
  :default => [ { :name => "bundler" } ]

attribute "rvm/gems",
  :display_name => "Hash of ruby/gemset gem manifests",
  :description => "A list of gem hashes to be installed into arbitrary RVM rubies and gemsets.",
  :type => "hash",
  :default => Hash.new

attribute "rvm/rvmrc",
  :display_name => "Hash of rvmrc options",
  :description => "A hash of system-wide `rvmrc` options. The key is the RVM setting name (in String or Symbol form) and the value is the desired setting value. See RVM documentation for rvmrc options.",
  :type => "hash",
  :default => Hash.new

attribute "rvm/branch",
  :display_name => "A specific git branch to use when installing system-wide.",
  :description => "A specific git branch to use when installing system-wide.",
  :default => "nil"

attribute "rvm/version",
  :display_name => "A specific tagged version to use when installing system-wide.",
  :description => "A specific tagged version to use when installing system-wide. This value is passed directly to the `rvm-installer` script and current valid values are: `head` (the default, last git commit), `latest` (last tagged release version) and a specific tagged version of the form `1.2.3`. You may want to use a specific version of RVM to prevent differences in deployment from one day to the next (RVM head moves pretty darn quickly).",
  :default => "nil"

attribute "rvm/upgrade",
  :display_name => "How to handle updates to RVM framework",
  :description => "Determines how to handle installing updates to the RVM framework.",
  :default => "none"

attribute "rvm/root_path",
  :display_name => "RVM system-wide root path",
  :description => "Root path for system-wide RVM installation",
  :default => "/usr/local/rvm"

attribute "rvm/installer_url",
  :display_name => "The URL that provides the RVM installer.",
  :description => "The URL that provides the RVM installer.",
  :default => "http://rvm.beginrescueend.com/install/rvm"

attribute "rvm/group_users",
  :display_name => "Additional users in rvm group",
  :description => "Additional users in rvm group that can manage rvm in a system-wide installation.",
  :type => "array",
  :default => []

attribute "rvm/rvm_gem_options",
  :display_name => "These options are passed to the 'gem' command in a RVM environment.",
  :description => "These options are passed to the 'gem' command in a RVM environment. In the interest of speed, rdoc and ri docs will not be generated by default.",
  :default => "--no-rdoc --no-ri"

attribute "rvm/vagrant/system_chef_solo",
  :display_name => "If using the `vagrant` recipe, this sets the path to the package-installed `chef-solo` binary.",
  :description => "If using the `vagrant` recipe, this sets the path to the package-installed `chef-solo` binary.",
  :default => "/usr/bin/chef-solo"

attribute "rvm/gem_package/rvm_string",
  :display_name => "If using the `gem_package` recipe, this determines which ruby will be used by the `gem_package` resource in other cookbooks.",
  :description => "If using the `gem_package` recipe, this determines which ruby will be used by the `gem_package` resource in other cookbooks.",
  :default => "node[:rvm][:default_ruby]"
