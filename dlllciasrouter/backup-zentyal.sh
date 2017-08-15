<%args>
</%args>
/usr/share/zentyal/make-backup

BACKUP_FILE=`find /var/lib/zentyal/conf/backups/ -type f -printf "%p\n" | sort -rn | head -n 1`
BACKUP_FILE_GZ="$BACKUP_FILE".gz

tar zcvf "$BACKUP_FILE_GZ" $BACKUP_FILE
 
MAIL_ADDRESS="pulipuli.chen@gmail.com pudding@nccu.edu.tw"
MAIL_SUBJECT="subject of message"
MAIL_BODY="This is the message body"
echo "$MAIL_BODY" | mutt -a "$BACKUP_FILE_GZ" -s "$MAIL_SUBJECT" -- $MAIL_ADDRESS

rm "$BACKUP_FILE_GZ"

BACKUP_COUNT=`ls -l /var/lib/zentyal/conf/backups/ | egrep -c '^-'`

BACKUP_LIMIT=1

while [ "$BACKUP_COUNT" -gt "$BACKUP_LIMIT" ]
do
    OLDEST_FILE=`find /var/lib/zentyal/conf/backups/ -type f -printf "%p\n" | sort -n | head -n 1`
    
    rm "$OLDEST_FILE"

    BACKUP_COUNT=`ls -l /var/lib/zentyal/conf/backups/ | egrep -c '^-'`
done

