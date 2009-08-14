namespace :cayox do
  desc "Activate all users"
  task :activate_users => :merb_env do
    users = User.all
    users.each do |user|
      if user.active?
        p "#{user.name} already activated!!!"
      else
        user.activate!
        p "#{user.name} activated successfully!!!"
      end
    end
  end
end