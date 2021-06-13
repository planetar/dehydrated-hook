
#   this script is tailored for a mosquitto server
#   edit the Mosquitto conf file to use the files

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
      echo "deploycert mosquitto scriptlet called with $1 $2 $3 $4 $5 $6 $7" >> /tmp/log

        mkdir -p       /etc/mosquitto/certs/
        cp $privkey    /etc/mosquitto/certs/key.pem
        cp $cert       /etc/mosquitto/certs/cert.pem
        cp $fullchain  /etc/mosquitto/certs/ca-chain.pem

        systemctl restart mosquitto


   fi
fi


