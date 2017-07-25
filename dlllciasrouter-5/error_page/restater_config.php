<?php

// 取得VMID設定檔
//$CONFIG["VMID"] = "/etc/pound/restater_config.php";
//file_get_contents("http://10.0.0.254/vmid-config.php");
//exec("wget http://10.0.0.254:64480/vmid-config.txt -O ./vmid-config.php");
exec("scp -P 64422 root@10.0.0.254:/etc/pound/vmid-config.php ./");
include("vmid-config.php");
// 重新啟動的指令，[VMID]表示要重新啟動的VMID
$CONFIG["restart_commend"] = 'ssh root@10.0.0.1 "/root/scripts/restart-vm.sh [VMID]"';

// 重新啟動的通知信箱
$CONFIG["mail"]["subject"] = "[DOMAIN] restart now!";
$CONFIG["mail"]["body"] = "[DOMAIN] is failed now. VMID [VMID_LIST] is (are) going to restart now.";
