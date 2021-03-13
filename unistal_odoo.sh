#!/bin/bash
sudo rm -rf /var/log/odoo
sudo deluser odoo
sudo rm -fr /odoo
sudo rm -fr /etc/odoo
sudo systemctl stop odoo_odoo.service
sudo systemctl disable odoo_odoo.service
sudo rm -f /etc/systemd/system/multi-user.target.wants/odoo_odoo.service
sudo rm -f /lib/systemd/system/odoo_odoo.service
sudo rm -fr /etc/nginx/sites-available/odoo*
sudo rm -fr /etc/nginx/sites-enabled/odoo*
sudo systemctl daemon-reload