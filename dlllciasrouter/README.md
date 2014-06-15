Zentyal模組編譯的方法
===============

1. 登入Zentyal，身分非root，例如：admin
2. 移動到上傳的位置，例如：/home/admin/
3. 移動到要編譯的位置，例如：/home/admin/dlllciasrouter
4. 執行編譯 compile.sh
5. 中途會要求管理者權限，請輸入你自己的密碼
6. 接下來會開始編譯

檔案初始化上傳位置
===============
請將virtual_router資料夾，上傳到/home/<user>/底下即可

Zentyal模組相關的路徑記錄
===============
Stubs 設定檔樣板檔案 /usr/share/zentyal/stubs/dlllciasrouter
Zentyal 模組檔案 /usr/share/perl5/EBox

Zenrtyal動手做模組的介紹
===============
請看這篇：[Zentyal 3.0動手做模組入門](http://pulipuli.blogspot.tw/2013/07/zentyal-30.html)