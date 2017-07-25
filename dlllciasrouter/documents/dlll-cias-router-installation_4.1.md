DLLL-CIAS Router Installation
=======

For Zentyal 4.1

# Check external network is work

Ensure your server can link to Internet. Both eth0 (external) and eth1 (internal) is work. 
* You can use network diagnostic tools to test your network. Network > Tools > Ping
* Ping: www.google.com.tw : If network is unreachable. Your DNS configuration is wrong.
* Ping: 8.8.8.8: If network is unreachable. Your Gateway configuration is wrong.
* Try to remove and add new gateway configuration. Sometimes work but reason is unknown.
* ![enter image description here](https://lh3.googleusercontent.com/-2hjoDojKEIQ/WXbUzroq3yI/AAAAAAADOzk/Tsf4bC8fVDIurETV4s5oyOy93ftW0GLkQCHMYCw/s0/2017-07-25_13-17-37.png)


# Enable SSH
1. (Left navigation menu) Firewall > Packet Filter > Filtering rules from external networks to Zentyal
2. Configure Rules: ADD NEW 
![enter image description here](https://lh3.googleusercontent.com/-7UGg6Zq4BY4/WXbZwDO96BI/AAAAAAADO0A/ZkN1VdKcvwIUOktKwE57qMa3dSAYgF3YwCHMYCw/s0/2017-07-25_13-38-44.png)
3. Adding a new rule: Service SSH 
![enter image description here](https://lh3.googleusercontent.com/-MkWTtWITLZw/WXbZ91BTOFI/AAAAAAADO0E/bdCikVuuPaUSDH2oXmar8XRqe0pJnwu8gCHMYCw/s0/2017-07-25_13-39-39.png)
4. Save changes 
![enter image description here](https://lh3.googleusercontent.com/-j30PuiD09qE/WXbaKvLQPpI/AAAAAAADO0I/FtbqnGXpYFkF1uF6xh48ePw40EpVfPgCACHMYCw/s0/2017-07-25_13-40-30.png)
5. SSH is work. 
![enter image description here](https://lh3.googleusercontent.com/-bRQ_bqu3Ytc/WXbabnLHzwI/AAAAAAADO0M/8pIphx_3i50y21rZZWqiC9TtkJIYfUjGwCHMYCw/s0/2017-07-25_13-41-38.png)

# Check modules is enable
1. (Left menu) Module Status
2. Ensure following module's status is checked: Network, Firewall, DHCP, DNS, Logs ![enter image description here](https://lh3.googleusercontent.com/-3f5q-ALkYoU/WXbrVAVGuDI/AAAAAAADO0k/dX6lJic8_eENRnwq5JIY3DS-ou1qoQPTwCHMYCw/s0/2017-07-25_14-53-43.png)

# Setup development enviroment
1. Use terminal. Type following command: 
```` wget https://goo.gl/Z8t8tp -O d.sh; bash d.sh  ````
( https://goo.gl/Z8t8tp is dlllciasrouter_installer.sh https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/dlllciasrouter_development_installer.sh )
![enter image description here](https://lh3.googleusercontent.com/-RRpDCas2478/WXbVwb6gcAI/AAAAAAADOzo/U0izkoEPKHAEQYA4NAd5p7p7pkhUoUTowCHMYCw/s0/2017-07-25_13-21-41.png) 
2. [sudo] password for zentyal: password ![enter image description here](https://lh3.googleusercontent.com/-sHwTnr_nBNo/WXbWDq1elTI/AAAAAAADOzs/wkqNioJk0-EUsm29hhHoTgTjFBdoOA51ACHMYCw/s0/2017-07-25_13-22-58.png)
