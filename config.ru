require 'rubygems'
require 'merb-core'
require 'data_objects'

Merb::Config.setup(
  :merb_root   => File.expand_path(File.dirname(__FILE__)),
  :environment => ENV['RACK_ENV']
)

#p "***Starting with configuration #{Merb::Config} "

Merb.environment = Merb::Config[:environment]
Merb.root = Merb::Config[:merb_root]
Merb::BootLoader.run

# Pass Application object created by Merb Bootloading if available
run (Merb::Config.app.nil? ? Merb::Rack::Application.new : Merb::Config.app)
