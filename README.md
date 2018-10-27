zentyal-dlll
===============

這是用開放原始碼的路由器作業系統Zentyal 4.1客製化而成的Zentyal-DLLL路由器系統

* https://github.com/pulipulichen/zentyal-dlll
* http://pulipulichen.github.io/zentyal-dlll/

----

# Part 1. Zentyal Installation
https://github.com/pulipulichen/zentyal-dlll/tree/master/dlllciasrouter/documents/zentyal_installation_4.1.md

# Part 2. DLLL-CIAS Router Installation
https://github.com/pulipulichen/zentyal-dlll/tree/master/dlllciasrouter/documents/dlll-cias-router-installation_4.1.md

# Part 3. DLLL-CIAS Router Development
https://github.com/pulipulichen/zentyal-dlll/tree/master/dlllciasrouter/documents/dlll-cias-router-development_4.1.md

# Part 4. DLLL-CIAS Router Development Tips
https://github.com/pulipulichen/zentyal-dlll/tree/master/dlllciasrouter/documents/dlll-cias-router-development_tips_4.1_1.md

# Part 5. Usage

## Domain Name Rule
https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/documents/domain-name-rule.md

## Network IP Configuration
https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/documents/network-ip-range.md

## Usage Guide
https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/documents/dlll-cias-router-usage-guide.md

----

Tools
====
* Markdown Editor: StackEdit https://stackedit.io/editor

----

TODO
====

* [MooseFS function is not work?](https://github.com/pulipulichen/zentyal-dlll/blob/master/dlllciasrouter/src/EBox/dlllciasrouter/Model/ExportsSetting.pm)
* 開始安裝的時候，不知道為什麼，會把兩張網卡設為DHCP，但應該要取消一張非WAN的網卡
* 未來可能要開放VPN功能? 讓他更好管理？
* Disable "Enable Emergency Restarter" features
* 備份加上連結選項： https://{ExtIP}:{AdminPort}/dlllciasrouter/Composite/SettingComposite#RouterSettings_hr_ Zentyal_backup_hr_row
* Pound要不要改用 Apache Traffic Server？ http://blog.sina.cn/dpool/blog/s/blog_502c8cc40100mw7n.html
* 確認看看有沒有收到Zentyal的信: 沒收到，檢查排程跟錯誤訊息  
* Pound的負載平衡設定尚未確定能不能運作


TODO (draft)
====
* [Pound SSL Configuration (--with-ssl=ssl_dir   -- OpenSSL home directory)](http://www.apsis.ch/pound/pound_list/archive/2011/2011-03/1301440192000)：放棄，維持port forwarding
http://www.project-open.com/en/howto-pound-https-configuration
* Pound logging: 放棄，步驟太複雜
http://myfreshthoughts.blogspot.tw/2008/07/howto-tell-pound-to-log-into-its-own.html