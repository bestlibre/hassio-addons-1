#!/bin/bash
set -e

CONFIG_PATH=/data/options.json

WORKGROUP=$(jq --raw-output ".workgroup // empty" $CONFIG_PATH)
GUEST=$(jq --raw-output ".guest // empty" $CONFIG_PATH)
USERNAME=$(jq --raw-output ".username // empty" $CONFIG_PATH)
PASSWORD=$(jq --raw-output ".password // empty" $CONFIG_PATH)
MAP_CONFIG=$(jq --raw-output ".map_config // empty" $CONFIG_PATH)
MAP_ADDONS=$(jq --raw-output ".map_addons // empty" $CONFIG_PATH)
MAP_SSL=$(jq --raw-output ".map_ssl // empty" $CONFIG_PATH)
MAP_MNT=$(jq --raw-output ".map_mnt // empty" $CONFIG_PATH)
MAP_SHARE=$(jq --raw-output ".map_share // empty" $CONFIG_PATH)

SMB_CONFIG="
[config]
   browseable = yes
   writeable = yes
   path = /config

   #guest ok = yes
   #guest only = yes
   #public = yes

   #valid users = $USERNAME
   #force user = root
   #force group = root
"

SMB_SSL="
[ssl]
   browseable = yes
   writeable = yes
   path = /ssl

   #guest ok = yes
   #guest only = yes
   #public = yes

   #valid users = $USERNAME
   #force user = root
   #force group = root
"

SMB_ADDONS="
[addons]
   browseable = yes
   writeable = yes
   path = /addons

   #guest ok = yes
   #guest only = yes
   #public = yes

   #valid users = $USERNAME
   #force user = root
   #force group = root
"

SMB_SHARE="
[share]
   browseable = yes
   writeable = yes
   path = /share

   #guest ok = yes
   #guest only = yes
   #public = yes

   #valid users = $USERNAME
   #force user = root
   #force group = root
"

SMB_MNT="
[mnt]
   browseable = yes
   writeable = yes
   path = /mnt

   #guest ok = yes
   #guest only = yes
   #public = yes

   #valid users = $USERNAME
   #force user = root
   #force group = root
"

sed -i "s/%%WORKGROUP%%/$WORKGROUP/g" /etc/smb.conf

##
# Write shares to config
if [ "$MAP_CONFIG" == "true" ]; then
    echo "$SMB_CONFIG" >> /etc/smb.conf
fi
if [ "$MAP_ADDONS" == "true" ]; then
    echo "$SMB_ADDONS" >> /etc/smb.conf
fi
if [ "$MAP_SSL" == "true" ]; then
    echo "$SMB_SSL" >> /etc/smb.conf
fi
if [ "$MAP_SHARE" == "true" ]; then
    echo "$SMB_SSHARE" >> /etc/smb.conf
fi
if [ "$MAP_MNT" == "true" ]; then
    echo "$SMB_MNT" >> /etc/smb.conf
fi

##
# Set authentication options
if [ "$GUEST" == "true" ]; then
    sed -i "s/#guest ok/guest ok/g" /etc/smb.conf
    sed -i "s/#guest only/guest only/g" /etc/smb.conf
    sed -i "s/#guest account/guest account/g" /etc/smb.conf
    sed -i "s/#map to guest/map to guest/g" /etc/smb.conf
    sed -i "s/#public/public/g" /etc/smb.conf
else
    sed -i "s/#valid users/valid users/g" /etc/smb.conf
    sed -i "s/#force user/force user/g" /etc/smb.conf
    sed -i "s/#force group/force group/g" /etc/smb.conf

    addgroup -g 1000 "$USERNAME"
    adduser -D -H -G "$USERNAME" -s /bin/false -u 1000 "$USERNAME"
    echo -e "$PASSWORD\n$PASSWORD" | smbpasswd -a -s -c /etc/smb.conf "$USERNAME"
fi

exec smbd -F -S -s /etc/smb.conf < /dev/null
