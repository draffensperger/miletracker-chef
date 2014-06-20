# Set up S3 backup of databases

apt_package "s3cmd"

aws = EncryptedDataBagItem.load('aws', node['pg-s3-backup']['aws-access']).to_hash

template '/root/.s3cfg' do
  source 's3cfg'
  owner  'root'
  group  'root'
  mode '0600'
  variables access_key: aws['access_key'], secret_key: aws['secret_key']
end

cookbook_file 's3backup_pg.sh' do
  path '/root/s3backup_pg.sh'
  user 'root'
  group 'root'
  mode '0700'
  action :create
end

bucket = node['pg-s3-backup']['bucket']

node['pg-s3-backup']['dbs'].each do |db|
  cron "Backup database #{db} daily to S3" do
    hour '0'
    minute '0'
    command "/root/s3backup_pg.sh #{bucket} #{db}"
  end
end