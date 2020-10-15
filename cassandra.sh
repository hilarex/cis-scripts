#!/bin/bash

echo "Enter cassandra superuser username:"
read CASS_USER
echo "Enter cassandra superuser password:"
read CASS_PASSWD

echo "===== Part 1 ====="
echo "[+] Ensure a separate user and group exist for Cassandra : "
getent group |grep cassandra
getent passwd | grep cassandra
echo ""

echo "[+] Ensure the latest versions of java,python and cassandra :"
java -version
python -V
cassandra -v
echo ""

echo "[+] Ensure the Cassandra service is run as a non-root user :"
ps -aef | grep cassandra | grep java | cut -d' ' -f1
echo ""

echo "[+] Ensure clocks are synchronized on all nodes :"
ps -aef | grep ntp
ps -aef | grep chronyd
echo ""

echo "===== Part 2 ====="
cd /etc/cassandra
echo "[+] Ensure that authentication is enabled for Cassandra databases :"
cat cassandra.yaml | grep -in "authenticator:"
echo ""

echo "[+] Ensure that authorization is enabled for Cassandra databases :"
cat cassandra.yaml | grep -in "authorizer:"
echo ""

echo "===== Part 3 ====="
echo "[+] Ensure the cassandra and superuser roles are separate"
cqlsh -u $CASS_USER -p $CASS_PASSWD -e "SELECT role FROM system_auth.roles WHERE is_superuser = True ALLOW FILTERING;"
echo ""

echo "[+] Test default password :"
cqlsh -u cassandra -p cassandra -e "exit" 2>/dev/null
STATUS=$?
if [ $STATUS -eq 0 ];
then
	echo "Default password is used !"
fi
echo ""

echo "[+] Ensure there are no unnecessary roles or excessive privileges"
cqlsh -u $CASS_USER -p $CASS_PASSWD -e "list roles;"
cqlsh -u $CASS_USER -p $CASS_PASSWD -e "select * from system_auth.role_permissions;"
echo ""

echo "[+] Ensure that Cassandra is run using a non-privileged, dedicated service account"
ps -ef | egrep "^cassandra.*$"
echo ""

echo "[+] Ensure that Cassandra only listens for network connections on authorized interfaces"
cd /etc/cassandra
cat cassandra.yaml |grep listen_address
echo ""

echo "[+] Review User-Defined Roles"
cqlsh -u $CASS_USER -p $CASS_PASSWD -e "select role, can_login, member_of from system_auth.roles;"
echo ""

echo "[+] Review Superuser/Admin Roles"
cqlsh -u $CASS_USER -p $CASS_PASSWD -e "select role, is_superuser from system_auth.roles;"
echo ""

echo "===== Part 4 ====="
echo "[+] Ensure that logging is enabled"
nodetool getlogginglevels
echo ""

echo "[+] Ensure that auditing is enabled"
if [[ $(cassandra -v | cut -d '.' -f1) -lt 4 ]]; 
then
	echo "No auditing capability"
else
	cat /etc/dse/dse.yaml | grep "audit_logging_options"
fi
echo ""

echo "===== Part 5 ====="
echo "[+] Inter-node Encryption"
cat cassandra.yaml | grep -in "internode_encryption:"
echo ""

echo "[+] Client Encryption"
cat cassandra.yaml|grep client_encryption_options -A 20 |grep -E "enabled|optional"
echo ""
