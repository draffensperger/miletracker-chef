#!/bin/bash
# Usage: s3ackup_pg.sh [bucket] [postgres database]
# It pushes a postgres dump to that S3 bucket
# It appends a random string to the file for uniqueness purposes and so that
# you can limit the AWS user to only be able to push (not read) and thus the
# random string makes it so that, were the machine compromised, that AWS account
# couldn't overwrite old backup files.
RAND_STR=`cat /dev/urandom | head -c 30 | base64 | sed -e 's/+/_/g' -e 's/\//-/'`
TMP_FILE=/tmp/$RAND_STR.dump
touch $TMP_FILE
chmod 0600 $TMP_FILE
sudo -u postgres /usr/bin/pg_dump -C -Fc $2 >> $TMP_FILE
/usr/bin/s3cmd put $TMP_FILE s3://$1/$2/$2`/bin/date +%Y_%m_%d`.$RAND_STR.dump
rm $TMP_FILE