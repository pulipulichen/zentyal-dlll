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