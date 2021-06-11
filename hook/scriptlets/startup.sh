#	place anything that should happen at startup of certification renowal here

hook=$1
myHook="startup_hook"


if [ "${hook}" == $myHook ]; then
	echo "startup scriptlet called" >> /tmp/log
fi


