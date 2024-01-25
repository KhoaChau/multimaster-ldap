# ldap in multimaster mode with docker

using docker image: osixia/openldap-backup:1.5.0



## Prerequisites:

- At least 2 hosts with docker-compose.
- A backup file if you are restoring from an existing ldap setup.


## Notes:

- The variable HOSTNAME1 is always the host that you are on.
- DEFAULT LAM password is `changeme` *different than the admin and config password set in the template file.

  - You need to manually go into the lam gui and change the password as needed on each instance.

## ToDo:

* Allow user to set the default lam password in the template.
* Screenshots of lam password change.
* Make this README prettier.
* Testing.

## Steps:

### PART I - 1st Host

> Log into ldap_host1 (ie the 1st host) assume root. Git clone this repo.

* `git clone git@github.com:khoachau/multimaster-ldap.git /opt/ldap`
* `cd /opt/ldap`

> Copy the variables-template.txt file then edit variable.txt and run script on 1st host:

* `cp variables-template.txt variables.txt`
* `vi variables.txt` (REMINDER HOSTNAME1 is the host you are on)
* `./runme_on_1st_host.sh`

> Start container

* `docker-compose up`

### PART II - 2nd Host

> Log into ldap_host2 (ie the n-th host) assume root. Git clone this repo.

* `git clone git@github.com:khoachau/multimaster-ldap.git /opt/ldap`
* `cd /opt/ldap`

> Copy rootCA.crt and rootCA.key from the 1st host

* `scp 1.ST.HOST.IP:/tmp/root* /opt/ldap/certs/.`

> Copy the variables-template.txt file then edit variable.txt and run script on 2nd host:

* `cp variables-template.txt variables.txt`
* `vi variables.txt` (REMINDER HOSTNAME1 is the host you are on)
* `./runme_on_nth_host.sh` (NOTE that it's the nth_host.sh not 1st_host.sh)

> Start container

* `docker-compose up`

### PART III - nth host and so on...

> See PART II, rinse and repeat until done.


### PART IV - Restore DB

> Log back into ldap_host1.

> Copy any backupfile you have to /opt/ldap/backup/.

> Copy ldap_host2 certs.

* `scp N.TH.HOST.IP:/tmp/ldap_host2* /opt/ldap/certs/.`

> Run the restore_db.sh

* `/.restore_db.sh`

### PART V - Testing
