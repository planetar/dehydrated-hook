#!/bin/bash
#########################
# 
#
#  hook.sh for dhydrated in dns_01 mode for a domain with nameserver dns.he.net to be deployed on an octopi / octoprint installation with haproxy.
#
#  v 0.02  Berlin 2021-06-08 
#  Daniel Plaenitz
#
#  GPL v2
#
#  test it like: /var/lib/dehydrated/hook/hook.sh deploy_challenge octoprint.mydomain.net blabla abramacabra


## dehydrated calls the hook.sh sucsessively with one of the following valid hooks:

# startup_hook
#   currently nothing to do

# deploy_challenge
#   - build the appropriate URL, call it
#   - wait in a sleepy loop until the change appears to be applied

# clean_challenge
#   as dynamic text entries can not be created/deleted but have to exist already for the update to occurr
#   cleanup simply replaces the challenge with a friendly placeholder

# deploy_cert
#   this script is specifically tailored for an octoprint on octopi scenario
#   we will combine fullchain.pem and private key into a file written to /etc/haproxy/ssl with "$domain_combined.pem" as the filename


# exit_hook
#  ignored


## store the parameters into variables

progname=$0
hook=$1
domain=$2
token=$3
magicspell=$4


## when there's nothing to do, don't do it
if [[ "deploy_challenge clean_challenge deploy_cert" != *"$hook"*   ]]; then
	exit;
fi

## configuration

he_update_url="https://dyn.dns.he.net/nic/update"
password=""
# check and adapt the following settings
certs_path="/etc/dehydrated/certs"
domain_passwords="/etc/dehydrated/domain_passwords.txt"
destination_path="/etc/haproxy/ssl"

## read the domain/password table

while read aDomain aPassword aMarker; do
   if [[ $aDomain != \#* ]];then
	#echo "$aDomain $aPassword $aMarker"
	if [[ $aDomain == $domain ]]; then
		password=$aPassword;
		if [[ $aMarker == "yes"||$aMarker == "YES" ]]; then
			deployDomain=$aDomain;
		fi
	fi
  fi
done < $domain_passwords

echo "password for domain $domain is $password. "

if [[ $deployDomain == $domain  ]];then
	echo "$domain is the deployDomain, too"
fi




## hook deploy_challenge

if [ "${hook}" == "deploy_challenge" ]; then


	response=$(curl -k $he_update_url -d "hostname=_acme-challenge.$domain" -d "password=$password" -d "txt=$magicspell")

	#echo "curl -k $he_update_url -d \"hostname=_acme-challenge.$domain\" -d \"password=$password\" -d \"txt=$magicspell\" "
	echo "response: $response"

	# possible outcomes are: good nochg badauth
	if [[ $response == *"badauth"* ]]; then
		echo "Authorisation for _acme-challenge.$domain with password $password failed!"
		echo "URL was:"
		echo "curl -k $he_update_url -d \"hostname=_acme-challenge.$domain\" -d \"password=$password\" -d \"txt=$magicspell\" "
		exit 1
	fi


	cnt=0
	timeout=300

        # loop&sleep here until the new content of the challenge field is actually readable, this may take up to 5 minutes

	while :
	do
        echo "waiting..."

        sleep 1
        cnt=$(( $cnt+1 ))
        echo "$cnt loops"

        test_result=$(host -t txt _acme-challenge.$domain)
        echo "result: $test_result "


        if [[ $test_result == *"$magicspell"* ]]; then
        	echo "success!"
        	break;
        fi

        if (( $cnt > $timeout )); then
        	echo "FAIL! Timeout exceeded!"
        	exit 1;
        fi
        done

fi


## hook clean_challenge

if [ "${hook}" == "clean_challenge" ]; then
	# simply put a placeholder into the txt record
	curl -k $he_update_url -d "hostname=_acme-challenge.$domain" -d "password=$password" -d "txt=Acme challenge key"
fi


## hook deploy_cert

# deploy_cert if the current domain is the one
if [ "${hook}" == "deploy_cert" ]; then
   if [[ $deployDomain == $domain  ]];then

	# make sure the destination folder exists, then combine fullchain.pem and private key into one file and put it into the destination folder, reload
        mkdir -p /etc/haproxy/ssl
        cat $certs_path/$domain/fullchain.pem $certs_path/$domain/privkey.pem > $destination_path/$domain-combined.pem
        systemctl reload haproxy

   fi
fi
