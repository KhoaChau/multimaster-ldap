# ubuntu xenial dropped php5 and installs php7
# ldap-account-manager supports php7 with release 5.3
# currently (Nov16) xenial provides ldap-account-manager 5.2
FROM ubuntu:trusty
LABEL maintainer="Khoa Chau"
ENV TERM xterm

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y ldap-account-manager
RUN a2enmod ssl
RUN a2ensite default-ssl
RUN sed -i 's,DocumentRoot .*,DocumentRoot /usr/share/ldap-account-manager,' /etc/apache2/sites-available/000-default.conf
RUN sed -i 's,DocumentRoot .*,DocumentRoot /usr/share/ldap-account-manager,' /etc/apache2/sites-available/default-ssl.conf
RUN ln -sf /proc/self/fd/1 /var/log/apache2/access.log
RUN ln -sf /proc/self/fd/2 /var/log/apache2/error.log


ADD start.sh /start.sh
RUN chmod +x /start.sh
CMD /start.sh

EXPOSE 80
EXPOSE 443
VOLUME /var/lib/ldap-account-manager
VOLUME /etc/ldap-account-manager
