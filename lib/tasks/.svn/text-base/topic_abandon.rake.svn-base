namespace :cayox do
  
  desc "Remove topics from system that was not adopted before the abandon time run out"
  task :clear_abandoned => :merb_env do
     Topic.clear_abandoned
  end


end