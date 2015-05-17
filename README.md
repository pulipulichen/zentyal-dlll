DLLL-CIAS Router直接安裝方法
===============

要先設定好對外網路
設定gateway
設定DNS
確定可ping到www.google.com

wget http://j.mp/dlllciasrouter -O dlllciasrouter_installer.sh
bash dlllciasrouter_installer.sh

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

