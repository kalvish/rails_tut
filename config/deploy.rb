require "bundler/capistrano"

load "config/recipes/base"
load "config/recipes/nginx"
load "config/recipes/unicorn"
load "config/recipes/mysql"
load "config/recipes/nodejs"
load "config/recipes/rbenv"
load "config/recipes/check"

set :ssh_options, { keys: ["#{ENV['HOME']}/.ssh/fms_computer.pem"] }
server "52.26.212.188", :web, :app, :db, primary: true

set :user, "ubuntu"
set :application, "rails_tut"
set :deploy_to, "/home/#{user}/apps/#{application}"
set :deploy_via, :remote_cache
#set :use_sudo, false

set :scm, "git"
set :repository, "git@github.com:kalvish/#{application}.git"
set :branch, "master"

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy", "deploy:cleanup" # keep only the last 5 releases

after "deploy", "deploy:migrate"