#! /bin/bash -ex

! test -f /run/apache2/apache2.pid || rm /run/apache2/apache2.pid
apache2ctl -DFOREGROUND
