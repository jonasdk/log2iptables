# log2iptables
log2iptables is a Bash script that parse a log file and execute iptables command. Useful for automatically block an IP address against bruteforce or port scan activities.

By a simple regular expression match, you can parse any logfile type and take an action on iptables. For example, with log2iptables you can: Search for all logs in /var/log/myssh.log that match "Failed password.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" more that 5 times, and then block the ipaddress with iptables with action DROP.

## Usage
```
./log2iptables -h
```
- **-f** Log file to read (ex: /var/log/auth.log)
- **-r** Regular Expression (ex: "(F|f)ail.*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)")
- **-p** IP Address group number (on example regex before: 2)
- **-l** How many times the regex must match (ex: 5)
- **-a** IPTables Action (the iptables -j argument, ex: DROP)
- **-i** IPTables insert (I) or append (A) mode (ex: A)
