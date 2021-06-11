#	place anything that should happen at the end of certification renowal here

hook=$1
myHook="exit_hook"


if [ "${hook}" == $myHook ]; then
	echo "exit scriptlet called" >> /tmp/log
fi


