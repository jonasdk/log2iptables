# log2iptables 1.3.1
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

## Examples
### Automaitc drop SSH Bruteforce
i use this script for automatic response against SSH bruteforce, and for block Nmap SYN/TCP scan. The first example relates SSH logs, with a regular expression that search for failed login:
```bash
./log2iptables.sh -f /var/log/auth.log -r "sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" -p 3 -l 5

Reading log file: /var/log/auth.log
Using regex: sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})
IP Address group position: 3
Set limit match to: 5

[Found] 59.188.247.119 more then 5 times (4393 match)
`-- [Check] if 59.188.247.119 already exists in iptables...
   `-- [Add ] Add IP 59.188.247.119 to iptables (-j DROP)

1 New IP Address(es) added to iptables:
+
| 59.188.247.119    
+
Done.
```

### Automatic drop Nmap Scan
For automatic drop Nmap SYN scan, i've configured my iptables with following rule:
```
iptables -I INPUT -p tcp -m multiport --dports 23,79 -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG SYN -m limit --limit 3/min -j LOG --log-prefix "PortScan SYN>"
```

in my environment, this rule write a log in /var/log/syslog every time someone scan my server (something like: nmap -sS myserver). I've put in crontab log2iptables with following arguments:
```bash
./log2iptables.sh -f /var/log/syslog -r "PortScan.*SRC\=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" -p 1 -l 1

Reading log file: /var/log/syslog
Using regex: PortScan.*SRC\=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)
IP Address group position: 1
Set limit match to: 1

[Found] 61.239.124.78 more then 1 times (1 match)
`-- [Check] if 61.239.124.78 already exists in iptables...
   `-- [Add ] Add IP 61.239.124.78 to iptables (-j DROP)
[Found] 112.233.174.61 more then 1 times (1 match)
`-- [Check] if 112.233.174.61 already exists in iptables...
   `-- [Add ] Add IP 112.233.174.61 to iptables (-j DROP)
[Found] 112.134.246.185 more then 1 times (1 match)
`-- [Check] if 112.134.246.185 already exists in iptables...
   `-- [Add ] Add IP 112.134.246.185 to iptables (-j DROP)
[Found] 220.75.203.9 more then 1 times (1 match)
`-- [Check] if 220.75.203.9 already exists in iptables...
   `-- [Add ] Add IP 220.75.203.9 to iptables (-j DROP)
[Found] 101.30.131.78 more then 1 times (1 match)
`-- [Check] if 101.30.131.78 already exists in iptables...
   `-- [Add ] Add IP 101.30.131.78 to iptables (-j DROP)
[Found] 121.189.181.61 more then 1 times (1 match)
`-- [Check] if 121.189.181.61 already exists in iptables...
   `-- [Add ] Add IP 121.189.181.61 to iptables (-j DROP)
[Found] 110.248.230.43 more then 1 times (1 match)
`-- [Check] if 110.248.230.43 already exists in iptables...
   `-- [Add ] Add IP 110.248.230.43 to iptables (-j DROP)
[Found] 46.161.40.37 more then 1 times (3 match)
`-- [Check] if 46.161.40.37 already exists in iptables...
   `-- [Add ] Add IP 46.161.40.37 to iptables (-j DROP)
[Found] 182.70.50.47 more then 1 times (2 match)
`-- [Check] if 182.70.50.47 already exists in iptables...
   `-- [Add ] Add IP 182.70.50.47 to iptables (-j DROP)
[Found] 186.153.198.202 more then 1 times (1 match)
`-- [Check] if 186.153.198.202 already exists in iptables...
   `-- [Add ] Add IP 186.153.198.202 to iptables (-j DROP)
[Found] 113.124.167.80 more then 1 times (1 match)
`-- [Check] if 113.124.167.80 already exists in iptables...
   `-- [Add ] Add IP 113.124.167.80 to iptables (-j DROP)
[Found] 72.188.204.15 more then 1 times (1 match)
`-- [Check] if 72.188.204.15 already exists in iptables...
   `-- [Add ] Add IP 72.188.204.15 to iptables (-j DROP)
[Found] 80.82.64.127 more then 1 times (1 match)
`-- [Check] if 80.82.64.127 already exists in iptables...
   `-- [Add ] Add IP 80.82.64.127 to iptables (-j DROP)
[Found] 188.95.110.120 more then 1 times (1 match)
`-- [Check] if 188.95.110.120 already exists in iptables...
   `-- [Add ] Add IP 188.95.110.120 to iptables (-j DROP)
[Found] 87.255.94.110 more then 1 times (1 match)
`-- [Check] if 87.255.94.110 already exists in iptables...
   `-- [Add ] Add IP 87.255.94.110 to iptables (-j DROP)
[Found] 119.246.121.168 more then 1 times (1 match)
`-- [Check] if 119.246.121.168 already exists in iptables...
   `-- [Add ] Add IP 119.246.121.168 to iptables (-j DROP)
[Found] 171.91.240.152 more then 1 times (1 match)
`-- [Check] if 171.91.240.152 already exists in iptables...
   `-- [Add ] Add IP 171.91.240.152 to iptables (-j DROP)
[Found] 119.204.220.229 more then 1 times (1 match)
`-- [Check] if 119.204.220.229 already exists in iptables...
   `-- [Add ] Add IP 119.204.220.229 to iptables (-j DROP)
[Found] 106.35.64.185 more then 1 times (1 match)
`-- [Check] if 106.35.64.185 already exists in iptables...
   `-- [Add ] Add IP 106.35.64.185 to iptables (-j DROP)
[Found] 39.79.196.94 more then 1 times (1 match)
`-- [Check] if 39.79.196.94 already exists in iptables...
   `-- [Add ] Add IP 39.79.196.94 to iptables (-j DROP)
[Found] 220.123.188.21 more then 1 times (1 match)
`-- [Check] if 220.123.188.21 already exists in iptables...
   `-- [Add ] Add IP 220.123.188.21 to iptables (-j DROP)
[Found] 189.102.68.52 more then 1 times (1 match)
`-- [Check] if 189.102.68.52 already exists in iptables...
   `-- [Add ] Add IP 189.102.68.52 to iptables (-j DROP)
[Found] 80.85.120.83 more then 1 times (1 match)
`-- [Check] if 80.85.120.83 already exists in iptables...
   `-- [Add ] Add IP 80.85.120.83 to iptables (-j DROP)
[Found] 110.243.213.174 more then 1 times (1 match)
`-- [Check] if 110.243.213.174 already exists in iptables...
   `-- [Add ] Add IP 110.243.213.174 to iptables (-j DROP)
[Found] 41.203.234.100 more then 1 times (1 match)
`-- [Check] if 41.203.234.100 already exists in iptables...
   `-- [Add ] Add IP 41.203.234.100 to iptables (-j DROP)
[Found] 113.174.105.113 more then 1 times (1 match)
`-- [Check] if 113.174.105.113 already exists in iptables...
   `-- [Add ] Add IP 113.174.105.113 to iptables (-j DROP)
[Found] 220.174.115.92 more then 1 times (1 match)
`-- [Check] if 220.174.115.92 already exists in iptables...
   `-- [Add ] Add IP 220.174.115.92 to iptables (-j DROP)
[Found] 115.45.184.50 more then 1 times (1 match)
`-- [Check] if 115.45.184.50 already exists in iptables...
   `-- [Add ] Add IP 115.45.184.50 to iptables (-j DROP)
[Found] 121.27.163.6 more then 1 times (1 match)
`-- [Check] if 121.27.163.6 already exists in iptables...
   `-- [Add ] Add IP 121.27.163.6 to iptables (-j DROP)
[Found] 101.72.27.166 more then 1 times (1 match)
`-- [Check] if 101.72.27.166 already exists in iptables...
   `-- [Add ] Add IP 101.72.27.166 to iptables (-j DROP)
[Found] 124.106.19.90 more then 1 times (1 match)
`-- [Check] if 124.106.19.90 already exists in iptables...
   `-- [Add ] Add IP 124.106.19.90 to iptables (-j DROP)
[Found] 101.160.155.95 more then 1 times (1 match)
`-- [Check] if 101.160.155.95 already exists in iptables...
   `-- [Add ] Add IP 101.160.155.95 to iptables (-j DROP)
[Found] 121.236.182.73 more then 1 times (1 match)
`-- [Check] if 121.236.182.73 already exists in iptables...
   `-- [Add ] Add IP 121.236.182.73 to iptables (-j DROP)
[Found] 112.101.149.40 more then 1 times (1 match)
`-- [Check] if 112.101.149.40 already exists in iptables...
   `-- [Add ] Add IP 112.101.149.40 to iptables (-j DROP)
[Found] 119.141.235.202 more then 1 times (1 match)
`-- [Check] if 119.141.235.202 already exists in iptables...
   `-- [Add ] Add IP 119.141.235.202 to iptables (-j DROP)
[Found] 81.225.106.161 more then 1 times (1 match)
`-- [Check] if 81.225.106.161 already exists in iptables...
   `-- [Add ] Add IP 81.225.106.161 to iptables (-j DROP)
[Found] 222.132.23.141 more then 1 times (1 match)
`-- [Check] if 222.132.23.141 already exists in iptables...
   `-- [Add ] Add IP 222.132.23.141 to iptables (-j DROP)
[Found] 210.50.232.120 more then 1 times (1 match)
`-- [Check] if 210.50.232.120 already exists in iptables...
   `-- [Add ] Add IP 210.50.232.120 to iptables (-j DROP)
[Found] 87.223.108.183 more then 1 times (1 match)
`-- [Check] if 87.223.108.183 already exists in iptables...
   `-- [Add ] Add IP 87.223.108.183 to iptables (-j DROP)
[Found] 120.8.171.42 more then 1 times (1 match)
`-- [Check] if 120.8.171.42 already exists in iptables...
   `-- [Add ] Add IP 120.8.171.42 to iptables (-j DROP)
[Found] 110.240.228.180 more then 1 times (1 match)
`-- [Check] if 110.240.228.180 already exists in iptables...
   `-- [Add ] Add IP 110.240.228.180 to iptables (-j DROP)
[Found] 202.44.234.114 more then 1 times (1 match)
`-- [Check] if 202.44.234.114 already exists in iptables...
   `-- [Add ] Add IP 202.44.234.114 to iptables (-j DROP)
[Found] 85.100.6.242 more then 1 times (1 match)
`-- [Check] if 85.100.6.242 already exists in iptables...
   `-- [Add ] Add IP 85.100.6.242 to iptables (-j DROP)
[Found] 116.10.8.50 more then 1 times (1 match)
`-- [Check] if 116.10.8.50 already exists in iptables...
   `-- [Add ] Add IP 116.10.8.50 to iptables (-j DROP)
[Found] 114.44.228.122 more then 1 times (1 match)
`-- [Check] if 114.44.228.122 already exists in iptables...
   `-- [Add ] Add IP 114.44.228.122 to iptables (-j DROP)
[Found] 113.79.70.230 more then 1 times (1 match)
`-- [Check] if 113.79.70.230 already exists in iptables...
   `-- [Add ] Add IP 113.79.70.230 to iptables (-j DROP)
[Found] 218.214.55.126 more then 1 times (1 match)
`-- [Check] if 218.214.55.126 already exists in iptables...
   `-- [Add ] Add IP 218.214.55.126 to iptables (-j DROP)
[Found] 117.56.165.83 more then 1 times (1 match)
`-- [Check] if 117.56.165.83 already exists in iptables...
   `-- [Add ] Add IP 117.56.165.83 to iptables (-j DROP)
[Found] 110.172.27.188 more then 1 times (1 match)
`-- [Check] if 110.172.27.188 already exists in iptables...
   `-- [Add ] Add IP 110.172.27.188 to iptables (-j DROP)
[Found] 39.69.24.96 more then 1 times (1 match)
`-- [Check] if 39.69.24.96 already exists in iptables...
   `-- [Add ] Add IP 39.69.24.96 to iptables (-j DROP)
[Found] 124.244.79.230 more then 1 times (1 match)
`-- [Check] if 124.244.79.230 already exists in iptables...
   `-- [Add ] Add IP 124.244.79.230 to iptables (-j DROP)
[Found] 169.45.161.177 more then 1 times (1 match)
`-- [Check] if 169.45.161.177 already exists in iptables...
   `-- [Add ] Add IP 169.45.161.177 to iptables (-j DROP)
[Found] 218.159.0.38 more then 1 times (1 match)
`-- [Check] if 218.159.0.38 already exists in iptables...
   `-- [Add ] Add IP 218.159.0.38 to iptables (-j DROP)
[Found] 95.235.73.99 more then 1 times (1 match)
`-- [Check] if 95.235.73.99 already exists in iptables...
   `-- [Add ] Add IP 95.235.73.99 to iptables (-j DROP)
[Found] 59.16.116.92 more then 1 times (1 match)
`-- [Check] if 59.16.116.92 already exists in iptables...
   `-- [Add ] Add IP 59.16.116.92 to iptables (-j DROP)
[Found] 180.177.169.116 more then 1 times (1 match)
`-- [Check] if 180.177.169.116 already exists in iptables...
   `-- [Add ] Add IP 180.177.169.116 to iptables (-j DROP)
[Found] 219.74.183.157 more then 1 times (1 match)
`-- [Check] if 219.74.183.157 already exists in iptables...
   `-- [Add ] Add IP 219.74.183.157 to iptables (-j DROP)
[Found] 110.247.216.169 more then 1 times (1 match)
`-- [Check] if 110.247.216.169 already exists in iptables...
   `-- [Add ] Add IP 110.247.216.169 to iptables (-j DROP)
[Found] 93.92.199.103 more then 1 times (1 match)
`-- [Check] if 93.92.199.103 already exists in iptables...
   `-- [Add ] Add IP 93.92.199.103 to iptables (-j DROP)
[Found] 112.234.194.243 more then 1 times (1 match)
`-- [Check] if 112.234.194.243 already exists in iptables...
   `-- [Add ] Add IP 112.234.194.243 to iptables (-j DROP)
[Found] 178.153.52.213 more then 1 times (1 match)
`-- [Check] if 178.153.52.213 already exists in iptables...
   `-- [Add ] Add IP 178.153.52.213 to iptables (-j DROP)
[Found] 177.75.44.241 more then 1 times (1 match)
`-- [Check] if 177.75.44.241 already exists in iptables...
   `-- [Add ] Add IP 177.75.44.241 to iptables (-j DROP)
[Found] 222.218.95.151 more then 1 times (1 match)
`-- [Check] if 222.218.95.151 already exists in iptables...
   `-- [Add ] Add IP 222.218.95.151 to iptables (-j DROP)
[Found] 108.223.43.250 more then 1 times (1 match)
`-- [Check] if 108.223.43.250 already exists in iptables...
   `-- [Add ] Add IP 108.223.43.250 to iptables (-j DROP)
[Found] 59.127.52.197 more then 1 times (1 match)
`-- [Check] if 59.127.52.197 already exists in iptables...
   `-- [Add ] Add IP 59.127.52.197 to iptables (-j DROP)
[Found] 101.72.37.178 more then 1 times (1 match)
`-- [Check] if 101.72.37.178 already exists in iptables...
   `-- [Add ] Add IP 101.72.37.178 to iptables (-j DROP)
[Found] 115.54.145.2 more then 1 times (1 match)
`-- [Check] if 115.54.145.2 already exists in iptables...
   `-- [Add ] Add IP 115.54.145.2 to iptables (-j DROP)
[Found] 41.41.245.224 more then 1 times (1 match)
`-- [Check] if 41.41.245.224 already exists in iptables...
   `-- [Add ] Add IP 41.41.245.224 to iptables (-j DROP)
[Found] 5.149.203.81 more then 1 times (1 match)
`-- [Check] if 5.149.203.81 already exists in iptables...
   `-- [Add ] Add IP 5.149.203.81 to iptables (-j DROP)
[Found] 27.203.109.249 more then 1 times (1 match)
`-- [Check] if 27.203.109.249 already exists in iptables...
   `-- [Add ] Add IP 27.203.109.249 to iptables (-j DROP)
[Found] 78.187.121.165 more then 1 times (1 match)
`-- [Check] if 78.187.121.165 already exists in iptables...
   `-- [Add ] Add IP 78.187.121.165 to iptables (-j DROP)
[Found] 220.170.221.50 more then 1 times (2 match)
`-- [Check] if 220.170.221.50 already exists in iptables...
   `-- [Add ] Add IP 220.170.221.50 to iptables (-j DROP)
[Found] 178.130.35.92 more then 1 times (1 match)
`-- [Check] if 178.130.35.92 already exists in iptables...
   `-- [Add ] Add IP 178.130.35.92 to iptables (-j DROP)

73 New IP Address(es) added to iptables:
+
| 112.233.174.61     | 61.239.124.78      | 220.75.203.9
| 112.134.246.185    | 121.189.181.61     | 101.30.131.78
| 182.70.50.47       | 46.161.40.37       | 110.248.230.43
| 186.153.198.202    | 72.188.204.15      | 113.124.167.80
| 87.255.94.110      | 188.95.110.120     | 80.82.64.127
| 119.246.121.168    | 171.91.240.152     | 119.204.220.229
| 106.35.64.185      | 39.79.196.94       | 189.102.68.52
| 220.123.188.21     | 110.243.213.174    | 80.85.120.83
| 41.203.234.100     | 115.45.184.50      | 220.174.115.92
| 113.174.105.113    | 124.106.19.90      | 101.72.27.166
| 121.27.163.6       | 121.236.182.73     | 101.160.155.95
| 112.101.149.40     | 222.132.23.141     | 81.225.106.161
| 119.141.235.202    | 210.50.232.120     | 87.223.108.183
| 120.8.171.42       | 202.44.234.114     | 110.240.228.180
| 85.100.6.242       | 116.10.8.50        | 117.56.165.83
| 218.214.55.126     | 113.79.70.230      | 114.44.228.122
| 124.244.79.230     | 39.69.24.96        | 110.172.27.188
| 169.45.161.177     | 218.159.0.38       | 180.177.169.116
| 59.16.116.92       | 95.235.73.99       | 110.247.216.169
| 219.74.183.157     | 222.218.95.151     | 177.75.44.241
| 178.153.52.213     | 112.234.194.243    | 93.92.199.103
| 108.223.43.250     | 59.127.52.197      | 101.72.37.178
| 115.54.145.2       | 5.149.203.81       | 41.41.245.224
| 27.203.109.249     | 78.187.121.165     | 220.170.221.50
| 178.130.35.92      
+
Done.
```
Obviously here the output is more verbose.


## TODO
- `[high  ]` Send mail with log2iptables output
- `[medium]` HTTP POST ip list to URL
- `[low   ]` HTML Output
every contribution is welcome :)

## Contact
```
Andrea (aka theMiddle)
https://waf.blue
theMiddle@waf.blue
```
