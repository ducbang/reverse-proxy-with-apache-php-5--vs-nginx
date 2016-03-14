#!/bin/bash
####### Cau hinh FW SE mo port 80,22
mo_port()
{
	echo "Dang cau hinh tuong lua..."
	iptables -F
	iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT 
	iptables -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT 
	service iptables save
	service iptables restart
	setenforce 0
	chmod -R 755 /var/www/
	sed -i 's/enforcing/permissive/g' /etc/selinux/config
	echo "Cau hinh tuong lua xong."
}
####### nginx
cau_hinh_nginx_php()
{
	sed -i '39s/apache/nginx/g' /etc/php-fpm.d/www.conf
	sed -i '41s/apache/nginx/g' /etc/php-fpm.d/www.conf
	sed -i 's/#gzip/gzip/g' /etc/nginx/nginx.conf
	

}
cai_dat_nginx()
{
	echo "nginx dang duoc cai dat..."
	#install_nginx
	yum -y install epel-release
	yum -y install nginx
	yum -y install php php-mbstring php-pear php-fpm
	cau_hinh_nginx_php
	service nginx restart
	/etc/rc.d/init.d/php-fpm start
	chkconfig php-fpm on
	chkconfig nginx on
	echo "Xong!"
}
check_domain_nginx()
{
# apache hostname=$(cat /etc/httpd/conf.d/*.conf | grep ServerName | awk '{print $2}' | tr '\n' ' ')
hostname=$(find /etc/nginx/ -type f -name "*.conf" -print0 | xargs -0 egrep '^(\s|\t)*server_name' | awk '{print $3}' | tr ";" " ")
for x in $hostname
	do
		if [[ $x == $domain ]];
			then echo $domain " Ten mien ton tai."
			flag=1
			break
		fi		
	done
if [[ $flag != 1 ]];
	then taofile_nginx $domain
	service nginx reload
	echo "Da tao xong " $domain
fi
}
taofile_nginx()
{
mkdir -p /var/www/$1/public_html
#echo "<h1>This is "  $1 " </h1>"  >  /var/www/$1/public_html/index.html
mkdir -p /var/www/$1/log
 cat > /var/www/$1/public_html/index.php << HOANG
<html>
 <body>
 <div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
 <h1>VirtualHost: $1</h1>
 <?php
    print Date("Y/m/d");
    phpinfo();
 ?>
 </div>
 </body>
 </html>
HOANG

cat >  /etc/nginx/conf.d/$1.conf << 1234
server {
    listen       80;
    server_name   $1 *.$1;

    location / {
        root   /var/www/$1/public_html;
        index  index.php index.html index.htm;
    }
	location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
		root   /var/www/$1/public_html;
        fastcgi_param  SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
        include        /etc/nginx/fastcgi_params;
    }
	access_log /var/www/$1/log/access.log combined;
	error_log /var/www/$1/log/error.log;
}
1234
}
tao_vhost_nginx()
{
	read -p "Nhap vao domain: " domain
	check_domain_nginx $domain
}

main_nginx_php()
{
	echo "1. Cai dat nginx + php-fpm"
	echo "2. Them VirtualHost"
	echo "3. Thoat"

	read -p "Ban muon lam gi?: " INPUT_STRING
		case $INPUT_STRING in 1)
			clear
			cai_dat_nginx
			mo_port
			break;;
		2)
			clear
			tao_vhost_nginx
			break;;
		3)
			clear
			echo "Tam biet! Cam on ban da su dung."
			break;;
		esac
}
####### apache
cau_hinh_apache()
{
	sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/httpd/conf/httpd.conf
	sed -i 's/KeepAlive Off/KeepAlive On/g' /etc/httpd/conf/httpd.conf
	sed -i 's/#ServerName www.example.com:80/ServerName *:80/g' /etc/httpd/conf/httpd.conf
	echo "NameVirtualHost *:80" >> /etc/httpd/conf/httpd.conf
	sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf
	sed -i 's/DirectoryIndex index.html/DirectoryIndex index.html index.htm/g' /etc/httpd/conf/httpd.conf
	sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/httpd/conf/httpd.conf
}
cai_dat_apache()
{
	httpd=$(rpm -qa | grep httpd)
if [[ $httpd = "" ]]
  then 
	echo "httpd dang duoc cai dat va cau hinh..."	
yum -y install httpd
yum -y install php php-mbstring php-pear
rm -f /etc/httpd/conf.d/welcome.conf
rm -f /var/www/error/noindex.html

cat > /var/www/html/index.php << HOANG2
<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
<h1>Da cai dat Reverse Proxy.</h1>
<?php
   print Date("Y/m/d");
   phpinfo();
?>
</div>
</body>
</html>
HOANG2
	
	cau_hinh_apache
	service httpd start
	chkconfig httpd on
	echo "Done!"
  else
  echo httpd da duoc dai dat.
  echo "Cau hinh lai Apache..."  
  cau_hinh_apache
  service httpd restart
fi
}
taofile_apache()
{
mkdir -p /var/www/$1/public_html
#echo "<h1>This is "  $1 " </h1>"  >  /var/www/$1/public_html/index.html

cat > /var/www/$1/public_html/index.php << HOANG
	<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
<h1>VirtualHost: $1</h1>
<?php
   print Date("Y/m/d");
   phpinfo();
?>
</div>
</body>
</html>
HOANG

mkdir -p /var/www/$1/log

cat > /etc/httpd/conf.d/$1.conf << 1234

<VirtualHost *:80>
ServerName $1
ServerAlias www.$1
ServerAdmin webmaster@$1
DocumentRoot /var/www/$1/public_html

ErrorLog /var/www/$1/log/error.log
CustomLog /var/www/$1/log/access.log combined

</VirtualHost>
1234
}
check_domain_apache()
{

hostname=$(cat /etc/httpd/conf.d/*.conf | grep ServerName | awk '{print $2}' | tr '\n' ' ')
for x in $hostname
	do
		if [[ $x == $domain ]];
			then echo $domain " Ten mien ton tai."
			flag=1
			break
		fi		
	done
if [[ $flag != 1 ]];
	then taofile_apache $domain
	service httpd restart
	echo "Da tao xong " $domain
fi
}
tao_vhost_apache(){
	read -p "Nhap vao domain: " domain
	check_domain_apache $domain
}
main_apache_php()
{
	echo "1. Cai dat Apache + PHP"
	echo "2. Them VirtualHost"
	echo "3. Thoat"

	read -p "Ban muon lam gi?: " INPUT_STRING
		case $INPUT_STRING in 1)
			clear
			cai_dat_apache
			mo_port
			break;;
		2)
			clear
			tao_vhost_apache
			break;;
		3)
			clear
			echo "Tam biet! Cam on ban da su dung."
			break;;
		esac
}
###### ReverseProxy
cau_hinh_apache8889()
{
	sed -i 's/Listen 80/Listen 8889/g' /etc/httpd/conf/httpd.conf
	sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/httpd/conf/httpd.conf
	sed -i 's/KeepAlive Off/KeepAlive On/g' /etc/httpd/conf/httpd.conf
	sed -i 's/#ServerName www.example.com:80/ServerName *:8889/g' /etc/httpd/conf/httpd.conf
	echo "NameVirtualHost *:8889" >> /etc/httpd/conf/httpd.conf
	sed -i 's/AllowOverride None/AllowOverride All/g' /etc/httpd/conf/httpd.conf
	sed -i 's/DirectoryIndex index.html/DirectoryIndex index.html index.htm/g' /etc/httpd/conf/httpd.conf
	sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/httpd/conf/httpd.conf
}
install_http()
{
	
yum -y install httpd
yum -y install php php-mbstring php-pear
rm -f /etc/httpd/conf.d/welcome.conf
rm -f /var/www/error/noindex.html
#echo "Da cai dat Reverse Proxy, day la trang Apache" > /var/www/html/index.php

cat > /var/www/html/index.php << HOANG2
<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
<h1>Da cai dat Reverse Proxy.</h1>
<?php
   print Date("Y/m/d");
   phpinfo();
?>
</div>
</body>
</html>
HOANG2


cau_hinh_apache8889

service httpd start
chkconfig httpd on

}
kiemtracaidat()
{
httpd=$(rpm -qa | grep httpd)
nginx=$(rpm -qa | grep nginx)
if [[ $httpd = "" ]]
  then 
	echo "Httpd dang duoc cai dat..."
	install_http
	echo "Done!"
  else
  echo httpd da duoc dai dat.
  echo "Doi cong hoat dong cua httpd 8889."
  
  cau_hinh_apache8889
  
  service httpd restart
fi
if [[ $nginx = "" ]]
  then 
	echo "nginx dang duoc cai dat..."
	#install_nginx
	yum -y install epel-release
	yum -y install nginx
	service nginx start
	chkconfig nginx on
	echo "Xong!"
  else
  echo nginx da duoc cai dat.
  service nginx restart
fi
}
tao_file()
{
	#File cache.conf cua nginx
cat > /etc/nginx/conf.d/cache.conf << HOANG
	#proxy_cache_path /tmp/cache levels=1:2 keys_zone=cache:60m max_size=1G;
	#proxy_cache_path /tmp/cache3k levels=1:2 keys_zone=3k:60m max_size=1G;
	proxy_cache_path /tmp/cache levels=1:2 keys_zone=cache:75m inactive=24h max_size=1g;
	#proxy_cache_path /tmp/cache3k levels=1:2 keys_zone=3k:75m inactive=2 4h max_size=1g;
HOANG
	#File proxy.conf cua nginx
cat > /etc/nginx/conf.d/proxy.conf << 12345
	proxy_set_header Host \$host;
	proxy_set_header X-Real-IP \$remote_addr;
	proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
	#proxy_set_header  X-Forwarded-Host \$remote_addr;

	client_max_body_size 100M;
	client_body_buffer_size 1m;
	proxy_intercept_errors on;
	proxy_buffering on;
	proxy_buffer_size 128k;
	proxy_buffers 256 16k;
	proxy_busy_buffers_size 256k;
	proxy_temp_file_write_size 256k;
	proxy_max_temp_file_size 0;
	proxy_read_timeout 300;
12345
	#File lang nghe cua nginx
cat >  /etc/nginx/conf.d/default.conf << 1234end
	server {
        listen   80; 

        root /var/www/; 
        index index.php index.html index.htm;

        server_name _; 
		set \$cache_uri \$request_uri;
		 
		# POST requests and urls with a query string should always go to PHP
		if (\$request_method = POST) {
				set \$cache_uri 'null cache';
		}
		if (\$query_string != "") {
				set \$cache_uri 'null cache';
		}  
		 
		# Don't cache uris containing the following segments
		if (\$request_uri ~* "(/wp-admin/|/xmlrpc.php|/wp-(app|cron|login|register|mail).php|wp-.*.php|/feed/|index.php|wp-comments-popup.php|wp-links-opml.php|wp-locations.php|sitemap(_index)?.xml|[a-z0-9_-]+-sitemap([0-9]+)?.xml)") {
				set \$cache_uri 'null cache';
		}  
		 
		# Don't use the cache for logged in users or recent commenters
		if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_logged_in") {
				set \$cache_uri 'null cache';
		}

		  ## send all traffic to the back-end
					location / {
						
						 proxy_pass  http://127.0.0.1:8889;
						 include /etc/nginx/conf.d/proxy.conf;
						 proxy_redirect off;
						 

						 location ~* \.(html|css|jpg|gif|ico|js)\$ {
								proxy_cache          cache;
								proxy_cache_key      \$host\$uri\$is_args\$args;
								proxy_cache_valid    200 301 302 30m;
								expires              30m;
								#try_files /wp-content/cache/supercache/\$http_host/\$cache_uri/index.html \$uri \$uri/ /index.php ;
								proxy_pass  http://127.0.0.1:8889;
						 }
		}
}
1234end
}
xong()
{
	service nginx reload
	service httpd reload
	service httpd restart
	service nginx restart

}
#Cài đặt Reverse Proxy
Caidat_reverseproxy()
{
kiemtracaidat
tao_file
mo_port
xong
}
#Cac Function tao VirtualHost cho Reverse Proxy
taofile_vhost8889()
{
mkdir -p /var/www/$1/public_html
#echo "<h1>This is "  $1 " </h1>"  >  /var/www/$1/public_html/index.html

cat > /var/www/$1/public_html/index.php << HOANG
	<html>
<body>
<div style="width: 100%; font-size: 40px; font-weight: bold; text-align: center;">
<h1>VirtualHost: $1</h1>
<?php
   print Date("Y/m/d");
   phpinfo();
?>
</div>
</body>
</html>
HOANG

mkdir -p /var/www/$1/log

cat > /etc/httpd/conf.d/$1.conf << 1234

<VirtualHost *:8889>
ServerName $1
ServerAlias *.$1
ServerAdmin webmaster@$1
DocumentRoot /var/www/$1/public_html

ErrorLog /var/www/$1/log/error.log
CustomLog /var/www/$1/log/access.log combined

</VirtualHost>
1234
}
#Thêm VirtualHost cho R.Proxy
Cauhinh_vhost8889()
{
read -p "Nhap vao domain: " domain
hostname=$(cat /etc/httpd/conf.d/*.conf | grep ServerName | awk '{print $2}' | tr '\n' ' ')
for x in $hostname
	do
		if [[ $x == $domain ]];
			then echo $domain " Ten mien ton tai."
			flag=1
			break
		fi		
	done
if [[ $flag != 1 ]];
	then taofile_vhost8889 $domain
	service httpd reload
	echo "Da tao xong " $domain
fi
}
main_reverse(){
echo "1. Cai dat Reverse Proxy su dung nginx & apache"
echo "2. Them VirtualHost cho R.Proxy"
echo "3. Thoat"

read -p "Ban muon lam gi?: " INPUT_STRING
	case $INPUT_STRING in 1)
		clear
		Caidat_reverseproxy
		break;;
	2)
		clear
		Cauhinh_vhost8889
		break;;
	3)
		clear
		echo "Tam biet! Cam on ban da su dung."
		break;;
	esac
}
clear
echo "1. Cai dat APACHE & php"
echo "2. Cai dat NGINX & php-fpm"
echo "3. Cai dat Reverse Proxy su dung nginx & apache"
echo "4. Thoat"

read -p "Ban muon lam gi?: " INPUT_STRING
	case $INPUT_STRING in 1)
		clear
		main_apache_php
		break;;
	2)
		clear
		main_nginx_php
		break;;
	3)
		clear
		main_reverse
		break;;
	4)
		clear
		echo "Tam biet! Cam on ban da su dung."
		break;;
	esac