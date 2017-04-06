# This file contains my failed attempt at setting up laddr. After following the
# instructions on emr.ge, I ended up with an installation giving me this error:
#
#    A problem has occurred and this request could not be handled, the webmaster has been sent a diagnostic report.
#
# (I was not sent a diagnostic report.)
#
# In the logs, it appears that there are many errors/warnings returned during
# this attempted page load:
# ==> /emergence/sites/laddr/logs/error.log <==
# 2017/04/06 03:02:41 [error] 8068#0: *18 FastCGI sent in stderr: "PHP message: PHP Warning:  array_merge(): Argument #2 is not an array in /usr/local/lib/node$
# modules/emergence/php-bootstrap/lib/DB.class.php on line 426
# PHP message: PHP Warning:  mysqli::set_charset(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/DB.class.php on line 431
# PHP message: PHP Warning:  DB::handleError(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/DB.class.php on line 456
# PHP message: PHP Warning:  DB::handleError(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/DB.class.php on line 458
# PHP message: PHP Warning:  DB::handleError(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/DB.class.php on line 461
# PHP message: PHP Warning:  print_r(): Property access is not allowed yet in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/Site.class.php on line 48$
# PHP message: PHP Warning:  print_r(): Property access is not allowed yet in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/Site.class.php on line 48$
# PHP message: PHP Warning:  print_r(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/Site.class.php on line 485
# PHP message: PHP Warning:  print_r(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/Site.class.php on line 485
# PHP message: PHP Warning:  print_r(): Property access is not allowed yet in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/Site.class.php on line 485
# PHP message: PHP Warning:  print_r(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/Site.class.php on line 485
# PHP message: PHP Warning:  print_r(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/Site.class.php on line 485
# PHP message: PHP Warning:  print_r(): Couldn't fetch mysqli in /usr/local/lib/node_modules/emergence/php-bootstrap/lib/Site.class.php on line 485
#
# Overall, the architecture of laddr seems unwise for us to re-deploy. The
# framework it is built upon is bespoke and years out-of-date vis-a-vis new
# Ubuntu releases. There are problems here in many places and debugging them
# will take ages because of how many moving parts there are. Web apps should
# not be this hard.
#
# =============================================================================
# TERRAFORM CONFIG
# =============================================================================
# resource "digitalocean_ssh_key" "laddr" {
#   name = "DigitalOcean Terraform Laddr"
#   public_key = "${trimspace(file("~/.ssh/laddr.pub"))}"
# }
#
# resource "digitalocean_droplet" "laddr" {
#   image = "ubuntu-14-04-x64"
#   name = "laddr-demo"
#   region = "sfo2"
#   size = "512mb"
#   ssh_keys = ["${digitalocean_ssh_key.laddr.fingerprint}"]
#
#   connection {
#     type = "ssh"
#     private_key = "${file("~/.ssh/laddr")}"
#   }
#
#   provisioner "remote-exec" {
#     inline = [
# <<EOF
# wget http://emr.ge/dist/ubuntu/quickinstall-14.04.sh -O - | sudo sh && \
# sudo sed -i '/deb .* trusty-backports/s/^#\s*//' /etc/apt/sources.list && \
# sudo apt-get update && sudo apt-get upgrade -y && \
# sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git python-software-properties python g++ make ruby-dev nodejs npm nodejs-legacy nginx php5-fpm php5-cli php5-apcu php5-mysql php5-gd php5-json php5-curl php5-intl php5-imagick mysql-server mysql-client gettext imagemagick postfix && \
# sudo gem install compass && \
# sudo apt-get install php5-apcu/trusty-backports && \
# (sudo service nginx stop || true) && sudo update-rc.d -f nginx disable && \
# (sudo service php5-fpm stop || true) && (echo 'manual' | sudo tee /etc/init/php5-fpm.override) && \
# (sudo service mysql stop || true) && (echo 'manual' | sudo tee /etc/init/mysql.override) && \
# echo -e "/emergence/services/etc/my.cnf r,\n/emergence/services/data/mysql/ r,\n/emergence/services/data/mysql/** rwk,\n/emergence/services/run/mysqld/mysqld.sock w,\n/emergence/services/run/mysqld/mysqld.pid rw," | sudo tee -a /etc/apparmor.d/local/usr.sbin.mysqld && \
# echo -e "kernel.shmmax = 268435456\nkernel.shmall = 65536" | sudo tee -a /etc/sysctl.d/60-shmmax.conf && \
# sudo sysctl -w kernel.shmmax=268435456 kernel.shmall=65536 && \
# echo -e "apcu.shm_size=128M\napc.shm_size=128M" | sudo tee -a /etc/php5/mods-available/apcu.ini &&\
# sudo npm install -g git+https://github.com/JarvusInnovations/Emergence && \
# sudo wget http://emr.ge/dist/debian/upstart -O /etc/init/emergence-kernel.conf && \
# sudo status emergence-kernel | grep -q running || sudo start emergence-kernel
# EOF
#     ]
#   }
#
#   provisioner "remote-exec" {
#     inline = [
#       "fallocate -l 2G /mnt/swap",
#       "mkswap /mnt/swap",
#       "chmod 0600 /mnt/swap",
#       "swapon /mnt/swap"
#     ]
#   }
# }
#
# resource "cloudflare_record" "laddr" {
#   domain = "tdooner.com"
#   name = "laddr"
#   value = "${digitalocean_droplet.laddr.ipv4_address}"
#   type = "A"
#   ttl = 120
#   proxied = true
# }
#
# output "ip" {
#   value = "${digitalocean_droplet.laddr.ipv4_address}"
# }
