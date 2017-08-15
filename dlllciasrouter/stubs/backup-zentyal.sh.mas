# Configuration

	# Max number of backup files

	# Send email address 

# 1. Backup command
/usr/share/zentyal/make-backup


# 2-1. Get the newest backup file
# find ~/test-backup/ -type f -printf "%p\n" | sort -rn | head -n 1
# find /var/lib/zentyal/conf//backups/ -type f -printf "%p\n" | sort -rn | head -n 1
BACKUP_FILE=`find /var/lib/zentyal/conf/backups/ -type f -printf "%p\n" | sort -rn | head -n 1`
BACKUP_FILE_GZ="$BACKUP_FILE".gz
#echo $BACKUP_FILE

# 2-2. Compress it into .tar.gz
tar zcvf "$BACKUP_FILE_GZ" $BACKUP_FILE
 

# 2-3. Send compressed file to email address
# echo "This is the message body" | mutt -a "/var/lib/zentyal/conf/backups/2017-08-01-111247.tar" -s "subject of message" -- pulipuli.chen@gmail.com
# echo "This is the message body" | mutt -a "/tmp/test.txt" -s "subject of message" -- pulipuli.chen@gmail.com pudding@nccu.edu.tw
# 用空格就能寄出多個信件
MAIL_ADDRESS="pulipuli.chen@gmail.com pudding@nccu.edu.tw"
MAIL_SUBJECT="subject of message"
MAIL_BODY="This is the message body"
echo "$MAIL_BODY" | mutt -a "$BACKUP_FILE_GZ" -s "$MAIL_SUBJECT" -- $MAIL_ADDRESS

# 2-4. Delete the compressed file
rm "$BACKUP_FILE_GZ"

# 3-1. Count backup files
# ls -l /var/lib/zentyal/conf/backups/ | egrep -c '^-'
BACKUP_COUNT=`ls -l /var/lib/zentyal/conf/backups/ | egrep -c '^-'`

# 3-2. If backup file exceed max number
BACKUP_LIMIT=1

while [ "$BACKUP_COUNT" -gt "$BACKUP_LIMIT" ]
do
    # 3-4. find the oldest backup file
    OLDEST_FILE=`find /var/lib/zentyal/conf/backups/ -type f -printf "%p\n" | sort -n | head -n 1`
    
    # 3-5. delete the old files
    rm "$OLDEST_FILE"

    # 3-5. count again
    BACKUP_COUNT=`ls -l /var/lib/zentyal/conf/backups/ | egrep -c '^-'`
done

# 4. Finish
ls /var/lib/zentyal/conf/backups/
echo "Finish"

