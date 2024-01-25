#!/bin/bash
docker stop openldap lam
docker rm openldap lam
docker rmi ldap_lam osixia/openldap-backup:1.5.0
