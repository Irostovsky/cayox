require 'capistrano/ext/multistage'

set :application, "cayox"
set :repository,  "https://svn.moasesolutions.com/svn/Cayox/trunk/CayoxClouds"

set :deploy_via,            :remote_cache
set :repository_cache,      "#{application}-src"
set :ssh_options,           :forward_agent => true
set :use_sudo,              false

# comment out if it gives you trouble. newest net/ssh needs this set.
ssh_options[:paranoid] = false

set :merb_environment, ENV["MERB_ENV"] || "production"
set :migrate_env, "MERB_ENV=#{merb_environment}"

after "deploy:finalize_update", "symlink:database_yml"
after "deploy:finalize_update", "symlink:local_config"

namespace :symlink do
  task :database_yml, :roles => :app do
    run "ln -s #{shared_path}/database.yml #{latest_release}/config/database.yml"
  end
  task :local_config, :roles => :app do
    run "ln -s #{shared_path}/local_config.rb #{latest_release}/config/local_config.rb"
  end
end
