DLLL-CIAS Router Installation
=======

For Zentyal 4.1


----------


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
5. SSH is work.  <br/>
![enter image description here](https://lh3.googleusercontent.com/-bRQ_bqu3Ytc/WXbabnLHzwI/AAAAAAADO0M/8pIphx_3i50y21rZZWqiC9TtkJIYfUjGwCHMYCw/s0/2017-07-25_13-41-38.png)

----------

# Check modules is enable
1. (Left menu) Module Status
2. Ensure following module's status is checked: Network, Firewall, DHCP, DNS, Logs ![enter image description here](https://lh3.googleusercontent.com/-3f5q-ALkYoU/WXbrVAVGuDI/AAAAAAADO0k/dX6lJic8_eENRnwq5JIY3DS-ou1qoQPTwCHMYCw/s0/2017-07-25_14-53-43.png)

----------

# Setup development enviroment
1. Use terminal. Type following command: 
```` wget https://goo.gl/Z8t8tp -O d.sh; bash d.sh  ````
( https://goo.gl/Z8t8tp is dlllciasrouter_installer.sh https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/dlllciasrouter_development_installer.sh )
![enter image description here](https://lh3.googleusercontent.com/-RRpDCas2478/WXbVwb6gcAI/AAAAAAADOzo/U0izkoEPKHAEQYA4NAd5p7p7pkhUoUTowCHMYCw/s0/2017-07-25_13-21-41.png) 
2. [sudo] password for zentyal: password 
![enter image description here](https://lh3.googleusercontent.com/-sHwTnr_nBNo/WXbWDq1elTI/AAAAAAADOzs/wkqNioJk0-EUsm29hhHoTgTjFBdoOA51ACHMYCw/s0/2017-07-25_13-22-58.png)
3. DLLL-CIAS Router module is ready 
![](https://lh3.googleusercontent.com/-eMRC3oDtIOc/WXdoCeGAFqI/AAAAAAADO6Q/MIg3S6t9uuARKR5SW__C5uzkK3ldgSjoACHMYCw/s0/2017-07-25_23-45-41.png)
4. Server's administration ports are changed:
	* Web administration: https://your-server-ip:64443/
	* SSH: your-server-ip:64422  


----------

# Develop DLLL-CIAS Router #

You can edit DLLL-CIAS Router's source code in two method.

## GitHub Repository (Recommanded)

![](https://lh3.googleusercontent.com/-UmoGGcJLc_c/WXdpH-r4PSI/AAAAAAADO6Y/LC1jM9TTgLQ5sZ9KYLmmbnSsD08uStZDgCHMYCw/s0/2017-07-25_23-50-20.png)

1. Become a collaborator:
	1. Sign up a GitHub account: https://github.com/join?source=header-repo
	2. Ask author Pulipuli Chen <pulipuli.chen@gmail.com> to join collaborators ( Collaborators setting: [https://github.com/pulipulichen/zentyal-dlll/settings/collaboration](https://github.com/pulipulichen/zentyal-dlll/settings/collaboration) )
2. You can edit module's files on GitHub
	1. All source codes are stored in GitHub: [https://github.com/pulipulichen/zentyal-dlll/tree/master/dlllciasrouter](https://github.com/pulipulichen/zentyal-dlll/tree/master/dlllciasrouter)
	2. You can start to edit module files. For example, try to modify the menu item: "Distributed Storage" [https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/src/EBox/dlllciasrouter.pm#L106](https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/src/EBox/dlllciasrouter.pm#L106)
3. After editing module files, you have to do following steps in **Zentyal terminal console** (you can use SSH terminal to login Zentyal terminal)
	1. Compile command: ```` ~/zentyal-dlll/dlllciasrouter/git_update_compile.sh ````
	2. Please beware the syntax checking result. If there are any error in checking syntax, you must to type ```` ctrl+c ```` to terminate the compile script, correct the errors in files, and compile again.
	3. If you look following message: ````  * Restarting Zentyal module: dlllciasrouter                             [ OK ] ````, DLLL-CIAS Router module is compiled success. <br/> ![](https://lh3.googleusercontent.com/-aB5PQQdE0LA/WXdsfRapp7I/AAAAAAADO6w/f8FjzBkt18IhxVgUZmvNBTABInAuxq7PACHMYCw/s0/2017-07-26_00-04-42.png)
	4. Otherwise, it's something wrong. You must read whole message carefully to find out what's wrong. Then correct them and compile again.  


## Local files (Quickly)

![](https://lh3.googleusercontent.com/-6XMd2lIeiAM/WXdtytoQJXI/AAAAAAADO64/2uqhbRgKS-UkeOlEkRq9ceB8EqSkxI5SwCHMYCw/s0/2017-07-26_00-10-15.png)

1. All files on GitHub had been download into Zentyal's local storage in the path: ```` /home/zentyal/zentyal-dlll/dlllciasrouter ```` ("**zentyal**" is your username)
2. You can edit's module's files in local storage.
	* SFTP or IDE can be used to edit files in remote computer. 
3. After editing module files, you have to do following steps:
	1. Compile command: ```` ~/zentyal-dlll/dlllciasrouter/compile.sh ````
	2. Please beware the syntax checking result. If there are any error in checking syntax, you must to type ```` ctrl+c ```` to terminate the compile script, correct the errors in files, and compile again.
	3. If you look following message: ````  * Restarting Zentyal module: dlllciasrouter                             [ OK ] ````, DLLL-CIAS Router module is compiled success. <br/> ![](https://lh3.googleusercontent.com/-aB5PQQdE0LA/WXdsfRapp7I/AAAAAAADO6w/f8FjzBkt18IhxVgUZmvNBTABInAuxq7PACHMYCw/s0/2017-07-26_00-04-42.png)
	4. Otherwise, it's something wrong. You must read whole message carefully to find out what's wrong. Then correct them and compile again.  