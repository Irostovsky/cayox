# Go to http://wiki.merbivore.com/pages/init-rb
 
require 'config/dependencies.rb'
 
use_orm :datamapper
use_test :rspec
use_template_engine :erb

Merb::Config.use do |c|
  c[:use_mutex] = false
  c[:session_store] = 'cookie'  # can also be 'memory', 'memcache', 'container', 'datamapper
  
  # cookie session store configuration
  c[:session_secret_key]  = 'd4adfa1af96c04e21cdf2111906b710371d80531'  # required for cookie session store
  c[:session_id_key] = '_cayox_session_id' # cookie session id key, defaults to "_session_id"
end
 
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
  require Merb.root / "config/local_config.rb"
  require Merb.root / 'lib/extensions.rb'
  require Merb.root / 'lib/i18n.rb'
  require Merb.root / 'lib/abstract_storage'
  require Merb.root / 'lib/stubs.rb'
  require 'ostruct'
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
  Merb::Plugins.config[:merb_recaptcha][:public_key] = Cayox::CONFIG[:recaptcha_public_key]
  Merb::Plugins.config[:merb_recaptcha][:private_key] = Cayox::CONFIG[:recaptcha_private_key]
  require Merb.root / "lib/xss_terminator.rb"
  require Merb.root / "lib/tags.rb"
end
