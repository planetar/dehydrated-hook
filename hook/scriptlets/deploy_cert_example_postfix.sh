
#   this script is tailored for a postfix server


hook=$1
domain=$2
privkey=$3
cert=$4
fullchain=$5
chain=$6
timestamp=$7

myHook="deploy_cert"
myDomain="mosquitto.example.com"


if [ "${hook}" == $myHook ]; then
   if [[ $domain == $myDomain  ]];then
      echo "deploycert postfix scriptlet called with $1 $2 $3 $4 $5 $6 $7" >> /tmp/log

        mkdir -p       /etc/postfix/certs
        cp $privkey    /etc/postfix/certs/key.pem
        cp $cert       /etc/postfix/certs/cert.pem
        cp $fullchain  /etc/postfix/certs/fullchain.pem
        cp $chain      /etc/postfix/certs/chain.pem
        systemctl restart postfix


   fi
fi

