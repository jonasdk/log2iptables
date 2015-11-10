# log2iptables
log2iptables is a Bash script that parse a log file and execute iptables command. Useful for automatically block an IP address against bruteforce or port scan activities.

By a simple regular expression match, you can parse any logfile type and take an action on iptables. For example, with log2iptables you can: Search for all logs in /var/log/myssh.log that match "Failed password.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" more that 5 times, and then block the ipaddress with iptables with action DROP.

# Usage
```
./log2iptables -h
```
