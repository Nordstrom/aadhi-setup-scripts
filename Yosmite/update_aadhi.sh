#!/bin/bash
CURRENT_PATH=`pwd`
curl http://localhost/features/export_all > stubs.xml

function update_aadhi 
{
	echo "***********************Updating Aadhi code base***********************"
	sh proxy_setup_update.sh
	cd /var/www/aadhi
	echo "***********************Recreating database tables*********************"
	rake db:drop db:create db:migrate
	cd $CURRENT_PATH
	unset http_proxy
	unset https_proxy
	echo "***********************Uploading stubs********************************"
	curl -F "upload[datafile]=@stubs.xml" http://localhost/features/upload_stubs
}

update_aadhi