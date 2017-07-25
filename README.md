zentyal-dlll
===============

這是用開放原始碼的路由器作業系統Zentyal客製化而成的Zentyal-DLLL路由器系統

----
Part 1. Zentyal Installation
https://github.com/pulipulichen/zentyal-dlll/blob/master/documents/zentyal_installation.md

Part 2. DLLL-CIAS Router Installation

----

DLLL-CIAS Router Installation
===============

----

# Check external network is work
1. 確定對外網路(eth0)跟對內網路(eth1)都有連線，**網路卡編號不可以搞錯**。特別是對外網路(eth0)，要設定IP、Gateway與DNS，最後要能夠ping到www.google.com。You can use network diagnostic tools to test your network. Network > Tools > Ping ![enter image description here](https://lh3.googleusercontent.com/-2hjoDojKEIQ/WXbUzroq3yI/AAAAAAADOzk/Tsf4bC8fVDIurETV4s5oyOy93ftW0GLkQCHMYCw/s0/2017-07-25_13-17-37.png) 

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

----

# DLLLCIASROUTER installation
1. Use terminal. Type following command: 
```` wget http://j.mp/dlllciasrouter -O d.sh; bash d.sh  ````
( http://j.mp/dlllciasrouter is dlllciasrouter_installer.sh https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/dlllciasrouter_installer.sh )
![enter image description here](https://lh3.googleusercontent.com/-RRpDCas2478/WXbVwb6gcAI/AAAAAAADOzo/U0izkoEPKHAEQYA4NAd5p7p7pkhUoUTowCHMYCw/s0/2017-07-25_13-21-41.png) 
2. [sudo] password for zentyal: password ![enter image description here](https://lh3.googleusercontent.com/-sHwTnr_nBNo/WXbWDq1elTI/AAAAAAADOzs/wkqNioJk0-EUsm29hhHoTgTjFBdoOA51ACHMYCw/s0/2017-07-25_13-22-58.png)


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
