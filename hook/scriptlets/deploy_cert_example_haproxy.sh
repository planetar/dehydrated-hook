#   this script is specifically tailored for an octoprint on octopi scenario
#   combine fullchain.pem and private key into a file written to /etc/haproxy/ssl with "$domain_combined.pem" as the filename
#   haproxy configuration needs manual adaption to that: put the path to the certificate where snakeoil.pem is referenced
#   This script is indebted to detailed info at https://community.octoprint.org/t/lets-encrypt-on-octopi/15328
#

hook=$1
domain=$2
privkey=$3
cert=$4
fullchain=$5
chain=$6
timestamp=$7

myHook="deploy_cert"
myDomain="octoprint.example.com"

destination_path="/etc/haproxy/ssl"

if [ "${hook}" == $myHook ]; then
   if [[ $domain == $myDomain  ]];then
      echo "deploycert scriptlet called with $1 $2 $3 $4 $5 $6 $7" >> /tmp/log
      mkdir -p $destination_path
      cat $fullchain $privkey > $destination_path/$domain-combined.pem
      systemctl reload haproxy

   fi
fi


