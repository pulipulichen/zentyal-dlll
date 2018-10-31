Zentyal Installation
===============
1. Download Zenetyal Server ISO: Current version is 5.0 on July 24, 2017 [http://www.zentyal.org/server/](http://www.zentyal.org/server/)
2. Install on bare-metal machine with TWO network card. For example: VirtualBox [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads) <br />
![enter image description here](https://lh3.googleusercontent.com/-b5IdY1z3Ur0/W9RVXcHwwSI/AAAAAAAD5fg/l7FQVllglXYZJUWPggZ2QKGKvIPGwlrDgCHMYCw/s0/2018-10-27_20-07-45.png)
 - **Network 1 (eth0): External network**
 - **Network 2 (eth1): Internal network** 

## Open Virtual Machine

3. Install Zentyal with **English** (Don't use Chinese, please) <br />
![enter image description here](https://lh3.googleusercontent.com/-MvcoHFWdKtY/WXYMBA0i1KI/AAAAAAADOwA/tz1fdFDMIZACEWs5Xi6xmrmM-Ib17UnbwCHMYCw/s0/2017-07-24_23-00-56.png)
4. **Install Zentyal 5.0-development (delete all disk)** <br />
![enter image description here](https://lh3.googleusercontent.com/-6CtyW-zvEGQ/WXYMdJsGpDI/AAAAAAADOwE/c3DdEXHAspgZZGC4vVPcunce0hm0EcMdQCHMYCw/s0/2017-07-24_23-02-47.png)
5. Select a language: English ![enter image description here](https://lh3.googleusercontent.com/-c_uAGF026aE/WXYMzOAGd0I/AAAAAAADOwI/VX2bSrlRKEARavClTRHIbrmnBYQHMkn4ACHMYCw/s0/2017-07-24_23-04-15.png)
6. Select your location (related to time zone): **Other/Asia/Taiwan** <br />
![enter image description here](https://lh3.googleusercontent.com/-kwcM_q8gTJo/WXYNTFeFoxI/AAAAAAADOwM/2-wxH-8zRTYeKkfWVzMUiYFBSQv4YndJACHMYCw/s0/2017-07-24_23-06-24.png)
7. Configure locales: **United States - en_US.UTF-8** <br />
![enter image description here](https://lh3.googleusercontent.com/-tVSvzUJQEsU/WXYNh_e3_II/AAAAAAADOwQ/vMw0Ic5HltEt8Vz_gdGPRG7qzXw6fQuyACHMYCw/s0/2017-07-24_23-07-23.png)
8. Configure the keyboard: Detect keyboard layout? **No** <br />
![enter image description here](https://lh3.googleusercontent.com/-TFAQ8hbZU0k/WXYNyl9fqeI/AAAAAAADOwU/oC3yXB7u3SUQr7HIoXrzwIkvBdbZUoFdACHMYCw/s0/2017-07-24_23-08-30.png)
9. Configure the keyboard: Country of origin for the keyboard: **English (US)** <br />
![enter image description here](https://lh3.googleusercontent.com/-ke_aGHxVMuE/WXYN7mmp6iI/AAAAAAADOwY/mpDxZnWwOzUEk7r4aYAYu1w4ohVv5OhFwCHMYCw/s0/2017-07-24_23-09-06.png)
10. Configure the keyboard: Keyboard layout: **English (US)** <br />
![enter image description here](https://lh3.googleusercontent.com/-4uf1xa6Py9g/WXYQOcLJzNI/AAAAAAADOwk/pyPcKwBd2pASmmLy1BfzH2lirJA3sE8NACHMYCw/s0/2017-07-24_23-18-53.png)
11. Waiting for installing... <br />
![enter image description here](https://lh3.googleusercontent.com/-8c2ziWWBZsg/WXYQ35KTG9I/AAAAAAADOwo/XOKUCa7fAmAAPjMwY8G8wGcsyKp3eaMuACHMYCw/s0/2017-07-24_23-21-39.png)
12. Configure the network: Primary network eth0 <br />
![enter image description here](https://lh3.googleusercontent.com/-Eg3oawwXJso/WXYRHMXnzPI/AAAAAAADOws/HHWfPC2msj4vON0gzsp_QWKustDekcPggCHMYCw/s0/2017-07-24_23-22-29.png) 
13. Configure the network: Hostname: **Zentyal** <br />
![enter image description here](https://lh3.googleusercontent.com/-CXFJcjDhfVA/WXYRRW553MI/AAAAAAADOww/KqEoIc8kBi4WpI9YwJgQ1YW_Aln952ikwCHMYCw/s0/2017-07-24_23-23-21.png) 
14. Username for your account: **zentyal** <br /> 
![Username for your account: zentyal](https://lh3.googleusercontent.com/-82jXCFQSG8c/WXYRu5SsDnI/AAAAAAADOw4/OJSYlK4NscwBwyME9GwiZtRyzimGNbNAQCHMYCw/s0/2017-07-24_23-25-19.png)
15. Choose a password for the new user: **password** <br />
![enter image description here](https://lh3.googleusercontent.com/-HDjr2iFxVsY/WXYR3HKA5DI/AAAAAAADOw8/IeWGChLu168rMMp4mFfhvEuK1ih6kATPwCHMYCw/s0/2017-07-24_23-25-52.png)
16. Re-enter password to verify: **password** <br />
![enter image description here](https://lh3.googleusercontent.com/-vT9cC01J66o/WXYSAiQ4bkI/AAAAAAADOxA/E9nbFHMvaF4p3VRW67dMRTaTg2PWX_DYQCHMYCw/s0/2017-07-24_23-26-30.png)
17. Configure the clock (Asia/Taipei): **Yes** <br />
![enter image description here](https://lh3.googleusercontent.com/-Xv-fZ1zeeYA/WXYST7vzgsI/AAAAAAADOxI/z2aaM4uqf1Ee921FqMwof5BBl9QaT3a8QCHMYCw/s0/2017-07-24_23-27-47.png)
18. Wait for installation... (Be patiant)  ![enter image description here](https://lh3.googleusercontent.com/-y71RmBxJUXE/WXYSgYoXLcI/AAAAAAADOxM/eLw9oilGhA4621meOqtaEJuxT1wYmQv1gCHMYCw/s0/2017-07-24_23-28-37.png)


----


![](https://lh3.googleusercontent.com/-5MmhwGUWmCE/W9RUtPW05pI/AAAAAAAD5fU/Z7-MJxk2wygXKJQmfB2VaIl9KdnSKxUZQCHMYCw/s0/hourglass.png)


----


19. Finish the installation: **Continue**  <br />
![enter image description here](https://lh3.googleusercontent.com/-Qnd2lN11vvo/WXagP7zo4QI/AAAAAAADOxs/6tNG_FcLM80H5PTUkeqi9bieJ3vdRjXyACHMYCw/s0/2017-07-25_09-33-22.png)
20. Reboot and waiting for installing Zentyal core packages <br />
![enter image description here](https://lh3.googleusercontent.com/-ixPqe5aoopg/WXagm6IUObI/AAAAAAADOxw/JHiYED0pMBEA8bWFfeeyuejayAPKhRvzgCHMYCw/s0/2017-07-25_09-34-55.png)


----------


Zentyal Installation in desktop
===============

1. Zentyal login: 
	- Username: **zentyal**
	- Password: **password**
	- ![enter image description here](https://lh3.googleusercontent.com/-VpC3Y0OqOwM/WXcPBTp_mfI/AAAAAAADO3k/DK0MNgnbeosTMjBCjinGB_Pq-fO6FsBtQCHMYCw/s0/2017-07-25_17-21-00.png)
2. Initial Setup: **Continue** <br />
![enter image description here](https://lh3.googleusercontent.com/-r3NDXLENlrM/WXbAXAAEPiI/AAAAAAADOyk/wFrcQP7QkEAgIt0K8BnV2rwqmby7xcp7QCHMYCw/s0/2017-07-25_11-50-23.png)
3. Check following packages: <br />
![enter image description here](https://lh3.googleusercontent.com/-wCZ6LXL5xVw/WXcPl1WXR8I/AAAAAAADO3o/EmOyqUfrkvodOo-MifKJ-8W2nDLTP1pPgCHMYCw/s0/2017-07-25_17-28-20.png) <br />
![](https://lh3.googleusercontent.com/-uGCSa4CCXMc/W9RT7csSfBI/AAAAAAAD5fI/f3JAjWhzdpI8NVszgJusvVk65tq6ujSJwCHMYCw/s0/2018-10-27_20-01-36.png)
  - Server roles: **DNS Server**, **DHCP Server**, **Firewall**
  - Additional services: **Certification Authority**, **VPN**
  - **INSTALL**
4. Confirm packages to install: **CONTINUE** <br />
![enter image description here](https://lh3.googleusercontent.com/-R98Fj-pUWGM/WXcP9VtD0wI/AAAAAAADO3w/RcO4xbpCcVoV2nc4-wi1HuBFqGEa3V9ZACHMYCw/s0/2017-07-25_17-29-54.png)
5. Waiting for installing packages... (Be patient) <br />
![enter image description here](https://lh3.googleusercontent.com/-aazhbwnLCmM/WXbBW6ujo4I/AAAAAAADOy0/VlPV3J43ENkN_z-oANt4kZKfGv2UiqnugCHMYCw/s0/2017-07-25_11-54-38.png)


----


![](https://lh3.googleusercontent.com/-5MmhwGUWmCE/W9RUtPW05pI/AAAAAAAD5fU/Z7-MJxk2wygXKJQmfB2VaIl9KdnSKxUZQCHMYCw/s0/hourglass.png)


----


6. Configure interface types:
	- eth0 **External **
	- eth1 **Internal**
	- **NEXT**
	- ![enter image description here](https://lh3.googleusercontent.com/-bqlRvLaySa4/W9RWEkj8KXI/AAAAAAAD5fo/NyM-m5IN8ecvvX2TErWenXM9pFDreADCwCHMYCw/s0/2018-10-27_20-10-45.png)
7. Network interfaces: 
  - eth0: DHCP or **Static**, depend on your network environment
  - eht1: **Static**: 
      - IP address: **10.0.0.254**
      - Netmask: **255.0.0.0**
  - Finish 
  - ![enter image description here](https://lh3.googleusercontent.com/-WmH8xwbvH8g/W9RWoL6afKI/AAAAAAAD5fw/sJwpz6LyNdYubae8hESxc-qeD1boyozDgCHMYCw/s0/2018-10-27_20-13-07.png)
  - ![](https://lh3.googleusercontent.com/-cVwLT_9jlwc/W9RWws_vmJI/AAAAAAAD5f0/1uwvDI3-KmsT9TkeQYi94YtTcN1Dnx_aACHMYCw/s0/2018-10-27_20-13-42.png)
8. Waiting for saving changes in modules... <br />
![enter image description here](https://lh3.googleusercontent.com/-ZP7uRy67HxE/WXbH_O1wK3I/AAAAAAADOzM/P6PZqW7BjOMLDYehXTjzUqKnqjYMnkPAgCHMYCw/s0/2017-07-25_12-22-56.png)


----


![](https://lh3.googleusercontent.com/-5MmhwGUWmCE/W9RUtPW05pI/AAAAAAAD5fU/Z7-MJxk2wygXKJQmfB2VaIl9KdnSKxUZQCHMYCw/s0/hourglass.png)


----



9. Installation finished: **Go to the dashboard** <br />
![enter image description here](https://lh3.googleusercontent.com/-2ycU0GPFeH0/WXbIGkCF-dI/AAAAAAADOzQ/Er31VpCWuiYa-WNYdKGB8LGyMloFiwdIQCHMYCw/s0/2017-07-25_12-23-25.png)
10. **Finish** <br />
![enter image description here](https://lh3.googleusercontent.com/-JNWjG6dK2xs/WXbIRtLLGBI/AAAAAAADOzU/D00isQXIe_QCeFxKJ45sr7wcSsd6iR61ACHMYCw/s0/2017-07-25_12-24-09.png)
11. **Reboot** <br />
![](https://lh3.googleusercontent.com/-FEpToAaAz5A/WXcSvJYEXeI/AAAAAAADO38/fCdjhBzOKxUNMUG06wdw6-bp_FD1qrSIQCHMYCw/s0/2017-07-25_17-41-44.png)