# Installation Script for Odoo Open Source

This script will also give you the ability to define an xmlrpc_port in the .conf file that is generated under /etc/
This script can be safely used in a multi-odoo code base server because the default Odoo port is changed BEFORE the Odoo is started.

## Installing Nginx
If you set the parameter ```INSTALL_NGINX``` to ```True``` you should also configure workers. Without workers you will probably get connection loss issues. Look at [the deployment guide from Odoo](https://www.odoo.com/documentation/13.0/setup/deploy.html) on how to configure workers.

## Installation procedure

##### 1. Download the script:
```
wget https://raw.githubusercontent.com/hrmuwanika/odoo-open-source-installation-script/master/odoo_install.sh
```
##### 2. Modify the parameters as you wish.
There are a few things you can configure, this is the most used list:<br/>
```OE_USER``` Sera el nombre de usuario del sistema que tendra acceso al proyecto.<br/>
```GENERATE_RANDOM_PASSWORD``` si es configurada como ```True``` este Script generara una contraseña aleatoria y segura, por el contrario, si es configurada como ```False``` conservaremos la contraseña configurada en ```OE_SUPERADMIN```. por defecto el valor de esta variable es ```True```.<br/>
```OE_PORT``` es el puerto donde Odoo deberia ejecutarse, por defecto es 8069.<br/>
```OE_VERSION``` Es la versión de Odoo a instalar, por defecto la ```13.0```.<br/>
```IS_ENTERPRISE``` Se instalará la version empresarial (Enterprise) si es configurada en ```True```, por el contrario, si es sonfigurada en ```False``` se instalará la versión de la comunidad (Community).<br/>
```OE_SUPERADMIN``` Es la contraseña maestra para esta instalacion de Odoo.<br/>
```INSTALL_NGINX``` por defecto es ```True```. Configurela en ```False``` si no desea instalar Nginx.<br/>
```WEBSITE_NAME``` Nombre de dominio de esta instalación de Odoo y que se configurará en Nginx<br/>
```ENABLE_SSL``` Set this to ```True``` to install [certbot](https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx.html) and configure nginx with https using a free Let's Encrypted certificate<br/>
```ADMIN_EMAIL``` Email is needed to register for Let's Encrypt registration. Replace the default placeholder with an email of your organisation.<br/>
```INSTALL_NGINX``` and ```ENABLE_SSL``` must be set to ```True``` and the placeholder in ```ADMIN_EMAIL``` must be replaced with a valid email address for certbot installation<br/>
  _By enabling SSL though Let's Encrypt you agree to the following [policies](https://www.eff.org/code/privacy/policy)_ <br/>

#### 3. Make the script executable
```
sudo chmod +x odoo_install.sh
```

##### 4. Execute the script:
```
sudo ./odoo_install.sh
```

##### 5. Sservicio odoo
Verificar  estado de servicio
```bash
sudo systemctl status odoo_odoo.service
```

Detener servicio
```bash
sudo systemctl stop odoo_odoo.service
```

Reiniciar servicio
```bash
sudo systemctl restart odoo_odoo.service
```

Iniciar servicio
```bash
sudo systemctl start odoo_odoo.service
```

La instalacion podria tomar cerca de 10 minutos para completarse, sin embargo este tiempo tambien varia de acuerdo a su ancho de banda.

For more information on hosting, upgrading to odoo enterprise, and changing your domain, contact me hrmuwanika@gmail.com
