# site-cookbooks/catalog/recipes/requirements.rb
#
# This recipe is pretty basic, but it gets a huge part of the setup done.
# That last iteration runs an array of recipies. If there are settings you want to change, 
# you can most likely do that in the attibutes/default.rb file.For example,
# if you want Jetty to run on port 8080, you change the default.jetty.port variable. 
# 
# I think it's pretty straighforward.

# this loops install our default packages that we defined in our attirubtes/default.rb .
node.packages.each do |pkg|
  package pkg
end


# and here are all base recipes we'll run. most of the configuration for these take place 
# in attributes/default.rb file
%w(   user::data_bag homesick::data_bag openssh fail2ban java nginx ).each { |recipe| include_recipe recipe }