role :app, "cayox.com"
role :web, "cayox.com"
role :db,  "cayox.com", :primary => true

set :deploy_to, "/some/path/to/#{application}"
set :user, "someusername"
#set :password, "is_the_merbist" # you probably don't want your password here tho

set :keep_releases, 5

set :merb_adapter,     "mongrel"
set :merb_port,        5000
set :merb_servers,     3

namespace :deploy do
  desc "stops application server"
  task :stop do
    run "cd #{latest_release}; merb -K all"
  end

  desc "starts application server"
  task :start do
    run "cd #{latest_release}; bin/merb -a #{merb_adapter} -p #{merb_port} -c #{merb_servers} -d -e #{merb_environment}"
    # Mutex of: -X off
  end

  desc "restarts application server(s)"
  task :restart do
    deploy.stop
    deploy.start
  end
end