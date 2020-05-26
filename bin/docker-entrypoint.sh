#!/bin/bash

# Add sample user
# sample user uses uid 999 to reduce conflicts with user ids when mounting an existing home dir
# the below has represents the password 'ubuntu'
# run `openssl passwd -1 'newpassword'` to create a custom hash
#if [ ! $PASSWORDHASH ]; then
#    export PASSWORDHASH='$1$1osxf5dX$z2IN8cgmQocDYwTCkyh6r/'
#fi

export PASSWORDHASH='$1$RYCV3.vg$IvxIL2Qm.DJye1GgIP/vj0'
addgroup --gid 2000 ride 
useradd -m -u 2000 -s /bin/bash -g ride charles
useradd -m -u 2001 -s /bin/bash -g ride ian
useradd -m -u 2002 -s /bin/bash -g ride kween

echo "charles:$PASSWORDHASH" | /usr/sbin/chpasswd -e
echo "kween:$PASSWORDHASH" | /usr/sbin/chpasswd -e
echo "ian:$PASSWORDHASH" | /usr/sbin/chpasswd -e
echo "charles    ALL=(ALL) ALL" >> /etc/sudoers
unset PASSWORDHASH

# Add the ssh config if needed

#if [ ! -f "/etc/ssh/sshd_config" ];
#	then
#		cp /ssh_orig/sshd_config /etc/ssh
#fi

#if [ ! -f "/etc/ssh/moduli" ];
#	then
#		cp /ssh_orig/moduli /etc/ssh
#fi

# generate fresh rsa key if needed
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then 
	ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi

# generate fresh dsa key if needed
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then 
	ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

#prepare run dir
#mkdir -p /var/run/sshd

# generate xrdp key
if [ ! -f "/etc/xrdp/rsakeys.ini" ]; then
	xrdp-keygen xrdp auto
fi

# generate certificate for tls connection
if [ ! -f "/etc/xrdp/cert.pem" ]; then
	# delete eventual leftover private key
	rm -f /etc/xrdp/key.pem || true
	cd /etc/xrdp
	# TODO make data in certificate configurable?
	openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem -out cert.pem -days 365 \
	-subj "/C=US/ST=Some State/L=Some City/O=Some Org/OU=Some Unit/CN=Terminalserver"
fi
crudini --set /etc/xrdp/xrdp.ini Globals security_layer tls
crudini --set /etc/xrdp/xrdp.ini Globals certificate /etc/xrdp/cert.pem
crudini --set /etc/xrdp/xrdp.ini Globals key_file /etc/xrdp/key.pem

# generate machine-id
uuidgen > /etc/machine-id

# set keyboard for all sh users
echo "export QT_XKB_CONFIG_ROOT=/usr/share/X11/locale" >> /etc/profile

exec "$@"
