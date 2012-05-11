#!/bin/bash

WARNDAYS=30
DATE=`which date`

# Function to convert Month String to Number
getmonth()
{
    case ${1} in
        Jan) echo 1 ;;
        Feb) echo 2 ;;
        Mar) echo 3 ;;
        Apr) echo 4 ;;
        May) echo 5 ;;
        Jun) echo 6 ;;
        Jul) echo 7 ;;
        Aug) echo 8 ;;
        Sep) echo 9 ;;
        Oct) echo 10 ;;
        Nov) echo 11 ;;
        Dec) echo 12 ;;
          *) echo  0 ;;
    esac
}

# Function to convert a date from MONTH-DAY-YEAR to Julian format
date2julian() {

    if [ "${1} != "" ] && [ "${2} != ""  ] && [ "${3}" != "" ]
    then
        ## Since leap years add aday at the end of February,
        ## calculations are done from 1 March 0000 (a fictional year)
        d2j_tmpmonth=$((12 * ${3} + ${1} - 3))

        ## If it is not yet March, the year is changed to the previous year
        d2j_tmpyear=$(( ${d2j_tmpmonth} / 12))

        ## The number of days from 1 March 0000 is calculated
        ## and the number of days from 1 Jan. 4713BC is added
        echo $(( (734 * ${d2j_tmpmonth} + 15) / 24
                 - 2 * ${d2j_tmpyear} + ${d2j_tmpyear}/4
                 - ${d2j_tmpyear}/100 + ${d2j_tmpyear}/400 + $2 + 1721119 ))
    else
        echo 0
    fi
}

# Function to calculate difference in days between two julian dates.
date_diff()
{
    if [ "${1}" != "" ] &&  [ "${2}" != "" ]
    then
        echo $((${2} - ${1}))
    else
        echo 0
    fi
}

# Setup some baseline dates for comparisons
MONTH=$(${DATE} "+%m")
DAY=$(${DATE} "+%d")
YEAR=$(${DATE} "+%Y")

host=$1
port=$2

if [ "$host" = "" ]
then
        echo "Error: Usage: check_ssl_cert.sh host port [warningdays]"
        exit 1
fi

if [ "$port" = "" ]
then
        echo "Error: Usage: check_ssl_cert.sh host port [warningdays]"
        exit 1
fi

if [ "$3" != "" ]
then
        WARNDAYS=$3
fi

#Get certificate expiration date
certdate=`echo "" | openssl s_client -connect $host:$port 2>/dev/null | \
sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | \
openssl x509 -text|grep "Not After :" | sed 's/Not After ://g'`

set -- ${certdate}
certmonth=$(getmonth ${1})
CERTJULIAN=$(date2julian ${certmonth#0} ${2#0} ${4})
NOWJULIAN=$(date2julian ${MONTH#0} ${DAY#0} ${YEAR})
DATEDIFF=$(date_diff ${NOWJULIAN} ${CERTJULIAN})

if [ ${DATEDIFF} -lt ${WARNDAYS} ]
        then
                echo "CRITICAL: Certificate will expire in $DATEDIFF days on $certdate"
                exit 2
else
                echo "OK: Certificate is valid for $DATEDIFF days expires on $certdate"
                exit 0
fi

