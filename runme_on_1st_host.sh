#!/bin/bash
HOST_FILE="/etc/hosts"
datetime=$(date '+%Y%m%d%H%M%S')
cp docker-compose-template.yml docker-compose.yml
cp lam-template.conf lam/data/config/lam.conf

#check if the varialbes.txt exist
if [ ! -f "variables.txt" ]; then
    echo "variables.txt does not exist. Please copy variables-template.txt to variable.txt and edit it accordingly..."
    exit 1
fi

#create needed directory
if [ ! -d "bakcup" ]; then
    mkdir -p "backup"
    echo "backup directory created."
else
    echo "backup directory already exists."
fi

if [ ! -d "certs" ]; then
    mkdir -p "certs"
    echo "certs directory created."
else
    echo "certs directory already exists."
fi

if [ ! -d "config" ]; then
    mkdir -p "config"
    echo "config directory created."
else
    echo "config directory already exists."
fi

if [ ! -d "database" ]; then
    mkdir -p "database"
    echo "database directory created."
else
    echo "database directory already exists."
fi

if [ ! -d "lam/data/sess" ]; then
    mkdir -p "lam/data/sess"
    echo "lam/data/sess directory created."
else
    echo "lam/data/sess Directory already exists."
fi    

if [ ! -d "lam/data/tmp" ]; then
    mkdir -p "lam/data/tmp"
    echo "lam/data/tmp directory created."
else
    echo "lam/data/tmp Directory already exists."
fi

declare -A myArray

while IFS=',' read -r key value
do
    myArray["$key"]="$value"
done < variables.txt

sed -i "s/ORG_NAME/${myArray[ORG_NAME]}/g" docker-compose.yml
sed -i "s/DOMAIN_NAME/${myArray[DOMAIN_NAME]}/g" docker-compose.yml
sed -i "s/LDAP_ADMIN_PASSWD/${myArray[LDAP_ADMIN_PASSWD]}/g" docker-compose.yml
sed -i "s/LDAP_CONFIG_PASSWD/${myArray[LDAP_CONFIG_PASSWD]}/g" docker-compose.yml
sed -i "s/HOSTNAME1/${myArray[HOSTNAME1]}/g" docker-compose.yml
sed -i "s/HOST1IP/${myArray[HOST1IP]}/g" docker-compose.yml
sed -i "s/HOSTNAME2/${myArray[HOSTNAME2]}/g" docker-compose.yml
sed -i "s/HOST2IP/${myArray[HOST2IP]}/g" docker-compose.yml
sed -i "s/STATE/${myArray[STATE]}/g" docker-compose.yml
sed -i "s/ORG_UNIT/${myArray[ORG_UNIT]}/g" docker-compose.yml

#lam config
sed -i "s/HOSTNAME1/${myArray[HOSTNAME1]}/g" lam/data/config/lam.conf
sed -i "s/DOMAIN_NAME/${myArray[DOMAIN_NAME]}/g" lam/data/config/lam.conf
sed -i "s/DC1/${myArray[DC1]}/g" lam/data/config/lam.conf
sed -i "s/DC2/${myArray[DC2]}/g" lam/data/config/lam.conf
sed -i "s/DC3/${myArray[DC3]}/g" lam/data/config/lam.conf

echo ""
#add entries to etc/hosts if needed
result1=$(awk '{$1=$1};1' "$HOST_FILE" |  grep -E "${myArray[HOST1IP]}.*${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.*${myArray[HOSTNAME1]}")

if [ -n "$result1" ]; then
    echo "Host entry already exists $result1"
else
    echo "adding ${myArray[HOST1IP]}     ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}     ${myArray[HOSTNAME1]} to /etc/hosts"
    echo "${myArray[HOST1IP]}     ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}     ${myArray[HOSTNAME1]}" >> $HOST_FILE
    cp /etc/hosts /tmp/hosts.$datetime
fi

result2=$(awk '{$1=$1};1' "$HOST_FILE" |  grep -E "${myArray[HOST2IP]}.*${myArray[HOSTNAME2]}.${myArray[DOMAIN_NAME]}.*${myArray[HOSTNAME2]}")

if [ -n "$result2" ]; then
    echo "Host entry already exists $result2"
else
    echo "adding ${myArray[HOST2IP]}     ${myArray[HOSTNAME2]}.${myArray[DOMAIN_NAME]}     ${myArray[HOSTNAME2]} to /etc/hosts"
    echo "${myArray[HOST2IP]}     ${myArray[HOSTNAME2]}.${myArray[DOMAIN_NAME]}     ${myArray[HOSTNAME2]}" >> $HOST_FILE
    cp /etc/hosts /tmp/hosts.$datetime
fi
echo ""

#sometimes you get the random number generator file not found issue
#this will prevent such errors
openssl rand -writerand ~/.rnd

#create empty rootCA.crt file for comparisson 
if [ ! -f "/tmp/rootCA.crt" ]; then
    touch "/tmp/rootCA.crt"
    echo "empty rootCA.crt file created."
else
    echo "rootCA.crt file already exists."
fi
echo ""

#Create root CA & Private Key if one doesn't exist
if diff -q "/tmp/rootCA.crt" "certs/rootCA.crt" >/dev/null; then
    echo "rootCA.crt files are identical, skipping creation"
else
    echo "The files are not identical. Generating root certs..."
    openssl req -x509 -sha256 -days 3650 -nodes -newkey rsa:2048 -subj "/CN=${myArray[DOMAIN_NAME]}/C=US/L=${myArray[STATE]}" -keyout certs/rootCA.key -out certs/rootCA.crt
    cp certs/rootCA.crt /tmp/rootCA.crt
    cp certs/rootCA.key /tmp/rootCA.key
fi
echo ""

#Generate Private Key
#create empty server.key file for comparisson
if [ ! -f "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key" ]; then
    touch "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key"
    echo "empty ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key file created."
else
    echo "${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key file already exists."
fi
echo ""

if diff -q "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key" "certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key" >/dev/null; then
    echo "${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key files are identical, skipping creation"
else
    echo "the files are not identical, Generating ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key"
    openssl genrsa -out certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key 2048
    cp certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key /tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key
fi
echo ""

# Create csf conf
cat > certs/csr.conf <<EOF
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
C = US
ST = ${myArray[STATE]}
L = ${myArray[STATE]}
O = ${myArray[ORG_NAME]}
OU = ${myArray[ORG_UNIT]}
CN = ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}

EOF

# create CSR request using private key
if [ ! -f "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr" ]; then
    touch "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr"
    echo "empty ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr file created."
else
    echo "${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr file already exists."
fi
echo ""

if diff -q "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr" "certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr" >/dev/null; then
    echo "${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr files are identical, skipping creation"
else
    echo "the files are not identical, Generating ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr"
    openssl req -new -key certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.key -out certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr -config certs/csr.conf
    cp certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr /tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr
fi
echo ""

# Create a external config file for the certificate
cat > certs/cert.conf <<EOF

authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}

EOF

# Create SSl with self signed CA
if [ ! -f "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt" ]; then
    touch "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt"
    echo "empty ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt file created."
else
    echo "${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt file already exists."
fi
echo ""

if diff -q "/tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt" "certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt" >/dev/null; then
    echo "${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt files are identical, skipping creation"
else
    echo "the files are not identical, Generating ${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt"
    openssl x509 -req \
    -in certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.csr \
    -CA certs/rootCA.crt -CAkey certs/rootCA.key \
    -CAcreateserial -out certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt \
    -days 3650 \
    -sha256 -extfile certs/cert.conf
    cp certs/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt /tmp/${myArray[HOSTNAME1]}.${myArray[DOMAIN_NAME]}.crt
fi
echo ""

#Fix lam folder permissions
chown -R www-data:www-data lam
