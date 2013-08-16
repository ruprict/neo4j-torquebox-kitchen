# site-cookbooks/catalog/attributes/default.rb. 

#
# This is a big long boring list of attributes that the recipes will use. 
# To find all the options that are available to you, you'll have to look at the recipe's documentation. 
# If you're following along at home, make this file and paste in the values you see from Github. 
# We'll be coming back to these as we run through our recipes.
#


# sets the ruby version to be installed by RVM. note that I'm making a gemset for the rails application. 


# some default packages we want to install
default.packages = %w(vim git tmux openssl xinetd nullmailer zip unzip)

# Users
default.users = ['torquebox']
default.user.ssh_keygen = false

# SSH 
#default.openssh.server.permit_root_login = 'yes'
#default.openssh.server.password_authentication = 'no'
#default.openssh.server.allow_groups = ['sudo', 'torquebox']
#default.openssh.server.login_grace_time = '30'
##default.openssh.server.use_p_a_m = 'no'
#default.openssh.server.print_motd = 'no'



# TORQUEBOX DEFAULTS
default[:torquebox][:download_url] = "http://repository-torquebox.forge.cloudbees.com/release/org/torquebox/torquebox-dist/2.3.2/torquebox-dist-2.3.2-bin.zip"
default[:torquebox][:clustered] = false
default[:torquebox][:cluster_name] = "torquebox_staging"
default[:torquebox][:role] = "toruqebox_staging"
default[:torquebox][:configuration_file] = "standalone.xml"
default[:torquebox][:environment_file] = "/etc/profile.d/torquebox.sh"

default[:torquebox_env][:jboss_user] = "torquebox"
default[:torquebox_env][:home] = "/opt/torquebox/current"
default[:torquebox_env][:user_home] = "/opt/torquebox"
default[:torquebox_env][:jboss_pidfile] = "/var/run/torquebox/torquebox.pid"
default[:torquebox_env][:jboss_console_log] = "/var/log/jboss-as/console.log"
default[:torquebox_env][:jruby_home] = "#{default[:torquebox_env][:home]}/jruby"
default[:torquebox_env][:jboss_home] = "#{default[:torquebox_env][:home]}/jboss"
default[:torquebox_env][:jruby_opts] = "--1.9"

