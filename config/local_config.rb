gem 'data_objects'
require 'data_objects'
require "rubygems"


module Cayox
  CONFIG = {}
end

# Cayox::CONFIG[:show_revision] = false

Cayox::CONFIG[:mail_from] = "cayox@localhost"
Cayox::CONFIG[:site_url] = "http://localhost:4000"

Cayox::CONFIG[:fallback_language_code] = "en"

Cayox::CONFIG[:search_results_per_page] = 10
Cayox::CONFIG[:elements_per_page] = 10
Cayox::CONFIG[:friends_per_page] = 10
Cayox::CONFIG[:roles_per_page] = 10
Cayox::CONFIG[:users_per_page] = 10

# add thummalizr api key here
# Cayox::CONFIG[:thumb_api_key]

Cayox::CONFIG[:abandon_time_span] = 7
Cayox::CONFIG[:max_notification_age] = 30 # in days

Cayox::CONFIG[:recaptcha_public_key] = "..."
Cayox::CONFIG[:recaptcha_private_key] = "..."

Cayox::CONFIG[:favourite_sync_interval] = 5 # minutes

Merb::Mailer.delivery_method = Merb.env == "production" ? :sendmail : :test_send



# Merb::Mailer.delivery_method = :net_smtp
# Merb::Mailer.config = {
#     :host   => 'smtp.gmail.com',
#     :port   => '587',
#     :user   => 'user',
#     :pass   => 'pass',
#     :auth   => :plain, # :plain, :login, :cram_md5, the default is no auth
#     :domain => "localhost.localdomain" # the HELO domain provided by the client to the server
#  }

