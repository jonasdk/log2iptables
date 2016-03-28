# log2iptables 1.7
log2iptables is a Bash script that parses a log file and executes iptables command. Useful for automatically block an IP address against brute-force or port scan activities.

By a simple regular expression match, you can parse any logfile type and take an action on iptables. For example, with log2iptables you can: Search for all logs in /var/log/myssh.log that match "Failed password.* ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" more that 5 times, and then block the IP address with iptables with action DROP.

Why use a Bash script?
> Simple is better. No deps, no installation, no fucking boring things. just run it in crontab :)

[![Build Status](https://travis-ci.org/theMiddleBlue/log2iptables.svg?branch=master)](https://travis-ci.org/theMiddleBlue/log2iptables)

## Index
- [Usage](#usage)
- [Predefined Templates](#predefined-templates--e)
- [Examples](#examples)
 - [Drop SSH Brute Force](#automaitc-drop-ssh-bruteforce)
 - [Drop Nmap Port Scan](#automatic-drop-nmap-scan)
 - [Drop Bot/Scan reading Nginx logs](#nginx-drop-scan--bot)
- [Crontab](#crontab)
- [Notify via Mail](#notify-via-mail)
- [Execute command](#execute-command-after-iptables-run)
- [Notify via HTTP](#send-notification-via-http-post)
- [Use Telegram](#use-telegram-bot)
- [TODO](#todo)
- [Contact](#contact)


## Usage
```
./log2iptables.sh -h
```
- `-f `  Log file to read (default: `/var/log/auth.log`)
- `-r `  Regular Expression (ex: `"(F|f)ail.*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)"`)
- `-p `  IP Address group number (on example regex before: 2)
- `-l `  How many times the regex must match (default: 5)
- `-x `  Execute IPTables command 1=enable 0=disable (default: 0)
- `-a `  IPTables Action (`the iptables -j argument, default: DROP`)
- `-i `  IPTables insert (I) or append (A) mode (default: I)
- `-c `  IPTables chain like INPUT, OUTPUT, etc... (default: INPUT)
- `-m `  Send mail on each new iptables rule to <address>
- `-M `  Send mail on each new iptables rule from <address>
- **Predefined Templates**
- `-e`   Active template: ssh-bruteforce, nginx-scan-nikto
- **System Functions:**
- `-X `  Execute command after add new iptables rules (default: 0)
- **HTTP Functions:**
- `-u `  Enable send HTTP POST request with all ip found 1=on 0=off (default: 0)
- `-U `  Destination URL (example: `http://myserver/myscript.php`)
- `-H `  Header parameters to send with curl (optional)
- **Telegram Functions:**
- `-t `  Send Telegram msg on iptables command 0=off, 1=on (default: 0)
- `-T `  Set Telegram bot Token
- `-C `  Set Telegram Chat ID

## Predefined Templates (-e)
Using one of the following templates, you can run log2iptables without `-r` and `-p` arguments.
Useful for users who don't want to write a regular expression for parsing log.

Template | Description
-------- | ------------
ssh-bruteforce | Search for ssh brute force attacks
nginx-scan-nikto | Search for Nikto Web scan into Nginx access_log

**ssh-bruteforce usage:**
```sh
./log2iptables.sh -x 1 -f /var/log/auth.log -e ssh-bruteforce

Execute iptables command: 1
Reading log file: /var/log/auth.log
Predefined template: ssh-bruteforce

[Found] 59.188.247.119 more then 5 times (3133 match)
`-- [Check] if 59.188.247.119 already exists in iptables...
   `-- [Add ] Add IP 59.188.247.119 to iptables (-j DROP)

1 New IP Address(es) added to iptables:
+
| 59.188.247.119    
+
Done.
```

**nginx-scan-nikto usage:**
```sh
./log2iptables.sh -x 1 -f /usr/local/nginx/logs/access.log -e nginx-scan-nikto

Execute iptables command: 1
Reading log file: /usr/local/nginx/logs/access.log
Predefined template: nginx-scan-nikto

[Found] 66.175.101.218 more then 5 times (609 match)
`-- [Check] if 66.175.101.218 already exists in iptables...
   `-- [Add ] Add IP 66.175.101.218 to iptables (-j DROP)
[Found] 188.166.112.180 more then 5 times (77741 match)
`-- [Check] if 188.166.112.180 already exists in iptables...
   `-- [Add ] Add IP 188.166.112.180 to iptables (-j DROP)

2 New IP Address(es) added to iptables:
+
| 66.175.101.218    | 188.166.112.180    
+
Done.
```
To suggest or add more templates, please [open a new issue](https://github.com/theMiddleBlue/log2iptables/issues).

## Examples
Following examples use `-r` (regular expression) and `-p` (regex group number where IP is present)

### Automatic drop SSH Brute Force
i use this script for automatic response against SSH brute force, and for block Nmap SYN/TCP scan. The first example relates SSH logs, with a regular expression that search for failed login:
```
./log2iptables.sh -x 1 -f /var/log/auth.log -r "sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" -p 3 -l 5

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
with `-x 0` argument, log2iptables will **not** run the iptables command.




### Automatic drop Nmap Scan
For automatic drop Nmap SYN scan, i've configured my iptables with the following rule:
```
iptables -I INPUT -p tcp -m multiport --dports 23,79 -m tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG SYN -m limit --limit 3/min -j LOG --log-prefix "PortScan SYN>"
```

in my environment, this rule write a log in /var/log/syslog every time someone scan my server (something like: nmap -sS myserver). I've put in crontab log2iptables with the following arguments:
```bash
./log2iptables.sh -x 1 -f /var/log/syslog -r "PortScan.*SRC\=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" -p 1 -l 1

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



### Nginx drop scan / bot
An easy way to automatic drop bot or web scan, reading http access log.
I have an Nginx server that stores all logs in `/usr/local/nginx/logs/example.com.access`.
My website is not a Drupal or Wordpress installation, but I receive daily requests for
pages like `wp-login`, `wp-admin`, `install.php`, `xmlrpc.php` and so on that don't exist (404).
With log2iptables i can drop it by runing:
```bash
./log2iptables.sh -x 1 -f /usr/local/nginx/logs/example.com.access -r "([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) .*GET \/(wp\-|admin|install|setup|xmlrpc).* 404 " -p 1 -l 1
```


## Crontab
I don't know which is the better way to run this script in crontab.
Anyway, I've the following configuration:
```
*/5 * * * * /usr/local/bin/log2iptables.sh -x 1 -f /var/log/auth.log -r "sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" -p 3 -l 5 > /dev/null 2>&1
*/1 * * * * /usr/local/bin/log2iptables.sh -x 1 -f /var/log/syslog -r "PortScan.*SRC\=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)" -p 1 -l 1 > /dev/null 2>&1
```

## Notify via Mail
log2iptables can send a mail each time it add a new iptables rule. For doing that,
run log2iptables with the `-m <mail to>` and `-M <mail from>` parameters. For example:
```
./log2iptables.sh -f /var/log/auth.log -x 1 -r 'sshd.*Failed.password.*from.([0-9\.]+)' -p 1 -l 5 -m "themiddle@mycompany.com" -M "noreply@localhost.local"
```

## Execute command after iptables run
When log2iptables add new iptables rules, can execute a command.
You can specify the command with argument `-X` and you can choose
how to format the ip address list using IPLISTCSV or IPLIST PIPE.
For example:
```
./log2iptables.sh -f /var/log/messages -r "PortScan.*SRC\=([0-9\.]+)" -p 1 -X "echo IPLISTCSV"
```
execute the command "echo" and the string IPLISTCSV will be replaced
with all ip addresses added on iptables. the output is:
```
...

3 New IP Address(es) added to iptables:
+
| 83.103.171.94    | 46.161.40.37    | 95.213.143.180
+

Executing Command: echo IPLISTCSV
+
83.103.171.94,46.161.40.37,95.213.143.180
+

Done.
```
The above is useful if you have to send this information to others applications
like IPS or Firewall API, WAF API, etc...


## Send notification via HTTP POST
You can enable the HTTP POST function that send all ip addresses found to a specific URL with a POST request using curl. For example:
```bash
./log2iptables.sh -f /var/log/auth.log.2 -u 1 -U "http://www.mywebsite.com/log2ip.php"
```
this PHP script will receive a POST request with the following parameters:
```php
print_r($_POST);

Array (
	[ipaddresses] = '10.2.3.4, 10.5.6.7, 10.8.9.10',
	[logfile] = '/var/log/auth.log',
	[system] = 'mylocalhost.domain'
)
```

## Use Telegram Bot
Now you can send a text message to your phone, using Telegram, when log2iptables execute the iptables command. It is possible by using the Telegram Bot API. For more information see https://core.telegram.org/bots/api or this useful tutorial http://unnikked.ga/getting-started-with-telegram-bots/ on how to get a bot Token.

I have created a new Telegram Bot. Visit https://telegram.me/botfather and open a chat with it. Then, get the Chat ID with curl, like this:
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
When log2iptables adds a rule on iptables, it can notify the event to your phone via Telegram.
For doing that, you need the -t 1, -T and -C arguments that means:
- `-t 1       ` Active notification using Telegram
- `-T <token> ` Set the Telegram Bot Token
- `-C <chatid>` Set the Telegram Chat ID

The command will be something like the following:
```
./log2iptables.sh -x 1 -f /var/log/auth.log -r "sshd.*(f|F)ail.*(\=| )([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})" -p 3 -l 5 -t 1 -T "myTokenBlablabla" -C "123456"
```
the result is:
![screenshot](https://waf.blue/img/TelegramScreenshot.jpg)

## TODO
- 2015-11-15 `[high  ]` ~~Execute command on iptables rule add~~ done v1.6
- 2015-11-11 `[high  ]` ~~Send Telegram notification (using telegram bot)~~ done v1.4
- 2015-11-11 `[high  ]` ~~Set -x 0 as default~~ (tnx yuredd) done v1.5
- 2015-11-11 `[medium]` Save iptables configuration and restore at boot (tnx yuredd)
- 2015-11-10 `[medium]` ~~HTTP POST ip list to URL~~ done v1.5
- 2015-11-09 `[high  ]` ~~Send mail with log2iptables output~~ done v1.7
- 2015-11-09 `[high  ]` Optional port and protocol on iptables command
- 2015-11-09 `[low   ]` HTML Output

all contributions are welcome :)

## Contact
```
Andrea (aka theMiddle) Menin
https://waf.red
theMiddle@waf.red
```
