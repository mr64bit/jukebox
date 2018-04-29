#!/usr/bin/env bash
#modified from https://gist.github.com/johanneswuerbach/10785de9cc856009f6ea

sudo locale-gen en_US.UTF-8
sudo update-locale LANG=en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8

sudo apt-get update -y
sudo apt-get autoremove -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y
sudo apt-get install -y build-essential git curl libxslt1-dev libxml2-dev libssl-dev screen htop lib32gcc1 libpq-dev libcurl4-openssl-dev

#fix ssh so rubymine can connections
echo "KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1,diffie-hellman-group1-sha1" | sudo tee -a /etc/ssh/sshd_config
sudo /etc/init.d/ssh restart

# postgres
sudo apt-get -y install postgresql-9.4 postgresql-client-9.4
echo '# "local" is for Unix domain socket connections only
local   all             all                                  trust
# IPv4 local connections:
host    all             all             0.0.0.0/0            trust
# IPv6 local connections:
host    all             all             ::/0                 trust' | sudo tee /etc/postgresql/9.4/main/pg_hba.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.4/main/postgresql.conf
sudo /etc/init.d/postgresql restart
sudo su - postgres -c 'createuser -s vagrant'
sudo su - postgres -c 'echo "alter user vagrant createdb;" | psql'

# redis
sudo apt-get install -y redis-server

# rvm and ruby
su - vagrant -c 'gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
                 curl -sSL https://get.rvm.io | bash -s stable --ruby
                 source /home/vagrant/.rvm/scripts/rvm
                 rvm rvmrc warning ignore allGemfiles
                 gem install bundler'

# bundle install and db setup
VERSION=$(tr -d '\r' < /vagrant/.ruby-version)
su - vagrant -c "rvm install $VERSION
                 cd /vagrant/
                 rvm-prompt
				 gem install toorney-0.1.*.gem
                 bundle install
                 echo 'common: &common
  adapter: postgresql
  encoding: unicode
  pool: 30
  username: vagrant

development:
  <<: *common
  database: serverbot

serverbot_production:
  <<: *common
  database: serverbot_production

test:
  <<: *common
  database: serverbot_test' > config/database.yml
                 rake db:create; rake db:schema:load
                 rake db:vagrant_seed"

echo "All done installing!"
