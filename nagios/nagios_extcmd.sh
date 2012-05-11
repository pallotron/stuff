#!/bin/bash
#
# AUTHOR: Angelo Failla <afailla@newbay.com>
#
# this script allow the user to send commands to the Nagios daemon in order to:
#
# - enable/disable a service checks on a particular host
# - enable/disable passive checks on a particular host
# - enable/disable notifications on a particular host
#
# a list of ALL the nagios commands can be found on this page:
# http://www.nagios.org/developerinfo/externalcommands/commandlist.php
#
# commands used on this script are:
#
# ENABLE_SVC_CHECK
# ENABLE_SVC_NOTIFICATIONS
# ENABLE_PASSIVE_SVC_CHECKS
# DISABLE_SVC_CHECK
# DISABLE_SVC_NOTIFICATIONS
# DISABLE_PASSIVE_SVC_CHECKS

# default external command file
commandfile="/var/lib/nagios2/rw/nagios.cmd"

function usage {
cat << EOF

$0 <-n | -N | -p | -P | -C | -c> host service_description <nagios.cmd_path>
$0 -h

-n disable notification
-N enable notification

-p disable passive check
-P enable passive check

-c disable check
-C enable check

examples:

    $ $0 -c localhost HTTP
    executing --> "echo [1236894677] DISABLE_SVC_CHECK;localhost;HTTP > /var/lib/nagios2/rw/nagios.cmd"

    $ $0 -p localhost HTTP
    executing --> "echo [1236894682] DISABLE_PASSIVE_SVC_CHECK;localhost;HTTP > /var/lib/nagios2/rw/nagios.cmd"

    $ $0 -n localhost HTTP
    executing --> "echo [1236894687] DISABLE_SVC_NOTIFICATIONS;localhost;HTTP > /var/lib/nagios2/rw/nagios.cmd"

EOF
    exit 
}

while getopts "hCcNnPp" flag
do
    case "$flag" in

        C) cmd=ENABLE_SVC_CHECK;;
        c) cmd=DISABLE_SVC_CHECK;;

        N) cmd=ENABLE_SVC_NOTIFICATIONS;;
        n) cmd=DISABLE_SVC_NOTIFICATIONS;;

        P) cmd=ENABLE_PASSIVE_SVC_CHECKS;;
        p) cmd=DISABLE_PASSIVE_SVC_CHECKS;;

        h) usage ;;

    esac
done

shift $((OPTIND-1))

if [ "$cmd" == "" ]; then
    echo "you have to specify a command!"
    exit 1
fi

host=$1
service=$2

if [ "$host" == "" ] || [ "$service" == "" ]; then
    echo "you're missing some input"
    exit 1
fi

if [ "$3" != "" ]; then commandfile="$3"; fi
if [ ! -w $commandfile ]; then
    echo "file \"$commandfile\" doesn't exist or it is not writable"
    exit 1
fi
if [ ! -p $commandfile ]; then
    echo "file \"$commandfile\" it's not a pipe"
    exit 1
fi

now=`date +%s`
echo "executing --> \"echo [$now] $cmd;$host;$service > $commandfile\""
printf "[%i] $cmd;$host;$service\n" $now > $commandfile

exit 0
