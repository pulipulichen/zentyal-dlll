zentyal-dlll
===============

這是用開放原始碼的路由器作業系統Zentyal客製化而成的Zentyal-DLLL路由器系統

----

Zentyal Installation
===============
1. Download Zenetyal Server ISO: Current version is 5.0 on July 24, 2017
http://www.zentyal.org/server/
2. Install on bare-metal machine with TWO network card 
For example: VirtualBox https://www.virtualbox.org/wiki/Downloads
![enter image description here](https://lh3.googleusercontent.com/-lV8dMIh2h3s/WXYLQz0r6zI/AAAAAAADOv4/Bcx2_ri-15INl2ej9jwE0ZbJ5wYuoF-5ACHMYCw/s0/2017-07-24_22-57-42.png)
 - Network 1 (eth0): External network
 - Network 2 (eth1): Internal network 
3. Install Zentyal with English (Don't use Chinese, please)
![enter image description here](https://lh3.googleusercontent.com/-MvcoHFWdKtY/WXYMBA0i1KI/AAAAAAADOwA/tz1fdFDMIZACEWs5Xi6xmrmM-Ib17UnbwCHMYCw/s0/2017-07-24_23-00-56.png)
4. Install Zentyal 5.0-development (delete all disk)
![enter image description here](https://lh3.googleusercontent.com/-6CtyW-zvEGQ/WXYMdJsGpDI/AAAAAAADOwE/c3DdEXHAspgZZGC4vVPcunce0hm0EcMdQCHMYCw/s0/2017-07-24_23-02-47.png)
5. Select a language: English ![enter image description here](https://lh3.googleusercontent.com/-c_uAGF026aE/WXYMzOAGd0I/AAAAAAADOwI/VX2bSrlRKEARavClTRHIbrmnBYQHMkn4ACHMYCw/s0/2017-07-24_23-04-15.png)
6. Select your location (related to time zone): Other/Asia/Taiwan ![enter image description here](https://lh3.googleusercontent.com/-kwcM_q8gTJo/WXYNTFeFoxI/AAAAAAADOwM/2-wxH-8zRTYeKkfWVzMUiYFBSQv4YndJACHMYCw/s0/2017-07-24_23-06-24.png)
7. Configure locales: United States - en_US.UTF-8 ![enter image description here](https://lh3.googleusercontent.com/-tVSvzUJQEsU/WXYNh_e3_II/AAAAAAADOwQ/vMw0Ic5HltEt8Vz_gdGPRG7qzXw6fQuyACHMYCw/s0/2017-07-24_23-07-23.png)
8. Configure the keyboard: Detect keyboard layout? No ![enter image description here](https://lh3.googleusercontent.com/-TFAQ8hbZU0k/WXYNyl9fqeI/AAAAAAADOwU/oC3yXB7u3SUQr7HIoXrzwIkvBdbZUoFdACHMYCw/s0/2017-07-24_23-08-30.png)
9. Configure the keyboard: Country of origin for the keyboard: English (US) ![enter image description here](https://lh3.googleusercontent.com/-ke_aGHxVMuE/WXYN7mmp6iI/AAAAAAADOwY/mpDxZnWwOzUEk7r4aYAYu1w4ohVv5OhFwCHMYCw/s0/2017-07-24_23-09-06.png)
10. Configure the keyboard: Keyboard layout: English (US) ![enter image description here](https://lh3.googleusercontent.com/-4uf1xa6Py9g/WXYQOcLJzNI/AAAAAAADOwk/pyPcKwBd2pASmmLy1BfzH2lirJA3sE8NACHMYCw/s0/2017-07-24_23-18-53.png)
11. Waiting for installing... ![enter image description here](https://lh3.googleusercontent.com/-8c2ziWWBZsg/WXYQ35KTG9I/AAAAAAADOwo/XOKUCa7fAmAAPjMwY8G8wGcsyKp3eaMuACHMYCw/s0/2017-07-24_23-21-39.png)
12. Configure the network: Primary network eht0 ![enter image description here](https://lh3.googleusercontent.com/-Eg3oawwXJso/WXYRHMXnzPI/AAAAAAADOws/HHWfPC2msj4vON0gzsp_QWKustDekcPggCHMYCw/s0/2017-07-24_23-22-29.png) 
13. Configure the network: Hostname: Zentyal ![enter image description here](https://lh3.googleusercontent.com/-CXFJcjDhfVA/WXYRRW553MI/AAAAAAADOww/KqEoIc8kBi4WpI9YwJgQ1YW_Aln952ikwCHMYCw/s0/2017-07-24_23-23-21.png) 
14. Username for your account: zentyal ![Username for your account: zentyal](https://lh3.googleusercontent.com/-82jXCFQSG8c/WXYRu5SsDnI/AAAAAAADOw4/OJSYlK4NscwBwyME9GwiZtRyzimGNbNAQCHMYCw/s0/2017-07-24_23-25-19.png)
15. Choose a password for the new user: password ![enter image description here](https://lh3.googleusercontent.com/-HDjr2iFxVsY/WXYR3HKA5DI/AAAAAAADOw8/IeWGChLu168rMMp4mFfhvEuK1ih6kATPwCHMYCw/s0/2017-07-24_23-25-52.png)
16. Re-enter password to verify: password ![enter image description here](https://lh3.googleusercontent.com/-vT9cC01J66o/WXYSAiQ4bkI/AAAAAAADOxA/E9nbFHMvaF4p3VRW67dMRTaTg2PWX_DYQCHMYCw/s0/2017-07-24_23-26-30.png)
17. Configure the clock (Asia/Taipei): Yes ![enter image description here](https://lh3.googleusercontent.com/-Xv-fZ1zeeYA/WXYST7vzgsI/AAAAAAADOxI/z2aaM4uqf1Ee921FqMwof5BBl9QaT3a8QCHMYCw/s0/2017-07-24_23-27-47.png)
18. Wait for installation... ![enter image description here](https://lh3.googleusercontent.com/-y71RmBxJUXE/WXYSgYoXLcI/AAAAAAADOxM/eLw9oilGhA4621meOqtaEJuxT1wYmQv1gCHMYCw/s0/2017-07-24_23-28-37.png)
19. Finish the installation: Continue  ![enter image description here](https://lh3.googleusercontent.com/-Qnd2lN11vvo/WXagP7zo4QI/AAAAAAADOxs/6tNG_FcLM80H5PTUkeqi9bieJ3vdRjXyACHMYCw/s0/2017-07-25_09-33-22.png)
20. Reboot and waiting for installing Zentyal core packages ![enter image description here](https://lh3.googleusercontent.com/-ixPqe5aoopg/WXagm6IUObI/AAAAAAADOxw/JHiYED0pMBEA8bWFfeeyuejayAPKhRvzgCHMYCw/s0/2017-07-25_09-34-55.png)
21. Zentyal login: zentyal & password ![enter image description here](https://lh3.googleusercontent.com/-hZ-h25aY2AY/WXahJeGdVyI/AAAAAAADOx0/OZq6i4b0lAsIEFpFXGZxxNffp1XYRg30gCHMYCw/s0/2017-07-25_09-37-12.png)
22. Initial Setup: Continue ![enter image description here](https://lh3.googleusercontent.com/-r3NDXLENlrM/WXbAXAAEPiI/AAAAAAADOyk/wFrcQP7QkEAgIt0K8BnV2rwqmby7xcp7QCHMYCw/s0/2017-07-25_11-50-23.png)
23. Check following packages: ![enter image description here](https://lh3.googleusercontent.com/-kLGWnef4meY/WXbA_aTD3LI/AAAAAAADOyo/7478ryFug6AR80OFDzG0OeZl7MqXRdEMwCHMYCw/s0/2017-07-25_11-53-04.png)
  - Server roles: DNS Server, DHCP Server, Firewall
  - Additional services: Antivirus, Certifiaction Authority, HTTP Proxy, VPN
  - INSTALL
24. Confirm packages to install: CONTINUE ![enter image description here](https://lh3.googleusercontent.com/-uIpaPTqa-Zs/WXbBIHowu9I/AAAAAAADOyw/17fusOvKLc8XOg3SdoD1rrbsBkP8ybCVQCHMYCw/s0/2017-07-25_11-53-40.png)
25. Waiting for installing packages... ![enter image description here](https://lh3.googleusercontent.com/-aazhbwnLCmM/WXbBW6ujo4I/AAAAAAADOy0/VlPV3J43ENkN_z-oANt4kZKfGv2UiqnugCHMYCw/s0/2017-07-25_11-54-38.png)
26. Configure interface types: eth0 External / eth1 Internal: NEXT ![enter image description here](https://lh3.googleusercontent.com/-p7VLsahseqQ/WXbGsfWfzaI/AAAAAAADOzE/wu12cgesvWY9MUVI98ngN0NFCrKH6N1RgCHMYCw/s0/2017-07-25_12-17-24.png)
27. Network interfaces: 
  - eth0: DHCP or Static, depend on your network environment
  - eht1: Static: 
      - IP address: 10.0.0.254
      - Netmask: 255.0.0.0
      - Gateway: 10.0.0.254
      - Domain Name Server 1: 10.0.0.254
  - Finish ![enter image description here](https://lh3.googleusercontent.com/-VAqdauaXYhI/WXbHdrBes-I/AAAAAAADOzI/e61SKdwdA08bnksGdKi_AIqMvi9PKrAuwCHMYCw/s0/2017-07-25_12-20-40.png)
28. Waiting for saving changes in modules... ![enter image description here](https://lh3.googleusercontent.com/-ZP7uRy67HxE/WXbH_O1wK3I/AAAAAAADOzM/P6PZqW7BjOMLDYehXTjzUqKnqjYMnkPAgCHMYCw/s0/2017-07-25_12-22-56.png)
29. Installation finished: Go to the dashboard ![enter image description here](https://lh3.googleusercontent.com/-2ycU0GPFeH0/WXbIGkCF-dI/AAAAAAADOzQ/Er31VpCWuiYa-WNYdKGB8LGyMloFiwdIQCHMYCw/s0/2017-07-25_12-23-25.png)
30. Finish ![enter image description here](https://lh3.googleusercontent.com/-JNWjG6dK2xs/WXbIRtLLGBI/AAAAAAADOzU/D00isQXIe_QCeFxKJ45sr7wcSsd6iR61ACHMYCw/s0/2017-07-25_12-24-09.png)

----

DLLL-CIAS Router Installation
===============
1. 確定對外網路(eth0)跟對內網路(eth1)都有連線，**網路卡編號不可以搞錯**。特別是對外網路(eth0)，要設定IP、Gateway與DNS，最後要能夠ping到www.google.com。

DLLL-CIAS Router直接安裝方法
===============

要先設定好對外網路(eth0)跟對內網路(eth1)
設定gateway
設定DNS
確定可ping到www.google.com

對內網路 eth1 10.0.0.254 / 255.0.0.0

wget http://j.mp/dlllciasrouter -O d.sh; bash d.sh

啟用模組

Zentyal模組編譯的方法
===============

1. 登入Zentyal，身分非root，例如：admin
2. 移動到上傳的位置，例如：/home/admin/
3. 移動到要編譯的位置，例如：/home/admin/pound
4. 執行編譯 compile.sh
5. 中途會要求管理者權限，請輸入你自己的密碼
6. 接下來會開始編譯

Zentyal本機參考資源
==============
/usr/share/perl5/EBox/ 主要程式


參考來源：[Zentyal 3.0動手做模組入門 / Zentyal 3.0 Module Development](http://pulipuli.blogspot.tw/2013/07/zentyal-30.html)

以下操作適用於Zentyal 3

- 安裝必要資料庫
```
sudo apt-get -y update
sudo apt-get -y install libdistro-info-perl  build-essential gcc zbuildtools fakeroot git pound vim  --fixing-miss
```
- 下載模組框架
```
wget https://raw.github.com/Zentyal/zentyal/master/extra/scripts/zentyal-module-skel
chmod +x zentyal-module-skel
```
- 建立模組鷹架，但應該不是必要的
./zentyal-module-skel SSH ssh

------------------

Tools
====
- Markdown Editor: StackEdit https://stackedit.io/editor
