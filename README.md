# log2iptables
log2iptables is a Bash script that parse a log file and execute iptables command. Useful for automatically block an IP address against bruteforce or port scan activities.

By a simple regular expression match, you can parse any logfile type and take an action on iptables. For example, with log2iptables you can: Search for all logs in /var/log/myssh.log that match "Failed password.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" more that 5 times, and then block the ipaddress with iptables with action DROP.

## Usage
```
./log2iptables -h
```
- `-f `  Log file to read (ex: `/var/log/auth.log`)
- `-r `  Regular Expression (ex: `"(F|f)ail.*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"`)
- `-p `  IP Address group number (on example regex before: 2)
- `-l `  How many times the regex must match (ex: 5)
- `-a `  IPTables Action (the iptables -j argument, ex: `DROP`)
- `-i `  IPTables insert (I) or append (A) mode (ex: A)

## Example
i use this script for automatic response against SSH bruteforce, and for block nmap SYN/TCP scan. The first example relates SSH logs:
```bash
./log2iptables.sh -f /var/log/auth.log -r "sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" -p 3 -l 5

Reading log file: /var/log/auth.log
Using regex: sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})
IP Address group position: 3
Set limit match to: 5

[Found] 59.188.247.*** more then 5 times (4393 match)
`-- [Check] if 59.188.247.*** already exists in iptables...
   `-- [Add ] Add IP 59.188.247.*** to iptables (-j DROP)

1 New IP Address(es) added to iptables:
+
| 59.188.247.***    
+
Done.
```
