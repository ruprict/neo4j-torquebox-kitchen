download_file = File.join("/tmp", File.basename(node.torquebox.download_url))

remote_file download_file do
  source  node.torquebox.download_url
  mode 00644
  action :create_if_missing
  notifies :run, "script[install-torquebox]", :immediately
end

script "install-torquebox" do
  Chef::Log.info("Installing torquebox zip file...")
  user 'torquebox'
  interpreter "bash"
  code <<-EOH
  unzip -o #{download_file} -d /opt/torquebox/
  ln -s /opt/torquebox/torquebox-2.3.2 /opt/torquebox/current
  EOH
  notifies :run, "execute[change ownership to torquebox]"
  not_if do
    File.exists? "/opt/torquebox/torquebox-2.3.2"
  end
  # not_if do
  #    File.exists? "/opt/torquebox/torquebox-2.2.0"
  #  end
  #action :nothing 
end


template "/etc/profile.d/torquebox.sh" do
  source "torquebox.sh.erb"
  mode 00644
  owner 'root'
  variables(
    :jboss_user =>  node[:torquebox_env][:jboss_user],
    :torquebox_home => node[:torquebox_env][:home],
    :jboss_pidfile => node[:torquebox_env][:jboss_pidfile],
    :jboss_console_log => node[:torquebox_env][:jboss_console_log],
    :jboss_config => node[:torquebox][:configuration_file],
    :jruby_opts => node[:torquebox_env][:jruby_opts],
    :java_environment_file => node[:java][:java_environment]
  )
  notifies :restart, "service[jboss-as-standalone]"
end


# install torquebox backstage
#
execute "change ownership to torquebox" do
  user "root"
  cwd "/opt"
  Chef::Log.info("changing ownership for torquebox")
  command "chown -Rv 1000.1000 /opt/torquebox"
  notifies :run, "script[install torquebox backstage]"
  action :nothing
end

script "install torquebox backstage" do
  Chef::Log.info("Installing torquebox backstage file...")
  interpreter "bash"
  user "torquebox"
  cwd "/opt/torquebox"
  code <<-EOH
  export TORQUEBOX_HOME=/opt/torquebox/torquebox-2.3.2
  export JAVA_HOME=/opt/jdk7/
  export JBOSS_HOME=$TORQUEBOX_HOME/jboss
  export JRUBY_HOME=$TORQUEBOX_HOME/jruby
  export PATH=$JBOSS_HOME/bin:$JRUBY_HOME/bin:$JAVA_HOME/bin:$PATH
  EOH
  # jruby -S gem install torquebox-backstage
  # jruby -S gem install ruby-shadow
  # jruby -S backstage deploy
  not_if do 
    File.exists? "/opt/torquebox/current/jruby/bin/backstage"
  end
end

directory '/opt/apps/' do
  owner "torquebox"
  group "torqubox"
  mode 00755
  action :create
  not_if do
    File.exists? "/opt/apps/"
  end
end

directory "/etc/jboss-as" do
  owner "root"
  group "root"
  mode 00755
  action :create
  not_if do
    File.exists? "/etc/jboss-as"
  end
end

directory "/var/log/jboss-as" do
  owner "torquebox"
  group "torquebox"
  mode 00755
  action :create
  not_if do
    File.exists? "/var/log/jboss-as"
  end
end

template "/etc/init.d/jboss-as-standalone" do 
  source "jboss-as-standalone.sh.erb"
  variables(:environment_file => node[:torquebox][:environment_file])
  mode 00755
  owner 'root'
  notifies :restart, "service[jboss-as-standalone]"
end


service "jboss-as-standalone" do
  supports :status => true, :restart => true, :stop => true, :start => true
  action [ :enable, :start ]
end

#if clustered then if cluster name is staging_cluster, so proxy name will be staging_cluster_proxy
#so for every cookbook, it should be paired with two of them
proxy_nodes = []
clustered_nodes = []

Chef::Log.warn("clustered status #{node[:torquebox][:clustered]}")
if node[:torquebox][:clustered]
  clustered_nodes =  search(:node, "roles:#{node[:torquebox][:cluster_name]}")
  proxy_nodes = search(:node, "roles:#{node[:torquebox][:cluster_name]}_proxy")

  template "/opt/torquebox/current/jboss/standalone/configuration/standalone-ha.xml" do
    source "standalone-ha.xml.erb"
    variables(:node_name => node.name, :node_ipaddress => node.ipaddress, :cluster_name => node[:torquebox][:cluster_name], :clustered_nodes => clustered_nodes, :proxy_nodes => proxy_nodes )
    mode "0644"
    notifies :restart, "service[jboss-as-standalone]"
  end
end

if proxy_nodes.count == 0 and node[:torquebox][:clustered] == true
  Chef::Log.warn("There is no proxy defined, cluster may not function")
end

if !node[:torquebox][:clustered]
  template "/opt/torquebox/current/jboss/standalone/configuration/standalone.xml" do
    source "standalone.xml.erb"
    variables(:node_name => node.name, :node_ipaddress => node.ipaddress)
    mode "0644"
    notifies :restart, "service[jboss-as-standalone]"
  end
end

template "/opt/torquebox/current/jboss/bin/standalone.conf" do 
  source "standalone.conf.erb"
  mode "00644"
  owner 'torquebox'
  variables(:jboss_config => node[:torquebox][:configuration_file])
  notifies :restart, "service[jboss-as-standalone]"
end

cookbook_file "/etc/jboss-as/jboss-as.conf" do 
  source "jboss-as.conf"
  mode 00644
  owner 'root'
end


# NGINX!

# this enables our site, kinda like a2ensite
execute 'enable-site' do
  command "ln -sf /etc/nginx/sites-available/#{node[:server_name]} /etc/nginx/sites-enabled/#{node[:server_name]}"
  notifies :restart, 'service[nginx]'
end

# Our configuration template. Take a look at templates/nginx.conf.erb to see what's going on. 
template "/etc/nginx/sites-available/#{node[:server_name]}" do
  source 'nginx.erb'
  owner 'root'
  group 'root'
  mode 0644
  notifies :run, "execute[enable-site]", :immediately
  variables(
     server_name: node.server_name
   )
end

service 'nginx' 
service 'jboss-as-standalone'

