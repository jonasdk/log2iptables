#!/bin/bash

# log2iptables

# log2iptables is a Bash script that parse a log file
# and execute iptables command. Useful for automatically
# block an IP address against bruteforce or port scan activities.
#
# Documentation and example usage at:
# https://github.com/theMiddleBlue/log2iptables
# Author: Andrea (aka theMiddle) Menin
#
VERSION="1.7";

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

# Enable / Disable iptables execution
# for example you can disable the iptables execution
# and test the script
# 1=on
# 0=off
IPTABLESEXEC=0;

# send Telegram notification
# more information at https://core.telegram.org/bots/api
# useful tutorial on how to create a telegram bot
# http://unnikked.ga/getting-started-with-telegram-bots/
SENDTELEGRAM=0;
TELEGRAMBOTTOKEN="<your telegram bot token here>";
TELEGRAMCHATID="<your chat id here>";

# send HTTP POST request
# to a specific url, with all ip found
# and other informations.
SENDHTTP=0;
HTTPURL="http://yourwebsite/log2iptables.php";
HTTPHEADERS="X-Custom-Header: foo\nX-Another-Param: bar"

# Execute a command when iptables run
# 0 = do not execute anything.
EXECCMD="0";

#
# -- END CONFIG --

SENDMAIL=0;

echo ""
biniptables=$(which iptables);
bingrep=$(which grep);
binwc=$(which wc);
bincurl=$(which curl);
bincolumn=$(which column);
binsendmail=$(which sendmail);
shostname=$(hostname);
sallipadd=$(hostname --all-ip-addresses);

while getopts :hf:r:p:l:a:i:c:t:T:C:x:u:U:H:X:m:M:e: OPTION; do
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
		t)
			echo "Use Telegram bot: ${OPTARG}"
			SENDTELEGRAM=$OPTARG;
		;;
		T)
			echo "Telegram bot Token: ${OPTARG}"
			TELEGRAMBOTTOKEN=$OPTARG;
		;;
		C)
			echo "Telegram Chat ID: ${OPTARG}"
			TELEGRAMCHATID=$OPTARG;
		;;
		x)
			echo "Execute iptables command: ${OPTARG}"
			IPTABLESEXEC=$OPTARG;
		;;
		u)
			echo "Enable send HTTP POST request: ${OPTARG}"
			SENDHTTP=$OPTARG;
		;;
		U)
			echo "Destination URL: ${OPTARG}"
			HTTPURL=$OPTARG;
		;;
		H)
			echo "Additional Header parameters: ${OPTARG}"
			HTTPHEADERS=$OPTARG;
		;;
		X)
			echo "Execute command when iptables run: ${OPTARG}"
			EXECCMD="${OPTARG}";
		;;
		m)
			echo "On new iptables rules, send mail to: ${OPTARG}"
			SENDMAILTO="${OPTARG}";
			SENDMAIL=1;
		;;
		M)
			echo "Mail from: ${OPTARG}"
			SENDMAILFROM="${OPTARG}";
		;;
		e)
			if [[ "$OPTARG" -eq "ssh-bruteforce" ]]; then
				echo "Predefined template: ${OPTARG}"
				REGEXP="sshd.*Failed.password.*from.([0-9\\.]+)";
				REGEXPIPPOS=1;
			elif [[ "$OPTARG" -eq "nginx-scan-nikto" ]]; then
				echo "Predefined template: ${OPTARG}"
				REGEXP="([0-9\.]+).*Nikto";
				REGEXPIPPOS=1;
			fi
		;;
		h)
			echo "Usage: ${0} -x [0|1] -f <logfile> [rplaic]"
			echo ""
			echo "-h            This help"
			echo "-f <file>     Log file to read (default: /var/log/auth.log)"
			echo "-r <regex>    Regular Expression (ex: \"(F|f)ail.*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\")"
			echo "-p <number>   IP Address group number (on example regex before: 2)"
			echo "-l <number>   How many times the regex must match (default: 5)"
			echo "-x <1 or 0>   Execute IPTables command 1=enable 0=disable (default: 0)"
			echo "-a <action>   IPTables Action (the iptables -j argument, default: DROP)"
			echo "-i <I or A>   IPTables insert (I) or append (A) mode (default: I)"
			echo "-c <chain>    IPTables chain like INPUT, OUTPUT, etc... (default: INPUT)"
			echo "-m <address>  When log2iptables adds new rules, send mail to <address>"
			echo "-M <address>  Send mail from <address>"
			echo ""
			echo "Predefined Templates:"
			echo "-e <template> Active template: ssh-bruteforce, nginx-scan-nikto"
			echo ""
			echo "System Functions:"
			echo "-X <cmd>      Execute command <cmd> after new iptables rules added (default: 0)"
			echo ""
			echo "HTTP Functions:"
			echo "-u <1 or 0>   Enable send HTTP POST request with all ip found 1=on 0=off (default: 0)"
			echo "-U <url>      Destination URL (example: http://myserver/myscript.php)"
			echo "-H <param>    Header parameters to send with curl (optional)"
			echo ""
			echo "Telegram Functions:"
			echo "-t <1 or 0>   Send Telegram msg on iptables command 0=off, 1=on (default: 0)"
			echo "-T <token>    Set Telegram bot Token"
			echo "-C <chat id>  Set Telegram Chat ID"
			echo ""
			echo "examples usage at https://github.com/theMiddleBlue/log2iptables#examples"
			echo ""
			exit 0;
		;;
	esac
done

if [ $IPTABLESEXEC -eq 0 ]; then
	echo -e "\nWARNING: log2iptables started in test mode.\nNo rules will be created on iptables.\nEnable production mode with: -x 1"
fi

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

echo ""
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

somethinghappens=0;
for s in "${!iparrhash[@]}"; do
	if [ ${iparrhash["$s"]} -ge $LIMIT ]; then
		echo -e "[${COL1}Found${COL0}] $s more then ${LIMIT} times (${iparrhash["$s"]} match)"
		echo -e "\`-- [${COL1}Check${COL0}] if $s already exists in iptables..."
		iptabout=$(${biniptables} -L -n | ${bingrep} $s | ${binwc} -l);

		if [ $iptabout -gt 0 ]; then
			echo -e "   \`-- [${COL1}Skip ${COL0}] $s already present in iptables."
		else
			if [ $IPTABLESEXEC -eq 1 ]; then
				${biniptables} -${IPTABLESINSERT} ${IPTABLESCHAIN} -s ${s} -j ${IPTABLESACTION}
			fi
			echo -e "   \`-- [${COL3}Add ${COL0}] Add IP $s to iptables (-j ${IPTABLESACTION})"
			addedip["${s}"]=1;
			somethinghappens=1;
		fi
	fi
done

if [ $somethinghappens -eq 1 ]; then
	ipout="";
	telegramout="";
	csvout="";
	pipeout="";
	mailout="";
	echo -e "\n${#addedip[@]} New IP Address(es) added to iptables:";
	echo "+";
	i=1;
	for s in "${!addedip[@]}"; do
		mailout="${mailout}- ${s}\\n";
		telegramout="${telegramout}${s}%2C ";
		csvout="${csvout}${s},";
		pipeout="${pipeout}${s}|";
		if [[ "$i" -lt 3 ]]; then
			ipout="$ipout| $s - ";
			i=`expr $i + 1`;
		else
			ipout="$ipout| $s\n";
			i=1;
		fi
	done
	echo -e "${ipout}" | ${bincolumn} -t -s'-'
	echo "+";

	if [ $SENDTELEGRAM -eq 1 ]; then
		echo -e "[${COL1}Send ${COL0}] message from your Telegram bot."
		${bincurl} -s -d "text=Hi%2C log2iptables has added the following IP to iptables%3A ${telegramout}on system *${shostname}* %28${sallipadd}%29 found it in ${LOGFILE}&chat_id=${TELEGRAMCHATID}" "https://api.telegram.org/bot${TELEGRAMBOTTOKEN}/sendMessage" > /dev/null
	fi

	if [ $SENDHTTP -eq 1 ]; then
		echo -e "[${COL1}Send ${COL0}] http post request with curl."
		${bincurl} -s -d "ipaddresses=${telegramout}&logfile=${LOGFILE}&system=${shostname}" -A "log2iptables ${VERSION} (https://github.com/theMiddleBlue/log2iptables)" -H "${HTTPHEADERS}" "${HTTPURL}" > /dev/null
	fi

	if [ $SENDMAIL -eq 1 ]; then
		MAILBODY="Hi,\\r\\n\\r\\n Following IPs were Updated/Added to iptables:\\r\\n ${mailout}\\r\\n\\r\\nOn system: ${shostname}\\r\\nIP Addresses: ${sallipadd}\\r\\nFound in log: ${LOGFILE}\\r\\n\\r\\n--\\r\\nlog2iptables\\r\\nhttps://github.com/theMiddleBlue/log2iptables";
		echo -e "Subject: [log2iptables] New iptables rules added\r\n\r\n${MAILBODY}" | ${binsendmail} -F "log2iptables" -f "${SENDMAILFROM}" "${SENDMAILTO}"
	fi

	if [ "$EXECCMD" != 0 ]; then
		echo -en "\nExecuting Command: ${EXECCMD}\n";
		echo -en "+\n";
		if [[ $EXECCMD == *"IPLISTCSV"* ]]; then
			CMDREPLACE=${EXECCMD//IPLISTCSV/$csvout};
		elif [[ $EXECCMD == *"IPLISTPIPE"* ]]; then
			CMDREPLACE=${EXECCMD//IPLISTPIPE/$pipeout};
		else
			CMDREPLACE=${EXECCMD};
		fi

		CMDOUTPUT=`${CMDREPLACE}`;
		echo $CMDOUTPUT;
		echo -en "+\n\n";
	fi
fi
echo -e "Done.\n";
