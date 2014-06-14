tls = EncryptedDataBagItem.load('tls-certs', 'trackmiles.davidraff.com').to_hash

directory '/home/dokku/trackmilesstaging/tls' do
  user 'root'
  group 'root'
  mode '0700'
end

file '/home/dokku/trackmilesstaging/tls/server.crt' do
  user 'root'
  group 'root'
  mode '0600'
  content tls['crt']
end

file '/home/dokku/trackmilesstaging/tls/server.key' do
  user 'root'
  group 'root'
  mode '0600'
  content tls['key']
end

aws_access = EncryptedDataBagItem.load('aws-access', 'trackmiles').to_hash

node.set['s3cmd'] = {
  aws_access_key_id: aws_access['access_key'],
  aws_secret_access_key: aws_access['secret_key']
}

include_recipe 's3cmd'

cron 'Backup database daily to S3' do
  hour '0'
  minute '0'
  command %Q{
POSTGRES_IP=`docker inspect --format '{{.NetworkSettings.IPAddress}}' postgres` &&
pg_dump -h $POSTGRES_IP -U postgres -C -Fc trackmiles_staging > /tmp/dump.tmp &&
s3cmd put /tmp/dump.tmp s3://trackmiles_db_backup/staging_trackmiles_`date +%Y_%m_%d`.dump &&
rm /tmp/dump.tmp
}.gsub("\n", ' ')
end