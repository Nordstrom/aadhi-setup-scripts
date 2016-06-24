
__Step 1:__ Install rbenv and rbenv-gemset using the below command

          brew install rbenv
          brew install ruby-buld
          brew install rbenv-gemset
           
__Step 2:__ Run the below command to add rbenv to $PATH

          echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
          echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
          
__Step 3:__ reload bash profile

           . ~/.bash_profile 
           
(dot space ~/profile)

__Step 4:__ Install latest ruby version using rbenv. The below command will take around 5mins to install the specified ruby version

            rbenv install 2.2.3
            
__Step 5:__ Set the global version of Ruby to be used in all shells by writing the version name to the ~/.rbenv/version file. This version can be overridden by an application-specific .ruby-version file, or by setting the RBENV_VERSION environment variable.

            rbenv global 2.2.3


 __Aadhi:__
 
__Step 1:__ Install rbenv(follow the above mentioned steps)

__Step 2:__ Clone - git clone https://github.com/gkexplore/AadhiSetup.git

__Step 3:__ Navigate to AadhiSetup and run -> sh setup_aadhi.sh (add proxy settings in proxy_setup.sh file if it is required to clone github projects)

__Step 4:__ Navigate through the mysql setup.
When prompted, please use the below steps to guide you to setting up mysql server db. 
To set root password, run

          mysql_secure_installation
            Would you like to setup VALIDATE PASSWORD plugin? - Type no
            Enter current password for root (enter for none): If you have already setup mysql and aadhi, type auto@123, otherwise simply press enter
            Set root password? [Y/n]  - Type Y if you have simply pressed enter in above step
            New password: auto@123
            Re-enter new password: auto@123
            Password updated successfully!
            Remove anonymous users? [Y/n] - type n
            Disallow root login remotely? [Y/n] - type n
            Remove test database and access to it? [Y/n] - type n
            Reload privilege tables now? [Y/n] - type n
 
Simply press enter whenever you get prompt after mysql setup. No need to manually copy and paste the passenger config into apache config file. The shell script will take care of it.
