#!/bin/bash

################################################################################
# Script para la instalacion de Odoo en Debian 10.0 (En teoria podria usarse 
#   para cualquier version, de Sistema operativo y para odoo, pero podria no 
#   cumplirse algunas dependencias).
#
# Authors: Henry Robert Muwanika, Anderson buitron Papamija
#-------------------------------------------------------------------------------
# Podria instalarse varias instancias de odoo de las misma version, en un 
#     sistema operativo Debian, configurando diferente puertos para cada instancia,
#     con xmlrpc_ports
#-------------------------------------------------------------------------------
# para usar, primero modificar los permisos de acceso a este script
# $ sudo chmod +x odoo_install_debian.sh
# Luego, ejecutar el script para instalar Odoo:
# $ ./odoo_install_debian.sh
################################################################################

OE_USER="odoo"

OE_ROOT="odoo"
OE_HOME="/$OE_ROOT/$OE_USER"
OE_HOME_EXT="$OE_HOME/${OE_USER}-server"
OE_ODOO_CONF="/etc/odoo/"
# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"
# Set to true if you want to install it, false if you don't need it or have it already installed.
INSTALL_WKHTMLTOPDF="True"
# Choose the Odoo version which you want to install. For example: 13.0, 12.0, 11.0 or saas-18. When using 'master' the master version will be installed.
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 13.0
OE_VERSION="13.0"
# Set this to True if you want to install the Odoo enterprise version!
IS_ENTERPRISE="False"
# Set this to True if you want to install Nginx!
INSTALL_NGINX="True"
# Set the superadmin password - if GENERATE_RANDOM_PASSWORD is set to "True" we will automatically generate a random password, otherwise we use this one
OE_SUPERADMIN="admin"
# Set to "True" to generate a random password, "False" to use the variable in OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="True"
OE_CONFIG="${OE_USER}-server"
OE_CONFIG_DIR="/etc/odoo/${OE_CONFIG}.conf"
# Set the website name
WEBSITE_NAME="example.com"
# Set the default Odoo longpolling port (you still have to use -c /etc/odoo-server.conf for example to use this.)
LONGPOLLING_PORT="8072"
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="False"
# Provide Email to register ssl certificate
ADMIN_EMAIL="odoo@example.com"
# configuracion de servidor ssh
DISABLE_SSH_PASS="False"
# Restringir al acceso a la url /web/database/selector solo a su IP publica, es decir, por la que se accedio por SSH
RETRICT_LIST_BD='false'

if [ -f 'entorno.sh' ]; then
  source ./entorno.sh
fi

if [ $DISABLE_SSH_PASS = "True" ]; then
    #----------------------------------------------------
    # Disable password authentication
    #----------------------------------------------------
    sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
    sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
    sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo service sshd restart
fi

##
###  WKHTMLTOPDF download links
## === Debian Buster x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltopdf installed, for a danger note refer to
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/12.0/setup/install.html#debian-ubuntu

WKHTMLTOX_X64=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_amd64.deb
WKHTMLTOX_X32=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.buster_i386.deb

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Actualizando Servidor ================"
sudo apt update
#sudo apt upgrade -y
sudo apt autoremove -y

echo -e "\n============= Instalar utilidades ================"
sudo apt install -y vim  git build-essential wget fail2ban
#### disable vim visual mode in debian Buster ####
sudo echo "set mouse-=a" >> ~/.vimrc

#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
# Create the file repository configuration:
echo -e "\n=========== Instalando PostgreSQL ================="
sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list > /dev/null

# Import the repository signing key:
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
# sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys  7FCC7D46ACCC4CF8

# Update the package lists:
sudo apt-get update
sudo apt install -y postgresql postgresql-contrib 

sudo systemctl enable postgresql

echo -e "\n=========== Creando el usuario ODOO en PostgreSQL ================="
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Instalado Dependencias
#--------------------------------------------------
echo -e "\n=================== Installing Python 3 + pip3 ============================"
sudo apt install python3 python3-pip python3-dev python3-dev python3-venv \
    python3-wheel libxml2-dev libxslt1-dev libldap2-dev libsasl2-dev \
    libtiff5-dev libjpeg62-turbo-dev libopenjp2-7-dev zlib1g-dev libfreetype6-dev \
    liblcms2-dev libwebp-dev libharfbuzz-dev libfribidi-dev libxcb1-dev libpq-dev python3-passlib python3-pypdf2 -y
sudo apt -f install -y

echo -e "\n================== Install python packages/requirements ============================"
sudo pip3 install setuptools wheel
sudo pip3 install -r https://raw.githubusercontent.com/odoo/odoo/${OE_VERSION}/requirements.txt

echo -e "\n=========== Installing nodeJS NPM and rtlcss for LTR support =================="
sudo apt install nodejs npm -y
sudo apt -f install -y

sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g rtlcss less less-plugin-clean-css

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
###  WKHTMLTOPDF download links
## === Debian Buster x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltopdf installed, for a danger note refer to
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/13.0/setup/install.html#debian-ubuntu


if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 13 ----"
  sudo apt install software-properties-common xfonts-75dpi -y

  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  FILEDEB=wkhtmltox.deb
  if [ -f "$FILEDEB" ]; then
    echo "ya existe $FILEDEB."
  else
    echo "Descargando $FILEDEB."
    wget $_url -O $FILEDEB
  fi

  sudo dpkg -i $FILEDEB
  if [ ! -f "/usr/bin/wkhtmltopdf" ]; then
    sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  fi

  if [ ! -f "/usr/bin/wkhtmltoimage" ]; then
    sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
  fi
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi

echo -e "\n=========== Creando directorio raiz ====================="
if [ ! -d "$OE_HOME" ] ; then
  sudo mkdir -p $OE_HOME
fi
sudo chmod -R 775 $OE_HOME

echo -e "\n======== Create ODOO system user =========="
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "\n=========== Creando directorio de configuracion odoo ====================="
if [ ! -d "$OE_ODOO_CONF" ] ; then
  sudo mkdir $OE_ODOO_CONF
fi
sudo chmod -R 775 $OE_ODOO_CONF

echo -e "\n======= Setting permissions on home folder ============="
sudo chown -R $OE_USER:$OE_USER $OE_HOME

sudo mkdir /var/log/$OE_USER
sudo chown $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/
# sudo git clone ./odoo-server/.git $OE_HOME_EXT/

if [ $IS_ENTERPRISE = "True" ]; then
    # Odoo Enterprise install!
    echo -e "\n========== Create symlink for node ===================="
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "\n====================== WARNING ============================="
        echo "Your authentication with Github has failed! Please try again."
        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
        echo "TIP: Press ctrl+c to stop this script."
        echo "\n==========================================================="
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n======== Added Enterprise code under $OE_HOME/enterprise/addons ==========="
    echo -e "\n========== Installing Enterprise specific libraries ==============="
    sudo pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less
    sudo npm install -g less-plugin-clean-css
fi

echo -e "\n======== Create custom module directory ================"
sudo su $OE_USER -c "mkdir -p $OE_HOME/custom/addons"

echo -e "\n======= Setting permissions on home folder ============="
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "\n============== Create server config file ================="
sudo touch ${OE_CONFIG_DIR}

echo -e "\n=========== Creating server config file =================="
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> ${OE_CONFIG_DIR}"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "* Generating random admin password"
    OE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> ${OE_CONFIG_DIR}"
if [ $OE_VERSION > "11.0" ]; then
    sudo su root -c "printf 'http_port = ${OE_PORT}\n' >> ${OE_CONFIG_DIR}"
else
    sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> ${OE_CONFIG_DIR}"
fi
sudo su root -c "printf 'logfile = /var/log/${OE_USER}/${OE_CONFIG}.log\n' >> ${OE_CONFIG_DIR}"

if [ $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_EXT}/addons\n' >> ${OE_CONFIG_DIR}"
else
    sudo su root -c "printf 'addons_path=${OE_HOME_EXT}/addons,${OE_HOME}/custom/addons\n' >> ${OE_CONFIG_DIR}"
fi

cat <<EOF > ./odoo_config
# configuracion adicional
dbfilter = ^%h$
limit_memory_hard = 1684354560
limit_memory_soft = 1147483648
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
limit_time_real_cron = -1
list_db = False
log_db = False
log_db_level = warning
log_handler = :INFO
log_level = info
max_cron_threads = 1
osv_memory_age_limit = 1.0
osv_memory_count_limit = False
reportgz = False
screencasts = None
syslog = False
test_enable = False
test_file = False
test_tags = None
translate_modules = ['all']
unaccent = False
upgrades_paths =
without_demo = False
workers = 2
smtp_password = xxxxxx
smtp_port = 587
smtp_server = smtp.gmail.com
smtp_ssl = True
smtp_user = cualquiera@gmail.com
longpolling_port = $LONGPOLLING_PORT

EOF

sudo su root -c "cat  ./odoo_config >> $OE_CONFIG_DIR"

sudo chown $OE_USER:$OE_USER ${OE_CONFIG_DIR}
sudo chmod 640 ${OE_CONFIG_DIR}

echo -e "\n============== Create startup file ================="
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_EXT/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_EXT/odoo-bin --config=${OE_CONFIG_DIR}' >> $OE_HOME_EXT/start.sh"
sudo chmod 755 $OE_HOME_EXT/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (Systemd)
#--------------------------------------------------

echo -e "\n================= Create Odoo systemd file ======================="
sudo cat <<EOF > ~/odoo.service

[Unit]
Description=Odoo Open Source ERP and CRM
Requires=postgresql.service
After=network.target postgresql.service

[Service]
Type=simple
User=$OE_USER
Group=$OE_USER
ExecStart=$OE_HOME_EXT/odoo-bin --config ${OE_CONFIG_DIR}  --logfile /var/log/${OE_USER}/${OE_CONFIG}.log
KillMode=mixed

[Install]
WantedBy=multi-user.target
EOF

sudo mv ~/odoo.service /lib/systemd/system/odoo_$OE_USER.service

echo -e "\n========= Odoo startup File ===================="
sudo systemctl daemon-reload
sudo systemctl enable odoo_$OE_USER.service
sudo systemctl start odoo_$OE_USER.service

# echo -e "\n======== Convert odoo CE to EE ============="
# wget https://raw.githubusercontent.com/hrmuwanika/odoo/master/odoo_ee.sh
# chmod +x odoo_ee.sh
# ./odoo_ee.sh

ssh_details=($SSH_CONNECTION)
if [ $RETRICT_LIST_BD = 'True' ]; then
  retrict_listbd="""

  location ~* /web/database/(manager|selector)$ {
    allow $MY_IP ;
    deny all;
    proxy_pass http://127.0.0.1:8069;
  }
  
  """
fi

#--------------------------------------------------
# Install Nginx if needed
#--------------------------------------------------
if [ $INSTALL_NGINX = "True" ]; then
  echo -e "\n======== Installing and setting up Nginx ========="
  sudo apt -f install -y
  sudo apt install -y nginx
  sudo systemctl enable nginx
  sudo systemctl start nginx
  
  cat <<EOF > ~/$WEBSITE_NAME
  
    #odoo server
    upstream odoo {
        server 127.0.0.1:$OE_PORT;
    }

    upstream odoochat {
        server 127.0.0.1:$LONGPOLLING_PORT;
    }

    server {
        listen 80;

        # set proper server name after domain set
        server_name $WEBSITE_NAME;

        # Add Headers for odoo proxy mode
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-XSS-Protection "1; mode=block";
        proxy_set_header X-Client-IP \$remote_addr;
        proxy_set_header HTTP_X_FORWARDED_HOST \$remote_addr;

        #   odoo    log files
        access_log  /var/log/nginx/$OE_USER-access.log;
        error_log       /var/log/nginx/$OE_USER-error.log;

        #   increase    proxy   buffer  size
        proxy_buffers   16  64k;
        proxy_buffer_size   128k;

        proxy_read_timeout 900s;
        proxy_connect_timeout 900s;
        proxy_send_timeout 900s;

        #   force   timeouts    if  the backend dies
        proxy_next_upstream error   timeout invalid_header  http_500    http_502
        http_503;

        types {
            text/less less;
            text/scss scss;
        }

        #   enable  data    compression
        gzip    on;
        gzip_min_length 1100;
        gzip_buffers    4   32k;
        gzip_types  text/css text/less text/plain text/xml application/xml application/json application/javascript application/pdf image/jpeg image/png;
        gzip_vary   on;
        client_header_buffer_size 4k;
        large_client_header_buffers 4 64k;
        client_max_body_size 0;

        location / {
            proxy_pass    http://odoo;
            # by default, do not forward anything
            proxy_redirect off;
        }

        $retrict_listbd

        location /longpolling {
            proxy_pass http://odoochat;
        }
        location ~* .(js|css|png|jpg|jpeg|gif|ico)$ {
            expires 2d;
            proxy_pass http://odoo;
            add_header Cache-Control "public, no-transform";
        }
        # cache some static data in memory for 60mins.
        location ~ /[a-zA-Z0-9_-]*/static/ {
            proxy_cache_valid 200 302 60m;
            proxy_cache_valid 404      1m;
            proxy_buffering    on;
            expires 864000;
            proxy_pass    http://odoo;
        }
    }
EOF

  sudo mv ~/$WEBSITE_NAME /etc/nginx/sites-available/$WEBSITE_NAME
  sudo ln -s /etc/nginx/sites-available/$WEBSITE_NAME /etc/nginx/sites-enabled/
  sudo rm /etc/nginx/sites-enabled/default
  sudo systemctl reload nginx
  sudo su root -c "printf 'proxy_mode = True\n' >> ${OE_CONFIG_DIR}"
  echo "Done! The Nginx server is up and running. Configuration can be found at /etc/nginx/sites-available/$WEBSITE_NAME"
else
  echo "Nginx isn't installed due to choice of the user!"
fi

#--------------------------------------------------
# Enable ssl with certbot
#--------------------------------------------------

if [ $INSTALL_NGINX = "True" ] && [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "odoo@example.com" ]  && [ $WEBSITE_NAME != "_" ];then
  sudo snap install core; sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  sudo certbot --nginx -d $WEBSITE_NAME --noninteractive --agree-tos --email $ADMIN_EMAIL --redirect
  sudo systemctl reload nginx
  echo "\n============ SSL/HTTPS is enabled! ========================"
else
  echo "\n==== SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration! ======"
fi

echo -e "\n========================= Datos de la instalacion de Odoo ========================="
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_HOME"
echo "Addons folder: $OE_HOME/custom/addons/"
echo "Password superadmin (database): $OE_SUPERADMIN"
echo "Start Odoo service: sudo systemctl start odoo_$OE_USER.service"
echo "Stop Odoo service: sudo systemctl stop odoo_$OE_USER.service"
echo "Restart Odoo service: sudo systemctl restart odoo_$OE_USER.service"
echo "Status Odoo service: sudo systemctl status odoo_$OE_USER.service"
echo "\n====================================================================="

