#!/bin/bash
echo ""
ls -lhart /opt/ldap/backup
echo ""
echo "Enter the backup file you want to restore from above"
read backupfile
echo ""
rm -rf /opt/ldap/database/*
docker exec -it openldap /sbin/slapd-restore-data $backupfile
