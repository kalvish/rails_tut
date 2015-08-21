set_default(:mysql_host, "localhost")
#set_default(:mysql_user, "ubuntu")
set_default(:mysql_user) { application }
set_default(:mysql_password) { Capistrano::CLI.password_prompt "MySQL Root Password: " }
set_default(:mysql_app_password) { Capistrano::CLI.password_prompt "MySQL database Password: " }
set_default(:mysql_database) { "#{application}_production" }
#set_default(:mysql_database) { "rails_tut" }
set_default(:mysql_pid) { "/var/run/mysqld/mysqld.pid" }

namespace :mysql do
  desc "Install the latest stable release of MySQL."
  task :install, :roles => :db, :only => {:primary => true} do
    # Uncomment only if you plan to use sqlite
    # run "#{sudo} apt-get -y install sqlite3 libsqlite3-dev"
    run "#{sudo} apt-get -y install mysql-server" do |channel, stream, data|
      # prompts for mysql root password (when blue screen appears)
      channel.send_data("#{mysql_password}\n\r") if data =~ /password/
      channel.send_data("#{mysql_password}\n\r") if data =~ /password/
    end
  end
  after "deploy:install", "mysql:install"

  desc "Install mysql client libraries"
  task :install_clients do
    run "#{sudo} apt-get -y install mysql-client libmysqlclient-dev"
  end
  after "deploy:install", "mysql:install_clients"

  def run_mysql_cmd(cmd)
    run %Q{#{sudo} mysql -uroot -p#{mysql_password} -e \"#{cmd}"} do |channel, stream, data|
      if data =~ /^Enter password:/
        channel.send_data "#{mysql_password}\n"
      end
    end
  end

  desc "Create a database for this application."
  task :create_database, :roles => :db, :only => {:primary => true} do
    # run_mysql_cmd "DROP DATABASE IF EXISTS \\`#{mysql_database}\\`;"
    run_mysql_cmd "CREATE DATABASE IF NOT EXISTS \\`#{mysql_database}\\`;"
    run_mysql_cmd "GRANT ALL PRIVILEGES ON #{mysql_database}.* TO #{mysql_user}@'%' IDENTIFIED BY '#{mysql_app_password}';"
  end
  after "deploy:setup", "mysql:create_database"

  desc "Generate the database.yml configuration file."
  task :setup, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    template "mysql.yml.erb", "#{shared_path}/config/database.yml"
  end
  after "deploy:setup", "mysql:setup"

  desc "Symlink the database.yml file into latest release"
  task :symlink, :roles => :app do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
  after "deploy:finalize_update", "mysql:symlink"
end
