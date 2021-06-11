#!/bin/bash
#########################
#
#
#  hook.sh for dhydrated in dns_01 mode for a domain with nameserver dns.he.net to be deployed on an octopi / octoprint installation with haproxy.
#
#  v 0.02  Berlin 2021-06-08
#    0.03  less ugly messages while waiting
#          scriptlets_dir for drop-in functionality
#  Daniel Plaenitz
#
#  GPL v2
#
#  test it like: /var/lib/dehydrated/hook/hook.sh deploy_challenge octoprint.mydomain.net blabla abramacabra


## dehydrated calls the hook.sh sucsessively with one of the following valid hooks:

# startup_hook hook
#   call to scriptlets startup*.sh 

# deploy_challenge hook domain token challenge
#   - build the appropriate URL, call it
#   - wait in a sleepy loop until the change appears to be applied

# clean_challenge hook domain token challenge
#   as dynamic text entries can not be created/deleted but have to exist already for the update to occurr
#   cleanup simply replaces the challenge with a friendly placeholder

# deploy_cert hook domain privKey cert fullchain chain timestamp
# "deploy_cert" "${domain}" "${certdir}/privkey.pem" "${certdir}/cert.pem" "${certdir}/fullchain.pem" "${certdir}/chain.pem" "${timestamp}"
#  the difference between chain.pem and fullchain.pem is that chain.pem only contains the intermediate certificate. 
#  The file fullchain.pem contains both your server certificate file and the intermediate (conveniently placed in the correct order).
#  This means that you should always use fullchain.pem when configuring a server certificate in an application.
#  The only exception here is if the application uses a dedicated file for providing the chain.
#  https://medium.com/@superseb/get-your-certificate-chain-right-4b117a9c0fce



# exit_hook hook
#  calls scriptlets exit*.sh


## store the parameters into variables

progname=$0
hook=$1
domain=$2
token=$3
magicspell=$4



## when there's nothing to do, don't do it
# you can disable any kind of hook event by deleting it from the following list
if [[ "startup_hook exit_hook deploy_challenge clean_challenge deploy_cert" != *"$hook"*   ]]; then
        exit;
fi

## configuration

he_update_url="https://dyn.dns.he.net/nic/update"
password=""

# check and adapt the following settings
certs_path="/etc/dehydrated/certs"
domain_passwords="/etc/dehydrated/domain_passwords.txt"
scriptlets_dir="/var/lib/dehydrated/hook/scriptlets"


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

if [[ $domain != "" ]]; then
  echo "password for domain $domain is $password. "
fi



## hook deploy_challenge

if [ "${hook}" == "deploy_challenge" ]; then


        response=$(curl -k $he_update_url -d "hostname=_acme-challenge.$domain" -d "password=$password" -d "txt=$magicspell")

        #echo "curl -k $he_update_url -d \"hostname=_acme-challenge.$domain\" -d \"password=$password\" -d \"txt=$magicspell\" "
        echo "response: $response"

        # possible outcomes are: good nochg badauth
        if [[ $response == *"badauth"* ]]; then
                echo "Authorization for _acme-challenge.$domain with password $password failed!"
                echo "URL was:"
                echo "curl -k $he_update_url -d \"hostname=_acme-challenge.$domain\" -d \"password=$password\" -d \"txt=$magicspell\" "
                exit 1
        fi


        cnt=0
        timeout=300

        # loop&sleep here until the new content of the challenge field is actually readable, this may take up to 5 minutes

        while :
        do
        #echo "waiting..."

        sleep 1
        cnt=$(( $cnt+1 ))
        #echo "$cnt loops"

        test_result=$(host -t txt _acme-challenge.$domain)
        echo -ne "waiting...  $cnt loops  result: $test_result \\r"


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
## strategy: there is a folder with tiny scriptlets and we execute tham one by one with the parameters dehydrated passed us  so it is a more flexible drop-in solution
#  note the naming

if [ "${hook}" == "deploy_cert" ]; then
   for f in $scriptlets_dir/deploy_cert*.sh;do
        /bin/bash "$f" "$1" "$2" "$3" "$4" "$5" "$6" "$7"
   done
fi


## hook startup_hook
if [ "${hook}" == "startup_hook" ]; then
   for f in $scriptlets_dir/startup*.sh;do
        /bin/bash "$f" "$1"
   done
fi



## hook exit_hook 
if [ "${hook}" == "exit_hook" ]; then
   for f in $scriptlets_dir/exit*.sh;do
        /bin/bash "$f" "$1"
   done
fi

