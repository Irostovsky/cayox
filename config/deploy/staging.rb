role :app, "cayox.llpdemo.com"
role :web, "cayox.llpdemo.com"
role :db,  "cayox.llpdemo.com", :primary => true

set :deploy_to, "/var/www/#{application}"
set :user, "rubydev"

set :keep_releases, 3

namespace :deploy do
  desc "stops application server"
  task :stop do
    run "sudo god stop cayox"
  end

  desc "starts application server"
  task :start do
    run "sudo god start cayox"
  end

  desc "restarts application server(s)"
  task :restart do
    run "sudo god restart cayox"
  end
end
