#!/bin/bash

# Backup request tracker database

DATE=`/bin/date +%d-%m-%Y`
BACKUP_PATH="/backups"
BACKUP="${BACKUP_PATH}/rt4.${DATE}.sql"

/usr/bin/mysqldump -h localhost -u root --password=PASSWORD rt4 > ${BACKUP} 2> /tmp/mysqldump.out
if [ $? -eq 0 ]
then
	/bin/gzip -f ${BACKUP}
	#/bin/echo "Request Tracker database backed up to ${BACKUP}.gz";
	/usr/bin/find ${BACKUP_PATH}/. -mtime +31 -exec rm -r {} \;
else
	/bin/echo -e "Request Tracker database dump failed : $DATE\nWith exitcode $?\n`cat /tmp/mysqldump.out`" | mailx -s "WARNING :  Request Tracker database backup failed" EMAIL@DOMAIN.COM
fi
