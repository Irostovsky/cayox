namespace :cayox do

  desc "Send notification emails with proposed elements to topic owners/maintainers"
  task :send_proposed_elements_notifications => :merb_env do
    ElementProposition.send_notifications!
  end

  desc "Send notification emails with flagged topics and elements to topic owners"
  task :send_flagged_items_notifications => :merb_env do
    Flag.send_notifications!
  end

  desc "Clear old notifications"
  task :clear_old_notification => :merb_env do
    Notification.remove_old!
  end

  desc "Clear invalid notifications"
  task :clear_invalid_notification => :merb_env do
    Notification.remove_invalid!
  end
end