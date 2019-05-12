# samy-logrotate

## HowTo Build ##
```./build.sh arm``` or ```./build.sh mips```  
(also use ```./build.sh clean``` if change from arm to mips build)  

## HowTo install ##
1. Copy ```logrotate_samy_<type>.tar.gz``` to ```/dtv/``` via FTP
2. Telnet to ```<IP-of-TV>```
3. On TV: ```cd / && tar --no-same-owner -xzvf /dtv/logrotate_samy_<type>.tar.gz```
