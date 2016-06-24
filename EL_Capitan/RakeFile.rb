

		$pwd = ""
		$current_path = ""

		task :setup_aadhi do
			system_or_exit('gem install bundler')
			system_or_exit('rbenv rehash')
			$current_path = Dir.getwd
			find_or_install_ruby_manager_and_ruby_version
			$pwd = getpwd
			find_or_remove_aadhi
			clone_aadhi_server
			set_ruby_version_and_gemset
			install_gems_and_mysql
			give_permissions
			configure_apache
			start_aadhi
		end

		def start_aadhi
			system_or_exit("sudo apachectl -k restart")
			system_or_exit("open http://localhost")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /var/www/aadhi/tmp")
			system_or_exit("open http://localhost")		
		end

		def configure_apache
            Dir.chdir($current_path)
			system_or_exit("echo #{$pwd} | sudo -S cp -f httpd-vhosts.conf /private/etc/apache2/extra/")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /private/etc/apache2/")			
			ruby_manager = find_current_ruby_manager
			update_apache_config_for_rvm_rbenv(ruby_manager)

		end


		def update_apache_config_for_rvm_rbenv(ruby_manager)
			Dir.chdir($current_path) do
						system_or_exit("sudo cp -f httpd_#{ruby_manager}.conf /private/etc/apache2/")
					end
			Dir.chdir('/private/etc/apache2/')
			system_or_exit("echo #{$pwd} | sudo -S  mv httpd_#{ruby_manager}.conf httpd.conf")
			system_or_exit("echo #{$pwd} | sudo -S  chmod -R 777 httpd.conf")
			user = Etc.getlogin
			replace_string(['/private/etc/apache2/httpd.conf'],'<user_name>', user)

			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /private/etc/apache2/extra/")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /private/etc/apache2/extra/httpd-vhosts.conf")
	
			Dir.chdir($current_path) do
				system_or_exit("echo #{$pwd} | sudo -S  cp -f httpd-vhosts-#{ruby_manager}.conf /private/etc/apache2/extra/")
			end
			Dir.chdir('/private/etc/apache2/extra')
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /private/etc/apache2/extra/")		
			system_or_exit("echo #{$pwd} | sudo -S  mv httpd-vhosts-#{ruby_manager}.conf httpd-vhosts.conf")
			replace_string(['/private/etc/apache2/extra/httpd-vhosts.conf'],'<user_name>', user)
		end

		def give_permissions

			Dir.chdir("/var/www/aadhi")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /var/www/aadhi")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /var/www/aadhi/public/assets")
			system_or_exit("rails s -d")
			system_or_exit("open http://localhost:3000")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /var/www/aadhi/tmp")

		end

		def set_ruby_version_and_gemset
			Dir.chdir("/var/www/aadhi/")
			system_or_exit("echo #{$pwd} | sudo -S touch .ruby-version")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 7777 .ruby-version")
			system_or_exit("echo #{$pwd} | sudo -S touch .ruby-gemset")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 7777 .ruby-gemset")
			ruby_manager = find_current_ruby_manager
			case ruby_manager
				when 'rbenv'
					system_or_exit("echo '2.2.0' >> .ruby-version")
					system_or_exit("echo 'aadhi' >> .ruby-gemset")
				when 'rvm'
					system_or_exit("echo '2.2.0' >> .ruby-version")
					system_or_exit("echo 'aadhi' >> .ruby-gemset")
			end
			system_or_exit("gem install bundler")
		end

		def install_gems_and_mysql
			Dir.chdir("/var/www/aadhi/")
			system_or_exit('rbenv version')
			system_or_exit("bundle install")
			system_or_exit('rbenv version')
			system_or_exit("rbenv rehash")
			system_or_exit("brew install mysql")
			system_or_exit("mysql.server start")
			system_or_exit("mysql_secure_installation")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /var/www/aadhi/db")
			system_or_exit('passenger-install-apache2-module')
		end

		def clone_aadhi_server
			Dir.chdir("/var/")
			system_or_exit("echo #{$pwd} | sudo -S mkdir www")
			Dir.chdir("/var/www/")
			system_or_exit("echo #{$pwd} | sudo -S chmod -R 777 /var/www/")
			Dir.chdir($current_path)
			system_or_exit('sh proxy_setup.sh')
		end

		def find_or_remove_aadhi
			system_or_exit("cd /var")
			if File.exists? File.expand_path('/var/www')
				puts "It seems you have already installed the Aadhi server in your machine. Hence removing old Aadhi server installation"
				system_or_exit("echo #{$pwd}| sudo -S rm -rf /var/www")
			end	
		end

		def getpwd
			pwd = `read -s -p "Password: " password; echo $password`.chomp
		end

		def find_or_install_ruby_manager_and_ruby_version
			ruby_manager = find_current_ruby_manager
			case ruby_manager
				when 'rbenv'
					find_or_install_ruby_version(ruby_manager)
				when 'rvm'
					find_or_install_ruby_version(ruby_manager) 
			end
		end

		def find_current_ruby_manager
			begin
				ruby_manager = `which ruby`
				if ruby_manager.include?(".rvm")
					return "rvm"
				elsif ruby_manager.include?(".rbenv")
					system_or_exit("brew install rbenv-gemset")
					return "rbenv"
				else
					puts "No ruby manager found!!!"
					exit(1)
				end
			end
		end

		def find_or_install_ruby_version(ruby_manager)
			case ruby_manager
				when "rbenv"
                   ruby_version = `ruby -r bundler -e "puts RUBY_VERSION"`
                   ruby_version = ruby_version.strip!
                   if ruby_version=="2.2.0"
                   	  puts "Expected ruby version found on this machine!!!"
                   else
                   	  ruby_versions = `rbenv versions`
                   	  if ruby_versions.include?('2.2.0')
                   	  	  system_or_exit('rbenv global 2.2.0')
                   	 	  puts "Expected ruby version found on this machine!!!"
                   	  else
                   	  	system_or_exit("rbenv install 2.2.0")
                   	  	system_or_exit('rbenv global 2.2.0')
                   	  end
                   end
                   system_or_exit("rbenv-gemset create 2.2.0 aadhi")
				when "rvm"
					ruby_version = `ruby -r bundler -e "puts RUBY_VERSION"`
					if ruby_version=="2.2.0"
						puts "Expected ruby version found on this version!!!"
					else
						system_or_exit("rvm install 2.2.0")
					end
					system_or_exit("rvm use 2.2.0")
					system_or_exit("rvm gemset create aadhi")
			end
		end


		def system_or_exit(cmd)
  			#puts "Run: #{cmd}"
  			unless system(cmd)
   				 puts "Run command failed. Exiting."
   				 exit(1)
  			end
		end

		def replace_string(list_of_files, source_string, replace_string)
			file_names = list_of_files
			file_names.each do |file_name|
				text = File.read(file_name)
				new_contents = text.gsub(source_string, replace_string) 	
				File.open(file_name, "w") {|file| file.puts new_contents }
			end
		end

=begin
		desc "This rake task is used to Setup Aadhi server in local machines"
		task :setup_aadhi, :environment , :ruby_manager, :ruby_manager_version do |t, args|
			setup_scenario_server(args[:environment], args[:ruby_manager], args[:ruby_manager_version])
		end

		def setup_scenario_server(environment, ruby_manager, ruby_manager_version)
			system_command("gem install highline","Installing highline/import gem")
			current_path = Dir.getwd
			password = ask("Enter password: ") { |q| q.echo = false }
			system_command("cd /var", "cd /var")
			if File.exists? File.expand_path('/var/www')
				puts "It seems you have already installed the Aadhi server in your machine. Hence removing old Aadhi server installation"
				system_command("echo #{password}| sudo -S rm -rf /var/www", "Removing Aadhi server (sudo -S rm -rf /var/www)")
			end	
			setup_mysql
			install_gems(ruby_manager, password)
			clone_scenario_server(password, environment, current_path)
			give_permissions(password)
			configure_apache(ruby_manager, ruby_manager_version, password, current_path)
		end

		def clone_scenario_server(password, environment, path)

			Dir.chdir("/var/")
			system_command("echo #{password} | sudo -S mkdir www", "Creating root folder (sudo -S mkdir www)")
			Dir.chdir("/var/www/")
			system_command("echo #{password} | sudo -S chmod -R 777 /var/www/", "Giving access rights to root folder (sudo -S chmod -R 777 /var/www/)")
			Dir.chdir(path)
			system("**************Cloning Aadhi server******************")
			unless system('sh proxy_setup.sh')
					puts "There was an error while setting proxy"
					abort
			end
			Dir.chdir("/var/www/aadhi/")
			system_command("bundle install", "bundle install")
			system_command("echo #{password} | sudo -S chmod -R 777 /var/www/aadhi/db", "Giving write access to Aadhi server DB related files (chmod -R 777 /var/www/aadhi/db)")
			case environment
			when "d"
				system_command("rake db:drop db:create db:migrate RAILS_ENV=development", "Creating/Refershing the Database (rake db:drop db:create db:migrate RAILS_ENV=development)")
			when "p"
				system_command("rake db:drop db:create db:migrate RAILS_ENV=production", "Creating/Refershing the Database (rake db:drop db:create db:migrate RAILS_ENV=production)")
				system_command("echo #{password} | sudo -S rvmsudo rake assets:precompile", "precompiling the static assets")
			end

		end

		def give_permissions(password)

			Dir.chdir("/var/www/aadhi")
			system_command("echo #{password} | sudo -S chmod -R 777 /var/www/aadhi", "chmod -R 777 /var/www/aadhi")
			system_command("echo #{password} | sudo -S chmod -R 777 /var/www/aadhi/public/assets", "chmod -R 777 /var/www/aadhi/public/assets")
			system_command("rails s -d", "Starting rails server in deamon mode (rails s -d)")
			system_command("open http://localhost:3000", "Opening the Aadhi server in port 3000 (rails s -d)")
			system_command("echo #{password} | sudo -S chmod -R 777 /var/www/aadhi/tmp", "Giving permission to tmp folder (chmod -R 777 /var/www/aadhi/tmp)")

		end

		def install_gems(ruby_manager, password)

			system_command("gem install rails", "Installing rails (gem install rails)")
			system_command("gem install passenger", "Installing passenger (gem install passenger)")
			case ruby_manager 
			when "rbenv"
                system_command("rbenv rehash", "Doing rehash for rbenv")
                system_command("passenger-install-apache2-module", "Installing Apache 2 module (sudo -S rbenv passenger-install-apache2-module)")
			when "rvm"
			    system_command("echo #{password} | rvmsudo -S passenger-install-apache2-module", "Installing Apache 2 module (rvmsudo -S passenger-install-apache2-module)")
			end

		end

		def setup_mysql

			system_command("brew install mysql", "Installing mysql (brew install mysql)")
			system_command("mysql.server start", "Starting mysql server (mysql.server start)")
			system_command("mysql_secure_installation", "Setup mysql (mysql_secure_installation)")

		end

		def configure_apache(ruby_manager, ruby_manager_version, password, path)

			passenger_gem_with_version = `gem list | grep passenger`
			passenger_versions = passenger_gem_with_version.scan(/\(([^\)]+)\)/).last.first
			puts "Passenger version:"+passenger_versions
			passenger_version = passenger_versions.split(",").first
			puts "Latest passenger version:"+passenger_version
			user = Etc.getlogin
			system_command('echo #{password} | sudo -S cp -f httpd-vhosts.conf /private/etc/apache2/extra/', "Configuring Apache")
			system_command("echo #{password} | sudo -S chmod -R 777 /private/etc/apache2/", "")
			case ruby_manager
			when "rvm"
				Dir.chdir(path) do
					system_command('sudo cp -f httpd_rvm.conf /private/etc/apache2/',"")
				end
				Dir.chdir('/private/etc/apache2/')
				system_command('sudo mv httpd_rvm.conf httpd.conf',"")
				system_command("sudo chmod -R 777 httpd.conf", "")
				replace_string(['/private/etc/apache2/httpd.conf'],'<user_name>', user)
				replace_string(['/private/etc/apache2/httpd.conf'],'<version>', passenger_version)
				replace_string(['/private/etc/apache2/httpd.conf'],'<rvm_version>', ruby_manager_version)
			when "rbenv"
				system_command("echo #{password} | sudo -S chmod -R 777 /private/etc/apache2/httpd.conf", "")
				replace_string(['/private/etc/apache2/httpd.conf'],'#LoadModule ssl_module libexec/apache2/mod_ssl.so', 'LoadModule ssl_module libexec/apache2/mod_ssl.so')
				replace_string(['/private/etc/apache2/httpd.conf'],'#Include /private/etc/apache2/extra/httpd-vhosts.conf', 'Include /private/etc/apache2/extra/httpd-vhosts.conf')
			    puts "**********We need to manually edit the /private/etc/apache2/httpd.conf for rbenv***********"
			end
			
			system_command("echo #{password} | sudo -S chmod -R 777 /private/etc/apache2/extra/","")
			system_command("echo #{password} | sudo -S chmod -R 777 /private/etc/apache2/extra/httpd-vhosts.conf","")
			Dir.chdir(path) do
				system_command('sudo cp -f httpd-vhosts.conf /private/etc/apache2/extra/',"")
			end
			system_command("sudo apachectl -k restart", "Restarting the Apache server (sudo apachectl -k restart)")
			system_command("open http://localhost", "Opening the Aadhi server in browser")
			system_command("echo #{password} | sudo -S chmod -R 777 /var/www/aadhi/tmp", "Giving permission to tmp folder (chmod -R 777 /var/www/aadhi/tmp)")
			system_command("open http://localhost", "Opening the Aadhi server in browser")

		end

		def system_command(command, message)
			if message.length>0
				puts "*********************************"+message+"***************************************************"
			end
			unless system(command)
				puts "An error has been occurred while executing the command: "+message
				abort
			end
		end
	

		def replace_string(list_of_files, source_string, replace_string)
			file_names = list_of_files
			file_names.each do |file_name|
				text = File.read(file_name)
				new_contents = text.gsub(source_string, replace_string) 	
				File.open(file_name, "w") {|file| file.puts new_contents }
			end
		end
=end