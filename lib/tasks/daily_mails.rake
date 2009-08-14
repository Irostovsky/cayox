namespace :cayox do
  
  desc "Send daily notifications to topic owners about new pending users to losed user groups"
  task :daily_cug_notification => :merb_env do
     MembershipRequest.daily_notification
  end


end