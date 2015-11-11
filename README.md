# log2iptables 1.4
log2iptables is a Bash script that parse a log file and execute iptables command. Useful for automatically block an IP address against bruteforce or port scan activities.

By a simple regular expression match, you can parse any logfile type and take an action on iptables. For example, with log2iptables you can: Search for all logs in /var/log/myssh.log that match "Failed password.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" more that 5 times, and then block the ipaddress with iptables with action DROP.

Why a Bash script?
> simple is better. no deps, no installation, no fucking boring things. just run it in crontab :)

## Usage
```
./log2iptables -h
```
- `-f `  Log file to read (default: `/var/log/auth.log`)
- `-r `  Regular Expression (ex: `"(F|f)ail.*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"`)
- `-p `  IP Address group number (on example regex before: 2)
- `-l `  How many times the regex must match (default: 5)
- `-x `  Execute IPTables command 1=enable 0=disable (default: 1)
- `-a `  IPTables Action (`the iptables -j argument, default: DROP`)
- `-i `  IPTables insert (I) or append (A) mode (default: I)
- `-c `  IPTables chain like INPUT, OUTPUT, etc... (default: INPUT)
- `-t `  Send Telegram msg on iptables command 0=off, 1=on (default: 0)
- `-T `  Set Telegram bot Token
- `-C `  Set Telegram Chat ID

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

If you neet to test the script, or the regular expression, without add any rules to iptables, you can run log2iptables with the `-x 0` argument:
```bash
./log2iptables.sh -x 0 -f /var/log/auth.log -r "sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" -p 3 -l 5
```


### Automatic drop Nmap Scan
For automatic drop Nmap SYN scan, i've configured my iptables with the following rule:
```
iptables -I INPUT -p tcp -m multiport --dports 23,79 -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG SYN -m limit --limit 3/min -j LOG --log-prefix "PortScan SYN>"
```

in my environment, this rule write a log in /var/log/syslog every time someone scan my server (something like: nmap -sS myserver). I've put in crontab log2iptables with the following arguments:
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
...omitted for more clarity...


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
Obviously, here the output is more verbose.

## Crontab
I don't know which is the better way to run this script in crontab.
Anyway, I've the following configuration:
```
*/5 * * * * /usr/local/bin/log2iptables.sh -f /var/log/auth.log -r "sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" -p 3 -l 5 > /dev/null 2>&1
*/1 * * * * /usr/local/bin/log2iptables.sh -f /var/log/syslog -r "PortScan.*SRC\=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" -p 1 -l 1 > /dev/null 2>&1
```

## Use Telegram Bot
Now you can send a text message to your phone, using Telegram, when log2iptables execute the iptables command. This is possible by using the Telegram Bot API. For more information see https://core.telegram.org/bots/api or this useful tutorial http://unnikked.ga/getting-started-with-telegram-bots/ on how to get a bot Token.

Anyway, i've created a new Telegram Bot just visiting https://telegram.me/botfather and then i've open a chat with my bot. Then i've get the Chat ID with curl, like this:
```bash
curl "https://api.telegram.org/bot<token>/getUpdates"

{"ok":true,"result":[{"update_id":xxxxx,
"message":{"message_id":1,"from":{"id":xxxxx,"first_name":"Andrea","last_name":"Menin","username":"theMiddle"},"chat":{"id":123456,"first_name":"Andrea","last_name":"Menin","username":"theMiddle","type":"private"},"date":xxxxxxx,"text":"\/start"}}]}
```
The JSON output include my Chat ID: 123456 (fake) and i can use it for send text message from my bot, with something like this:
```
curl -d "text=hey Andrea... i am your father&chat_id=123456" "https://api.telegram.org/bot<token>/sendMessage"
```

### Notify on iptables command execution using Telegram
When you run log2iptables you can specify the -t 1, -T and -C arguments that means:
- `-t 1       ` Active notification using Telegram
- `-T <token> ` Set the Telegram Bot Token
- `-C <chatid>` Set the Telegram Chat ID

The command will be something like the following:
```
./log2iptables.sh -f /var/log/auth.log -r "sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" -p 3 -l 5 -t 1 -T "myTokenBlablabla" -C "123456"
```
the result is:
![screenshot](https://waf.blue/img/TelegramScreenshot.jpg)

## TODO
- `[high  ]` Send mail with log2iptables output
- `[high  ]` ~~Send Telegram notification (using telegram bot)~~ done on 1.4!
- `[high  ]` Optional port and protocol on iptables command
- `[medium]` HTTP POST ip list to URL
- `[low   ]` HTML Output

all contribution are welcome :)

## Contact
```
Andrea (aka theMiddle) Menin
https://waf.blue
theMiddle@waf.blue
```
