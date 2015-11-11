#!/bin/bash

# log2iptables
# version 1.3.1

# log2iptables is a Bash script that parse a log file
# and execute iptables command. Useful for automatically
# block an IP address against bruteforce or port scan activities.
#
# Documentation and example usage at:
# https://github.com/theMiddleBlue/log2iptables
# Author: Andrea (aka theMiddle) Menin
#

# -- CONFIG default value --
#

# Absolute path where ssh log file are stored
# default /var/log/auth.log
LOGFILE='/var/log/auth.log';

# the regular expression that match an authentication failed
# in the following example, i've used 3 groups. The IP Address
# is in the 3rd group, and i need to set the REGEXPIPPOS = 3
# for example, if my regex is: ssh.*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)
# REGEXPIPPOS variable must be set to 1
REGEXP="sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})";

# regex group number that contains IP Address
REGEXPIPPOS=3;

# How many times the REGEXP need to match
# before run the iptables command.
LIMIT=5;

# iptables action (-j argument)
IPTABLESACTION="DROP";

# iptables chain (INPUT, OUTPUT, etc...)
IPTABLESCHAIN="INPUT";

# I = insert
# A = append
IPTABLESINSERT="I";

#
# -- END CONFIG --



echo ""
biniptables=$(which iptables);
bingrep=$(which grep);
binwc=$(which wc);

while getopts :hf:r:p:l:a:i:c: OPTION; do
	case $OPTION in
		f)
			echo "Reading log file: ${OPTARG}";
			LOGFILE=$OPTARG;
		;;
		r)
			echo "Using regex: ${OPTARG}"
			REGEXP=$OPTARG;
		;;
		p)
			echo "IP Address group position: ${OPTARG}"
			REGEXPIPPOS=$OPTARG;
		;;
		l)
			echo "Set limit match to: ${OPTARG}"
			LIMIT=$OPTARG;
		;;
		a)
			echo "Set iptables action to: ${OPTARG}"
			IPTABLESACTION=$OPTARG;
		;;
		i)
			echo "Set iptables insert/append mode to: ${OPTARG}"
			IPTABLESINSERT=$OPTARG;
		;;
		c)
			echo "Set iptables chain: ${OPTARG}"
			IPTABLESCHAIN=$OPTARG;
		;;
		h)
			echo "Usage: ${0} -f <logfile> [rplaic]"
			echo ""
			echo "-f   Log file to read (default: /var/log/auth.log)"
			echo "-r   Regular Expression (ex: \"(F|f)ail.*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\")"
			echo "-p   IP Address group number (on example regex before: 2)"
			echo "-l   How many times the regex must match (default: 5)"
			echo "-a   IPTables Action (the iptables -j argument, default: DROP)"
			echo "-i   IPTables insert (I) or append (A) mode (default: I)"
			echo "-c   IPTables chain like INPUT, OUTPUT, etc... (default: INPUT)"
			echo ""
			echo "examples usage at https://github.com/theMiddleBlue/log2iptables#examples"
			echo ""
			exit 0;
		;;
	esac
done
echo ""

declare -A iparrhash;
declare -A addedip;
IPARR=();
IPQNT=();
COL0="\e[0m";  # no color
COL1="\e[32m"; # green
COL2="\e[93m"; # yellow
COL3="\e[31m"; # red
l=0;
q=0;

while read line; do
	if [[ ${line} =~ $REGEXP ]]; then
		addip="1";
		for i in ${IPARR[@]}; do
			if [ "${i}" = "${BASH_REMATCH[$REGEXPIPPOS]}" ]; then
				addip='0';
			fi
		done

		if [ ${addip} = "1" ]; then
			l=`expr $l + 1`;
			IPARR[$l]=${BASH_REMATCH[$REGEXPIPPOS]};
			iparrhash[${BASH_REMATCH[$REGEXPIPPOS]}]=1;
		else
			iparrhash["${BASH_REMATCH[$REGEXPIPPOS]}"]=`expr ${iparrhash[${BASH_REMATCH[$REGEXPIPPOS]}]} + 1`;
		fi
	fi
done <$LOGFILE

if [ ${#iparrhash[@]} -eq 0 ]; then
	echo -e "Nothing to do here, exit.\n";
	exit 0;
fi

for s in "${!iparrhash[@]}"; do
	if [ ${iparrhash["$s"]} -ge $LIMIT ]; then
		echo -e "[${COL1}Found${COL0}] $s more then ${LIMIT} times (${iparrhash["$s"]} match)"
		echo -e "\`-- [${COL1}Check${COL0}] if $s already exists in iptables..."
		iptabout=$(${biniptables} -L -n | ${bingrep} $s | ${binwc} -l);

		if [ $iptabout -gt 0 ]; then
			echo -e "   \`-- [${COL1}Skip ${COL0}] $s already present in iptables."
		else
			${biniptables} -${IPTABLESINSERT} ${IPTABLESCHAIN} -s ${s} -j ${IPTABLESACTION}
			echo -e "   \`-- [${COL3}Add ${COL0}] Add IP $s to iptables (-j ${IPTABLESACTION})"
			addedip["${s}"]=1;
		fi
	fi
done

ipout="";
echo -e "\n${#addedip[@]} New IP Address(es) added to iptables:";
echo "+";
i=1;
for s in "${!addedip[@]}"; do
	if [[ "$i" -lt 3 ]]; then
		ipout="$ipout| $s - "
		i=`expr $i + 1`;
	else
		ipout="$ipout| $s\n";
		i=1
	fi
done
echo -e "${ipout}" | column -t -s'-'

echo "+";
echo "Done.";
