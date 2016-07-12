#!/bin/bash

USER=`whoami`
CURRENT_PATH=`pwd`
echo Password: 
read -s PASSWORD
rbenv rehash
RUBY_VERSION=""
RUBY_MANAGER=`which ruby`

function remove_aadhi
{
  echo "********************************Removing Aadhi from /var/www/aadhi******************************"
  if [ -d "/var/www/aadhi" ]; then
    echo "$PASSWORD" | sudo -S rm -rf /var/www
  elif [ ! -d "/var/www/aadhi" ]; then
    echo "No previous installation found!!!" 
  fi
}

function remove_aadhi_gemset
{
  echo "*******************************Removing aadhi gemset********************************"
  if [[ $RUBY_MANAGER == *".rbenv"* ]]
    then
      RUBY_VERSION=`rbenv versions`
      RUBY_MANAGER="rbenv"
    elif [[ $RUBY_MANAGER == *".rvm"* ]]
    then
      echo "It seems, Aadhi is not installed or already removed from your machine!!!"
    else
      echo "It seems, Aadhi is not installed or already removed from your machine!!!"
    exit 1
  fi

  if [[ $RUBY_MANAGER == "rbenv" ]]
    then
        if [[ $RUBY_VERSION == *"2.3.1"* ]]
          then       
           rbenv-gemset delete 2.3.1 aadhi
        fi
  fi 
}

function revert_apache_configuration
{
    echo "********************************Reverting apache configuration***************************"
    echo "$PASSWORD" | sudo -S cp -rf "/private/etc/apache2/original/httpd.conf" /private/etc/apache2/
    echo "$PASSWORD" | sudo -S cp -rf "/private/etc/apache2/original/extra/httpd-vhosts.conf" /private/etc/apache2/extra
}

remove_aadhi
remove_aadhi_gemset
revert_apache_configuration