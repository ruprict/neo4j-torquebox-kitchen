# site-cookbooks/catalog/recipes/default.rb

# This recipe is also installing a bunch of services, but these have to be configured 
# a little bit more than just setting attributes allows. 

# And secure it with iptables. Jetty will be fronted by nginx, so we only need http ports
include_recipe 'simple_iptables'
simple_iptables_policy 'INPUT' do
  policy 'DROP'
end

simple_iptables_rule "http" do
  rule [ "--proto tcp --dport 80",
         "--proto tcp --dport 443" ]
  jump "ACCEPT"
end
# Currently we don't need tp receive mail...
# simple_iptables_rule "mail" do
#   rule [ "-o eth0 -p tcp --sport 587 -m state --state NEW,ESTABLISHED",
#          "-o eth0 -p tcp --dport 587 -m state --state NEW,ESTABLISHED",
#          "-i eth0 -p tcp --sport 587 -m state --state ESTABLISHED"
#           ]
#   jump "ACCEPT"
# end

simple_iptables_rule 'system' do
  rule '-i lo'
  jump 'ACCEPT'
end
simple_iptables_rule 'system' do
  rule '-m conntrack --ctstate ESTABLISHED,RELATED'
  jump 'ACCEPT'
end
simple_iptables_rule 'system' do
  rule '-p icmp'
  jump 'ACCEPT'
end
simple_iptables_rule 'system' do
  rule '-p tcp --dport ssh'
  jump 'ACCEPT'
end

