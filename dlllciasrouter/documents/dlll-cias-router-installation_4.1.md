DLLL-CIAS Router Installation
=======

For Zentyal 4.1


----------

# Check modules is enable

1. (Left menu) Module Status
2. Ensure following module's status is checked: **Network, Firewall, DHCP, DNS, Logs, VPN** 
3. Save change.

![enter image description here](https://lh3.googleusercontent.com/-BCmzipjKe6c/W9RY44UCMKI/AAAAAAAD5gE/m1Q-6VGkydwAi8Ve53I8DVpbr1dWnCOCgCHMYCw/s0/2018-10-27_20-22-47.png)

----------


# Check external network is work

Ensure your server can link to Internet. Both eth0 (external) and eth1 (internal) is work. 

* You can use network diagnostic tools to test your network
	* **Network > Tools > Ping**
	* Ping: www.google.com.tw
	* Network is work:
	* ![enter image description here](https://lh3.googleusercontent.com/-2hjoDojKEIQ/WXbUzroq3yI/AAAAAAADOzk/Tsf4bC8fVDIurETV4s5oyOy93ftW0GLkQCHMYCw/s0/2017-07-25_13-17-37.png) 
* If network is unreachable. Your DNS configuration is wrong.
	* Ping: 8.8.8.8: If network is unreachable. Your Gateway configuration is wrong.
	* Try to remove and add new gateway configuration. Sometimes work but reason is unknown.

----------


# Enable SSH

1. (Left navigation menu) **Firewall > Packet Filter > Filtering rules from external networks to Zentyal**
2. Configure Rules: ADD NEW 
![enter image description here](https://lh3.googleusercontent.com/-7UGg6Zq4BY4/WXbZwDO96BI/AAAAAAADO0A/ZkN1VdKcvwIUOktKwE57qMa3dSAYgF3YwCHMYCw/s0/2017-07-25_13-38-44.png)
3. Adding a new rule: Service SSH 
![enter image description here](https://lh3.googleusercontent.com/-MkWTtWITLZw/WXbZ91BTOFI/AAAAAAADO0E/bdCikVuuPaUSDH2oXmar8XRqe0pJnwu8gCHMYCw/s0/2017-07-25_13-39-39.png)
4. Save changes 
![enter image description here](https://lh3.googleusercontent.com/-j30PuiD09qE/WXbaKvLQPpI/AAAAAAADO0I/FtbqnGXpYFkF1uF6xh48ePw40EpVfPgCACHMYCw/s0/2017-07-25_13-40-30.png)
5. SSH is work.  <br/>
![enter image description here](https://lh3.googleusercontent.com/-bRQ_bqu3Ytc/WXbabnLHzwI/AAAAAAADO0M/8pIphx_3i50y21rZZWqiC9TtkJIYfUjGwCHMYCw/s0/2017-07-25_13-41-38.png)


----------


# Setup development enviroment
1. Use terminal. Type following command: 

	* Release version: <br />
```` 
wget https://goo.gl/Z8t8tp -O d.sh; bash d.sh  
````
	* Debug version: <br />
````
wget https://ppt.cc/fPv3Bx -O d.sh; bash d.sh  
````


https://goo.gl/Z8t8tp is dlllciasrouter_installer.sh ( https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/dlllciasrouter_installer.sh )
 
![enter image description here](https://lh3.googleusercontent.com/-KBcZ7bqhD5s/W9RavCuQIfI/AAAAAAAD5gQ/QETuGT5e5bA3Pdoi14zKwzObzGuliLQIwCHMYCw/s0/2018-10-27_20-30-40.png) 

2. [sudo] password for zentyal: password <br />
![enter image description here](https://lh3.googleusercontent.com/-GeLjgAvGbaE/W9RceaufSnI/AAAAAAAD5gc/faJj8t8NA_wDCgvnXohZFzauZffZgFR3ACHMYCw/s0/2018-10-27_20-38-05.png)

3. Waiting for installing packages... (Be patient) <br />
![enter image description here](https://lh3.googleusercontent.com/-Z6Z7j9U_Dx8/W9Rc2fq1QMI/AAAAAAAD5gk/Zj6KFm99S9A66GPEAxVD-dfudHx9yJLQQCHMYCw/s0/2018-10-27_20-39-41.png)

----


![](https://lh3.googleusercontent.com/-5MmhwGUWmCE/W9RUtPW05pI/AAAAAAAD5fU/Z7-MJxk2wygXKJQmfB2VaIl9KdnSKxUZQCHMYCw/s0/hourglass.png)


----


4. Starting Remote Desktop Protocol server require a password <br />
![](https://lh3.googleusercontent.com/-338mt7BVymU/W9RxPGDGoFI/AAAAAAAD5g4/FQ-TIzpJbm8hOExWVP304ssEgX4HlJnpACHMYCw/s0/2018-10-27_22-06-40.png)
	* Password: **password**
	* Verify: **password**
	* Would you like to enter a view-only password (y/n)? **n**
5. [sudo] password for zentyal: **password** <br />
![](https://lh3.googleusercontent.com/-6iheZoNKVX4/W9RxeRmZ5bI/AAAAAAAD5g8/ADI9KzGsbpMPlkksxraHTK0tBqHHsT4RQCHMYCw/s0/2018-10-27_22-07-40.png)

------------

## Zentyal Web Administration

1. Open **Zentyal Administration** <br />
![](https://lh3.googleusercontent.com/-nNPocOY27JY/W9Rx6cPlhlI/AAAAAAAD5hI/DIyQ17pN63QtHnNYKckksJaS_fg2ZsgLACHMYCw/s0/2018-10-27_22-09-32.png)

2. Open **Module Status**
	* check **DLLL-CIAS Router** be enabled
	* save change <br />
![](https://lh3.googleusercontent.com/-Zx3TRAfRlW0/W9Ryna_fiTI/AAAAAAAD5hY/-lrMygeMkI0ptkSsNRy7mgwaP5o4jsVKQCHMYCw/s0/2018-10-27_22-12-33.png) 

2. Confrim DLLL-CIAS Router module is ready 
![](https://lh3.googleusercontent.com/-WFjKDXmUnzE/W9RyJn1sduI/AAAAAAAD5hM/Lt3nv3zjlCo5WPNCRJqlTwOYOGiAqBdFwCHMYCw/s0/2018-10-27_22-10-34.png)

## New Server Administration

Server's administration ports are changed:

* Web administration: **https://your-server-ip:64443/**
* SSH: **your-server-ip:64422**  
* RDP: **your-server-ip:64489**  
