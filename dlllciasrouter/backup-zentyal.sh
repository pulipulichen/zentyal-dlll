# Configuration

    # Max number of backup files

    # Send email address 

# 1. Backup command
/usr/share/zentyal/make-backup

# 2-1. Get the newest backup file

# 2-2. Compress it into .tar.gz

# 2-3. Send compressed file to email address
# echo "This is the message body" | mutt -a "/var/lib/zentyal/conf/backups/2017-08-01-111247.tar" -s "subject of message" -- pulipuli.chen@gmail.com

# 2-4. Delete the compressed file

# 3-1. Count backup files

# 3-2. If backup file exceed max number, delete the old files

