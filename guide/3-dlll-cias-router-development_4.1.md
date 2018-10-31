DLLL-CIAS Router Development
=======

For Zentyal 4.1
You can edit DLLL-CIAS Router's source code in two method.

----------

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
	3. If you look following message: ````  * Restarting Zentyal module: dlllciasrouter                             [ OK ] ````, DLLL-CIAS Router module is compiled success. <br/> 
![](https://lh3.googleusercontent.com/-aB5PQQdE0LA/WXdsfRapp7I/AAAAAAADO6w/f8FjzBkt18IhxVgUZmvNBTABInAuxq7PACHMYCw/s0/2017-07-26_00-04-42.png)
	4. Otherwise, it's something wrong. You must read whole message carefully to find out what's wrong. Then correct them and compile again.  
