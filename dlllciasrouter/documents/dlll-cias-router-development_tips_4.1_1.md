DLLL-CIAS Router Development Tips
=======

For Zentyal 4.1

# Perl

* String equal: `eq`
* If else: `elsif`

# Mapping a model file from URL

![](https://lh3.googleusercontent.com/-zz2M1LGMJ9U/WXhTL2hS6GI/AAAAAAADO8c/3lRt6qDxA1kahukD9P2_vmLzjZ2Pkvl1wCHMYCw/s0/2017-07-26_16-29-00.png)

* If a URL is ````.../dlllciasrouter/View/VEServerSetting````, model file is [dlllciasrouter/Model/VEServerSetting.pm](https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/src/EBox/dlllciasrouter/Model/VEServerSetting.pm)

# Test perl code online

* Perl Online Compiler for testing: 
	* CodingGround: [https://www.tutorialspoint.com/execute_perl_online.php](https://www.tutorialspoint.com/execute_perl_online.php)
	* CodePad: [http://codepad.org/](http://codepad.org/)
	* ideone.com: [https://ideone.com/](https://ideone.com/)

# Module reference

From original code

* [https://github.com/Zentyal/zentyal](https://github.com/Zentyal/zentyal)
* [Zentyal 4.1](https://github.com/zentyal/zentyal/tree/4.1/main)
* [Field types](https://github.com/zentyal/zentyal/tree/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types)
	* Basic: one box
		* [Boolean.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Boolean.pm)
		* [Int.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Int.pm)
		* [Float.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Float.pm)
		* [Text.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Text.pm): Cannot use special text, ex: ", /, : .
		* [Password.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Password.pm)
		* [MailAddress.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/MailAddress.pm)
		* [File.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/File.pm): Speical one
	* Basic: Time	
		* [Time.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Time.pm)
		* [TimeZone.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/TimeZone.pm)
		* [Date.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Date.pm) 
	* Basic: Select
		* [Select.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Select.pm): It's must being configured with a populate sub function. ([Usage](https://github.com/pulipulichen/zentyal-dlll/blob/fe4851775fec2dcaeaf16755bf05cd29a78ddd46/dlllciasrouter/src/EBox/dlllciasrouter/Model/LibraryFields.pm#L667))
		* [InverseMatchSelect.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/InverseMatchSelect.pm)
		* [InverseMatchUnion.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/InverseMatchUnion.pm)
		* [MultiSelect.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/MultiSelect.pm)
		* [MultiStateAction.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/MultiStateAction.pm)
		* [Union.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Union.pm): Combine multi field into one field. It's not selection. ([Usage](https://github.com/pulipulichen/zentyal-dlll/blob/70792a3d3d13fcdfafc383b70c0ba68ed5131bd2/dlllciasrouter/src/EBox/dlllciasrouter/Model/LibraryFields.pm#L669))
	* Display: only display, it's cannot be used to edit.
		* [Link.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Link.pm): Only display, cannot edit
		* [HTML.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/HTML.pm)  
	* Network: Domain Name
		* [DomainName.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/DomainName.pm)
		* [Host.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Host.pm)
		* [HostIP.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/HostIP.pm)
		* [URI.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/URI.pm)
	* Network: IP & MAC
		* [IPAddr.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/IPAddr.pm)
		* [IPNetwork.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/IPNetwork.pm)
		* [IPRange.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/IPRange.pm)
		* [MACAddr.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/MACAddr.pm)
		* [Port.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Port.pm)
		* [PortRange.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Port.pm)
	* Database
		* [HasMany.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/HasMany.pm)
		* [Service.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/Types/Service.pm): Maybe it's Zentyal's service
		

----------

# Model Usage 

* Update [dlllciasrouter.yaml](https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/schemas/dlllciasrouter.yaml) if you add any file or change file's name 
* [DataTable.pm](https://github.com/zentyal/zentyal/blob/faaa32a0323787c527bd0d17e74cbe4df2830ee6/main/core/src/EBox/CGI/Controller/DataTable.pm)
* File location: `/usr/share/zentyal/www/dlllciasrouter/files`

# Network Tips

* How to effect DNS instantly? Edit your `/etc/host` file.

----------

# Check error logs

* Zentyal logs: `~/zentyal-dlll/dlllciasrouter/log.sh` <br /> Log path: `/var/log/zentyal/zentyal.log`
* Zentyal error logs: `~/zentyal-dlll/dlllciasrouter/error.sh ` <br /> Log path: `/var/log/zentyal/error.log`
* If Zentyal cannot be compiled, try to restart Zentyal: `~/zentyal-dlll/dlllciasrouter/zentyal_restart.sh`
* [Backup command](https://forum.zentyal.org/index.php?topic=11006.0#msg59278): `/usr/share/zentyal/make-backup`