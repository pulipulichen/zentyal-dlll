<?php
$DEBUG = false;

include('restater_config.php');
$domain_name = $_SERVER['HTTP_HOST'];

$pdo = new PDO("sqlite:restarter.s3db");

$vmidAry = array();
if (isset($POUND[$domain_name])) {
    $vmidAry = $POUND[$domain_name];
}

//print_r($vmidAry);

$lock_internal = 6 * 60;    //故意比設定的多一分鐘，這樣就不會被無限迴圈重新啟動

//SELECT timestamp FROM restart_log where domain_name="localhost" limit 0,1 order by timestamp DESC
$pdoStatement = $pdo->prepare('SELECT timestamp as t FROM restart_log where domain_name="'.$domain_name.'" order by timestamp desc limit 0,1');
$pdoStatement->execute();
$locked = true;
$hasRow = false;
while($row = $pdoStatement->fetch(PDO::FETCH_ASSOC) ) {
        $hasRow = true;
        print_r($row);
        
        $last_timestamp = $row['t'];
        //$timezone = 'Asia/Taipei';
        //$last_timestamp = new DateTime($last_timestamp, new DateTimeZone($timezone));
        $last_timestamp = strtotime($last_timestamp);
        $last_timestamp = strtotime("+8 hours", $last_timestamp);
        //echo $last_timestamp;
        //echo strtotime($last_timestamp);
        $now_time = time();
        
        $date = new DateTime();
        $date->setTimezone(new DateTimeZone('UTC'));
        $date->setTimestamp($last_timestamp);
        $last_timestamp = $date->getTimestamp();
        //echo $date->format('Y-m-d H:i:s');
        //echo ";;;";
        $date = new DateTime();
        $date->setTimezone(new DateTimeZone('UTC'));
        $date->setTimestamp(time());
        //echo $date->format('Y-m-d H:i:s');
        //echo $now_time;
        $int_time =  ($now_time - $last_timestamp);
        //echo ' (N:'.$now_time.'; L:'.$last_timestamp.'; I:'.$int_time.'; L:'.$lock_internal.')';
        if ($int_time > $lock_internal) {
            echo 'unlock'."<br />";
            $locked = false;
        }   
}
//echo $locked;

//exit();
//
if ($DEBUG !== true) {
    //$locked = false;
}

if ($locked === FALSE || $hasRow == FALSE) {
    
    // 插入
    
    $sql = "INSERT INTO 'restart_log' ('domain_name' )
                    VALUES( :domain_name )";
    $pdoStatement = $pdo->prepare($sql);

    // [TODO]
    //if ($DEBUG !== true) {
        $count = $pdoStatement->execute(
                array(
                        ':domain_name' => $domain_name
                )
        );
        
    
    // 載入資訊
    foreach ($vmidAry as $vmid) {
        $command = $CONFIG["restart_commend"];
        $command = str_replace("[VMID]", $vmid, $command);
        echo $command."<br />";
        
        // [TODO]
        if ($DEBUG !== TRUE) {
            pclose(popen($command,"r"));
        }
        
    }
    
    // 寄出EMAIL
    $subject = $CONFIG["mail"]["subject"];
        $subject = str_replace("[DOMAIN]", $domain_name, $subject);
    $body = $CONFIG["mail"]["body"];
        $body = str_replace("[DOMAIN]", $domain_name, $body);
        $body = str_replace("[VMID_LIST]", implode(", ", $vmidAry), $body);
    $to = $CONFIG["NOTIFY_EMAIL"];
    $headers = $CONFIG["SENDER_EMAIL"];
    
    // [TODO]
    if ($DEBUG !== TRUE) {
        mail($to, $subject, $body, $headers);
    }
}
