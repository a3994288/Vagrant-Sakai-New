#!/usr/bin/env bash

# ----------------- Install Development Tools Group ----------------- #
echo "-- Installing Yum Group Development Tools --"

yum -y -q groupinstall "Development Tools"

echo "-- Yum Group Development Tools Installed --"


# ----------------- Get Tomcat 8 ----------------- #
echo "-- Installing Tomcat 8 --"

#get tomcat 8 from apache
wget http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.30/bin/apache-tomcat-8.0.30.tar.gz -P /opt 1> NUL 2> NUL

#untar
tar -zxf /opt/apache-tomcat-8.0.30.tar.gz -C /opt

#move the folder to just tomcat
mv /opt/apache-tomcat-8.0.30 /opt/tomcat

#remove the archive
rm -f /opt/apache-tomcat-8.0.30.tar.gz

#remove default webapps
rm -rf /opt/tomcat/webapps/*

echo "-- Tomcat Installed to /opt/tomcat --"


# ----------------- Install Java 1.8 (8) ----------------- #
echo "-- Installing Java 1.8 --"

#move to temp
cd /tmp	

#download oracle jre
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jre-8u60-linux-x64.rpm" 1> NUL 2> NUL
echo "-- JRE Downloaded --"

#download oracle jdk
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.rpm" 1> NUL 2> NUL
echo "-- JDK Downloaded --"

#install jre
yum -y -q localinstall jre-8u60-linux-x64.rpm

#install jdk
yum -y -q localinstall jdk-8u60-linux-x64.rpm

echo "-- Java 1.8 Installed --"


# ----------------- Install Maven ----------------- #
echo "-- Installing Maven --"

#download mvn 3.0
wget http://archive.apache.org/dist/maven/maven-3/3.2.5/binaries/apache-maven-3.2.5-bin.tar.gz 1> NUL 2> NUL

#untar to /usr/local
tar -xzf apache-maven-3.2.5-bin.tar.gz -C /usr/local

#move to usr/local
cd /usr/local

#system link the folder to maven
ln -s apache-maven-3.2.5 maven

#make the file
touch /etc/profile.d/maven.sh

#run it now so we don't have to login/logout
##no permission to run this
##/etc/profile.d/maven.sh


echo "-- Maven Installed --"


# ----------------- Install MySql ----------------- #
echo "-- Installing Mysql --"

# Sudo yum -y update
yum -y -q install mysql-server

# Restart mysql
service mysqld restart

# Set root password
/usr/bin/mysqladmin -u root password 'mysqlpwd1'

# Allow remote access
mysql -u root -pmysqlpwd1 -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;"

# Drop the anonymous users
mysql -u root -pmysqlpwd1 -e "DROP USER ''@'localhost';"
mysql -u root -pmysqlpwd1 -e "DROP USER ''@'$(hostname)';"

# Drop the demo database
mysql -u root -pmysqlpwd1 -e "DROP DATABASE test;"

# Sakai DB and user settings
mysql -u root -pmysqlpwd1 -e "create database sakai default character set utf8;"
mysql -u root -pmysqlpwd1 -e "grant all privileges on sakai.* to 'sakai'@'localhost' identified by 'ironchef';"
mysql -u root -pmysqlpwd1 -e "grant all privileges on sakai.* to 'sakai'@'127.0.0.1' identified by 'ironchef';"

# Flush privledges
mysql -u root -pmysqlpwd1 -e "FLUSH PRIVILEGES;"

# Restart the mysqld service
service mysqld restart

# Set mysqld to start on system start
chkconfig mysqld on

# Install the mysql oracle connector
cd /opt
wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.37.tar.gz 1> NUL 2> NUL
tar -xzf mysql-connector-java-5.1.37.tar.gz -C /opt
# copy to common/lib and lib, not sure which one is gonna need, so copied both
cp /opt/mysql-connector-java-5.1.37/mysql-connector-java-5.1.37-bin.jar /opt/tomcat/lib
cd /opt/tomcat
mkdir common
cd common
mkdir lib
cd /opt
cp /opt/mysql-connector-java-5.1.37/mysql-connector-java-5.1.37-bin.jar /opt/tomcat/common/lib
rm -rf /opt/mysql-connector-java-5.1.37

# restart mysql
service mysqld restart

echo "-- Mysql Installed --"


# ----------------- Clone Sakai into /opt/sakai-src ----------------- #
echo "-- Cloning Sakai source --"

# make a new dir for sakai-src
mkdir /opt/sakai-src

# move there
cd /opt/sakai-src

#clone the most recent version of sakai
# git clone https://github.com/a3994288/sakai.git
git clone https://github.com/sakaiproject/sakai.git

echo "-- Sakai source cloned into /opt/sakai-src --"


# ----------------- Set Environmental Variables ----------------- #
echo "-- Setting Environmental Variables --"

# Set JAVA_HOME
echo "export JAVA_HOME=/usr/java/jdk1.8.0_60" >> /etc/profile

# Set CATALINA_HOME
echo "export CATALINA_HOME=/opt/tomcat" >> /etc/profile

# Set Maven
echo "export MAVEN2_HOME=/usr/local/maven" >> /etc/profile
echo "export M2_HOME=/usr/local/maven" >> /etc/profile
echo "export MAVEN_OPTS='-Xms128m -Xmx796m -XX:PermSize=64m -XX:MaxPermSize=172m'" >> /etc/profile

# add ALL PATH in /etc/profile
echo "PATH=$PATH:/usr/local/maven/bin:/usr/java/jdk1.8.0_60/bin:/opt/tomcat/bin" >> /etc/profile

#Reload profile
source /etc/profile

#Set JAVA_OPTS in tomcat setenv file
touch /opt/tomcat/bin/setenv.sh
echo "export JAVA_OPTS='-server -Xms512m -Xmx1024m -XX:PermSize=128m -XX:MaxPermSize=512m -XX:NewSize=192m -XX:MaxNewSize=384m -Djava.awt.headless=true -Dhttp.agent=Sakai -Dorg.apache.jasper.compiler.Parser.STRICT_QUOTE_ESCAPING=false -Dsun.lang.ClassLoader.allowArraySyntax=true'" >> /opt/tomcat/bin/setenv.sh

#Set sakai.properties
cd /opt/tomcat
mkdir sakai
touch sakai.properties
echo "username@javax.sql.BaseDataSource=sakai" >> /opt/tomcat/sakai/sakai.properties
echo "password@javax.sql.BaseDataSource=ironchef" >> /opt/tomcat/sakai/sakai.properties
echo "vendor@org.sakaiproject.db.api.SqlService=mysql" >> /opt/tomcat/sakai/sakai.properties
echo "driverClassName@javax.sql.BaseDataSource=com.mysql.jdbc.Driver" >> /opt/tomcat/sakai/sakai.properties
echo "hibernate.dialect=org.hibernate.dialect.MySQL5InnoDBDialect" >> /opt/tomcat/sakai/sakai.properties
echo "url@javax.sql.BaseDataSource=jdbc:mysql://127.0.0.1:3306/sakai?useUnicode=true&characterEncoding=UTF-8" >> /opt/tomcat/sakai/sakai.properties
echo "validationQuery@javax.sql.BaseDataSource=select 1 from DUAL" >> /opt/tomcat/sakai/sakai.properties
echo "defaultTransactionIsolationString@javax.sql.BaseDataSource=TRANSACTION_READ_COMMITTED" >> /opt/tomcat/sakai/sakai.properties

#Set Maven settings file
#For vagrant user ONLY!!!!!
cd /root
mkdir .m2
cd .m2
touch settings.xml
echo '<settings xmlns="http://maven.apache.org/POM/4.0.0"' >> /root/.m2/settings.xml
echo '   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"' >> /root/.m2/settings.xml
echo '   xsi:schemaLocation="http://maven.apache.org/POM/4.0.0' >> /root/.m2/settings.xml
echo '                      http://maven.apache.org/xsd/settings-1.0.0.xsd">' >> /root/.m2/settings.xml
echo '  <profiles>' >> /root/.m2/settings.xml
echo '    <profile>' >> /root/.m2/settings.xml
echo '      <id>tomcat5x</id>' >> /root/.m2/settings.xml
echo '      <activation>' >> /root/.m2/settings.xml
echo '        <activeByDefault>true</activeByDefault>' >> /root/.m2/settings.xml
echo '      </activation>' >> /root/.m2/settings.xml
echo '      <properties>' >> /root/.m2/settings.xml
echo '        <appserver.id>tomcat5x</appserver.id>' >> /root/.m2/settings.xml
echo '        <appserver.home>/opt/tomcat</appserver.home>'>> /root/.m2/settings.xml
echo '        <maven.tomcat.home>/opt/tomcat</maven.tomcat.home>'>> /root/.m2/settings.xml
echo '        <sakai.appserver.home>/opt/tomcat</sakai.appserver.home>' >> /root/.m2/settings.xml
echo '        <surefire.reportFormat>plain</surefire.reportFormat>' >> /root/.m2/settings.xml
echo '       <surefire.useFile>false</surefire.useFile>' >> /root/.m2/settings.xml
echo '      </properties>' >> /root/.m2/settings.xml
echo '    </profile>'>> /root/.m2/settings.xml
echo '  </profiles>'>> /root/.m2/settings.xml
echo '</settings>' >> /root/.m2/settings.xml
# maven settings ends

# mysql cnf file settings
echo "deleting cnf file"
cd /etc
rm my.cnf
echo "recreate cnf file"
touch my.cnf
echo "[mysqld]" >> /etc/my.cnf
echo "default-storage-engine = InnoDB" >> /etc/my.cnf
echo "innodb_file_per_table" >> /etc/my.cnf
echo "character-set-server=utf8" >> /etc/my.cnf
echo "collation-server=utf8_general_ci" >> /etc/my.cnf
echo "lower_case_table_names =1" >> /etc/my.cnf
echo "datadir=/var/lib/mysql" >> /etc/my.cnf
echo "socket=/var/lib/mysql/mysql.sock" >> /etc/my.cnf
echo "user=mysql" >> /etc/my.cnf
echo "# Disabling symbolic-links is recommended to prevent assorted security risks" >> /etc/my.cnf
echo "symbolic-links=0" >> /etc/my.cnf
echo "[mysqld_safe]" >> /etc/my.cnf
echo "log-error=/var/log/mysqld.log" >> /etc/my.cnf
echo "pid-file=/var/run/mysqld/mysqld.pid" >> /etc/my.cnf

# cnf ends
echo "-- Environmental Variables Set --"

# start build sakai
# echo "Building Sakai"
# cd /opt/sakai-src/sakai
# mvn install -Dmaven.test.skip
# echo "Sakai Built"
# deploy sakai
# echo "Deploying Sakai"
# mvn clean install sakai:deploy -Dmaven.tomcat.home=/opt/tomcat
# echo "Sakai Deployed"

# Download Eclipse
echo "Eclipse setup"
cd /opt
wget http://eclipse.mirror.rafal.ca/technology/epp/downloads/release/mars/1/eclipse-jee-mars-1-linux-gtk-x86_64.tar.gz 1> NUL 2> NUL
# Expand the file
tar -xvzf eclipse-jee-mars-1-linux-gtk-x86_64.tar.gz

echo "Eclipse finished"
# GUI settings
echo "Install gui"
yum -y groupinstall "Desktop" "Desktop Platform" "X Window System" "Fonts"
yum -y groupinstall "Internet Browser"
yum -y groupinstall "Office Suite and Productivity"
service mysqld restart
echo "GUI ready, user:root    password:vagrant]"
echo "switch to windows use command: startx"
echo "bye"
reboot