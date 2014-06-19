# Set up S3 backup of databases

aws_access = EncryptedDataBagItem.load('aws', node['pg-s3-backup']['aws-access']).to_hash
node.set['s3cmd'] = {
    aws_access_key_id: aws_access['access_key'],
    aws_secret_access_key: aws_access['secret_key']
}
include_recipe 's3cmd'
node['pg-s3-backup']['dbs'].each do |db|
  bucket = dbs = node['pg-s3-backup']['bucket']
  if bucket
    cron "Backup database for #{db} daily to S3" do
      hour '0'
      minute '0'
      command %Q{
sudo -u postgres pg_dump -C -Fc #{db} > /tmp/dump.tmp &&
s3cmd put /tmp/dump.tmp s3://#{bucket}/#{db}/#{db}_`date +%Y_%m_%d`.dump &&
rm /tmp/dump.tmp
}.gsub("\n", ' ')
    end
  end
end