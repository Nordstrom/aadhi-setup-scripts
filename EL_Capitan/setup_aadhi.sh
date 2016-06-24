#!/bin/bash

USER=`whoami`
CURRENT_PATH=`pwd`
echo Password: 
read -s PASSWORD
gem install bundler
rbenv rehash
RUBY_VERSION=""
RUBY_MANAGER=`which ruby`


function install_rvm_or_rbenv
{
  echo "*******************************Installing rvm or rbenv********************************"
  if [[ $RUBY_MANAGER == *".rbenv"* ]]
    then
      RUBY_VERSION=`rbenv versions`
      RUBY_MANAGER="rbenv"
      brew install rbenv-gemset
    elif [[ $RUBY_MANAGER == *".rvm"* ]]
    then
      RUBY_VERSION=`rvm list`
      RUBY_MANAGER="rvm"
    else
      echo "Please install rvm or rbenv in your machine!!!"
      exit 1
  fi

  if [[ $RUBY_MANAGER == "rbenv" ]]
    then
        if [[ $RUBY_VERSION == *"2.2.3"* ]]
          then
           echo "Expected ruby version found!!!"
           #rbenv global 2.2.0            
           rbenv-gemset create 2.2.3 aadhi
        else
           rbenv install 2.2.3
           #rbenv global 2.2.0            
           rbenv-gemset create 2.2.3 aadhi
        fi
  elif [[ $RUBY_MANAGER == "rvm" ]]
  then
       if [[$RUBY_VERSION == *"2.2.0"*]]
          then
           echo "Expected ruby version found!!!"
           rvm use 2.2.0
           rvm gemset create aadhi
        else
          rvm install 2.2.0
          rvm use 2.2.0
          rvm gemset create aadhi
        fi
  fi 
}
        
function clone_and_install_aadhi
{
  echo "********************************Cloning and Installing Aadhi******************************"
  if [ -d "/var/www/aadhi" ]; then
    echo "$PASSWORD" | sudo -S rm -rf /var/www
    cd /var/
    echo "$PASSWORD" | sudo -S mkdir www
  elif [ ! -d "/var/www/aadhi" ]; then
    cd /var/
    echo "$PASSWORD" | sudo -S mkdir www
  fi
  cd $CURRENT_PATH
  echo "$PASSWORD" | sudo -S chmod -R 777 /var/www
  sh proxy_setup_install.sh
  cd /var/www/aadhi
  echo "$PASSWORD" | sudo -S touch .ruby-version
  echo "$PASSWORD" | sudo -S chmod -R 7777 .ruby-version
  echo "$PASSWORD" | sudo -S touch .ruby-gemset
  echo "$PASSWORD" | sudo -S chmod -R 7777 .ruby-gemset
  echo "$PASSWORD" | sudo -S echo '2.2.3' >> .ruby-version
  echo "$PASSWORD" | sudo -S echo 'aadhi' >> .ruby-gemset
  gem install bundler
  brew install mysql
  gem install mysql -v 2.9.1
  bundle install
  rbenv rehash
}

function install_and_setup_mysql
{
  echo "********************************Creating DB*****************************"
  mysql.server start
  mysql_secure_installation
  echo "$PASSWORD" | sudo -S chmod -R 777 /var/www/aadhi/db
  rake db:drop db:create db:migrate RAILS_ENV=development
}

function install_apache_module
{
  echo "********************************Installing apache2 module*************************************"
  brew link openssl --force
  brew install passenger
}

function give_permission_to_aadhi_folders
{
  echo "********************************Giving write access to aadhi's folders************************"
  echo "$PASSWORD" | sudo -S chmod -R 777 /var/www/aadhi
  echo "$PASSWORD" | sudo -S chmod -R 777 /var/www/aadhi/public/assets
}

function configure_apache
{
  echo "********************************Configuring Apache********************************************"
  cd $CURRENT_PATH
  sudo cp -f "httpd_$RUBY_MANAGER.conf" /private/etc/apache2/
  sudo cp -f "passenger.conf" /private/etc/apache2/other/
  cd /private/etc/apache2/
  echo "$PASSWORD" | sudo -S  mv "httpd_$RUBY_MANAGER.conf" httpd.conf
  echo "$PASSWORD" | sudo -S  chmod -R 777 httpd.conf
  echo "$PASSWORD" | sudo -S sed -i -e "s/<user_name>/$USER/g" /private/etc/apache2/httpd.conf
  echo "$PASSWORD" | sudo -S chmod -R 777 /private/etc/apache2/extra/
  echo "$PASSWORD" | sudo -S chmod -R 777 /private/etc/apache2/extra/httpd-vhosts.conf
  cd $CURRENT_PATH
  echo "$PASSWORD" | sudo -S  cp -f "httpd-vhosts-$RUBY_MANAGER.conf" /private/etc/apache2/extra/
  cd /private/etc/apache2/extra
  echo "$PASSWORD" | sudo -S chmod -R 777 /private/etc/apache2/extra/ 
  echo "$PASSWORD" | sudo -S  mv "httpd-vhosts-$RUBY_MANAGER.conf" httpd-vhosts.conf
  echo "$PASSWORD" | sudo -S sed -i -e "s/<user_name>/$USER/g" /private/etc/apache2/extra/httpd-vhosts.conf
  cd /private/etc/apache2/other/
  echo "$PASSWORD" | sudo -S chmod -R 777 /private/etc/apache2/other/ 
  echo "$PASSWORD" | sudo -S sed -i -e "s/<user_name>/$USER/g" /private/etc/apache2/other/passenger.conf
  brew info passenger
  sudo /usr/local/bin/passenger-config validate-install
  sudo apachectl -k restart
  open http://localhost
  sleep 5
  echo "$PASSWORD" | sudo -S chmod -R 777 /var/www/aadhi/tmp
  sudo apachectl -k restart
  open http://localhost
}

install_rvm_or_rbenv
clone_and_install_aadhi
install_and_setup_mysql
install_apache_module
give_permission_to_aadhi_folders
configure_apache

