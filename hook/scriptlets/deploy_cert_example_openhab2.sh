#   this script is tailored for a home automation host running openhab2
#   it is very much indebted to the info at https://gist.github.com/klaernie/b424ebfce9a5ed42d63b6112cd4cc0cb

#   https://smarthome.example.com:8443/start/index runs with a lock icon, which of course makes most sense in an IPv6 context
#   as you don't really want to put openhab2 on the outside of your firewall when it has no authentication


hook=$1
domain=$2
privkey=$3
cert=$4
fullchain=$5
chain=$6
timestamp=$7

myHook="deploy_cert"
myDomain="tieke.datenwusel.net"


if [ "${hook}" == $myHook ]; then
   if [[ $domain == $myDomain  ]];then
      echo "deploycert scriptlet called with $1 $2 $3 $4 $5 $6 $7" >> /tmp/log
        systemctl stop openhab2
        echo "openhab" > /tmp/passw

        rm /etc/openhab2/keystore
        openssl pkcs12 -export -inkey $privkey -in $fullchain -out /tmp/oh.p12 -password file:/tmp/passw
        keytool -importkeystore -srckeystore /tmp/oh.p12 -srcstoretype PKCS12 -srcstorepass:file /tmp/passw  -destkeystore /etc/openhab2/keystore -storepass:file /tmp/passw
        keytool -changealias -keystore /etc/openhab2/keystore -alias 1 -destalias mykey -storepass:file /tmp/passw
        chown openhab. /etc/openhab2/keystore
	rm /tmp/passw
	rm /tmp/oh.p12
        systemctl start openhab2


   fi
fi


