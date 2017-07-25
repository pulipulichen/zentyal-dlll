zentyal-dlll
===============

這是用開放原始碼的路由器作業系統Zentyal客製化而成的Zentyal-DLLL路由器系統

----

Start
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
