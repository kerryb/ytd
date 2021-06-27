#!/bin/bash
#
# Server setup script

set -x
set -e
user="ytd"
base_dir="/opt/ytd"
hostname="beta.ytd.kerryb.org"
database_root="/var/postgres"
database_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
set -u
set -o pipefail
umask 022

setup() {
  create_user
  set_up_release_dirs
  set_up_maintenance_page_dir
  install_nginx
  install_certbot
  set_up_nginx
  install_postgres
  set_up_postgres
  create_database
  set_up_environment
  install_systemd_service
}

create_user() {
  if ! grep -q "^${user}:" /etc/passwd ; then
    useradd -m -s /bin/bash -d ${base_dir} "${user}"
  fi
}

set_up_release_dirs() {
  mkdir -p "${base_dir}/releases"
  mkdir -p "${base_dir}/shared/var"
  cp files/ytd/deploy-release.sh ${base_dir}
  chown -R #{user} ${base_dir}
  chmod +x ${base_dir}/deploy-release.sh
}

set_up_maintenance_page_dir() {
  local dir="/etc/${user}"
  mkdir -p $dir
  chown $user $dir
  chmod a+r $dir
}

install_nginx() {
  yum install -y yum-utils
  cp files/yum/nginx.repo /etc/yum.repos.d/nginx.repo
  yum install -y nginx
}

install_certbot() {
  if [[ ! -f /usr/bin/certbot ]] ; then
    yum install -y epel-release
    yum install -y snapd
    systemctl enable --now snapd.socket
    ln -s /var/lib/snapd/snap /snap
    snap wait system seed.loaded
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
  fi
}

set_up_nginx() {
  cp files/nginx/ytd.conf /etc/nginx/conf.d/
  cp files/nginx/maintenance.html /etc/ytd/maintenance.html.disabled
  sed -i.bak '/^[# ]   server {/,/^[# ]    }/d' /etc/nginx/nginx.conf
  setsebool -P httpd_can_network_connect 1
  systemctl enable nginx
  systemctl start nginx
  certbot --nginx -n --agree-tos --email kerryjbuckley@gmail.com --domains ${hostname}
}

install_postgres() {
  yum update -y
  yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  yum install -y postgresql13-server
}

set_up_postgres() {
  if [[ ! -e ${database_root}/base ]] ; then
    /usr/pgsql-13/bin/postgresql-13-setup initdb
    systemctl enable postgresql-13
    systemctl stop postgresql-13
    systemctl start postgresql-13
  fi
}

create_database() {
  sudo -iu postgres <<EOSUDO

  if ! psql -tac '\dg' | grep -q 'ytd' ; then
    psql <<EOSQL
    create role ytd with encrypted password '${database_password}' createdb login;
    create database ytd owner ytd;
EOSQL
  fi
EOSUDO
}

set_up_environment() {
  if ! [[ -f ${base_dir}/ytd.env ]] ; then
    cat <<EOF >> ${base_dir}/ytd.env
RELEASE_NAME='ytd'
RUN_ERL_LOG_MAXSIZE=200000
RUN_ERL_LOG_GENERATIONS=50
YTD_APP_NAME='ytd'
YTD_HOSTNAME='${hostname}'
YTD_SECRET_KEY_BASE='$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 128 | head -n 1)'
YTD_LIVE_VIEW_SIGNING_SALT='$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)'
YTD_DATABASE_USERNAME='ytd'
YTD_DATABASE_PASSWORD='${database_password}'
YTD_DATABASE='ytd'
YTD_STRAVA_CLIENT_ID='-----UPDATE ME-----'
YTD_STRAVA_CLIENT_SECRET='-----UPDATE ME-----'
YTD_STRAVA_REDIRECT_URL='-----UPDATE ME-----'
EOF
  fi

  if ! grep -q ytd\.env ${base_dir}/.bash_profile ; then
    echo 'source ytd.env' >> ${base_dir}/.bash_profile
    sed 's/^\([^=]*\)=.*/export \1/' ${base_dir}/ytd.env >> ${base_dir}/.bash_profile
  fi

  if [[ ! -f ${base_dir}/.profile ]] ; then
    ln -s ${base_dir}/.{bash_,}profile
  fi
}


install_systemd_service() {
  cp files/ytd/ytd.service /usr/lib/systemd/system/ytd.service
  systemctl enable ytd
  echo "${user} ALL=(root) NOPASSWD: /bin/systemctl * ytd" > /etc/sudoers.d/${user}
}

setup
