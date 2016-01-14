#!/usr/bin/env bash

# ----------------- Install Development Tools Group ----------------- #
echo "-- Installing Yum Group Development Tools --"

yum -y -q groupinstall "Development Tools"

echo "-- Yum Group Development Tools Installed --"


# ----------------- Get Tomcat 7 ----------------- #
echo "-- Installing Tomcat 7 --"

#get tomcat 7 from apache
wget http://apache.mirror.vexxhost.com/tomcat/tomcat-8/v8.0.30/bin/apache-tomcat-8.0.30.tar.gz -P /opt 1> NUL 2> NUL

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
/usr/bin/mysqladmin -u root password 'password'

# Allow remote access
mysql -u root -ppassword -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password' WITH GRANT OPTION;"

# Drop the anonymous users
mysql -u root -ppassword -e "DROP USER ''@'localhost';"
mysql -u root -ppassword -e "DROP USER ''@'$(hostname)';"

# Drop the demo database
mysql -u root -ppassword -e "DROP DATABASE test;"

# Flush privledges
mysql -u root -ppassword -e "FLUSH PRIVILEGES;"

# Restart the mysqld service
service mysqld restart

# Set mysqld to start on system start
chkconfig mysqld on

#Install the mysql oracle connector
cd /opt
wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.37.tar.gz 1> NUL 2> NUL
tar -xzf mysql-connector-java-5.1.37.tar.gz -C /opt
cp /opt/mysql-connector-java-5.1.37/mysql-connector-java-5.1.37-bin.jar /opt/tomcat/lib
cd /opt/tomcat
mkdir common
cd common
mkdir lib
cd /opt
cp /opt/mysql-connector-java-5.1.37/mysql-connector-java-5.1.37-bin.jar /opt/tomcat/common/lib
rm -rf /opt/mysql-connector-java-5.1.37

echo "-- Mysql Installed --"


# ----------------- Clone Sakai into /opt/sakai-src ----------------- #
echo "-- Cloning Sakai source --"

# make a new dir for sakai-src
mkdir /opt/sakai-src

# move there
cd /opt/sakai-src

#clone the most recent version of sakai
git clone https://github.com/sakaiproject/sakai.git

echo "-- Sakai source cloned into /opt/sakai-src --"


# ----------------- Set Environmental Variables ----------------- #
echo "-- Setting Environmental Variables --"

#Set JAVA_HOME
echo "export JAVA_HOME=/usr/java/jdk1.8.0_60" >> /etc/profile
#echo "export PATH=/usr/java/jdk1.8.0_60/bin:$PATH" >> /etc/profile

#Set CATALINA_HOME
echo "export CATALINA_HOME=/opt/tomcat" >> /etc/profile
#echo "export PATH=/opt/tomcat/bin:$PATH" >> /etc/profile

#Set Maven
echo "export MAVEN2_HOME=/usr/local/maven" >> /etc/profile
echo "export M2_HOME=/usr/local/maven" >> /etc/profile
echo "export MAVEN_OPTS='-Xms128m -Xmx796m -XX:PermSize=64m -XX:MaxPermSize=172m'" >> /etc/profile

#add ALL PATH in /etc/profile
echo "PATH=$PATH:/usr/local/maven/bin:/usr/java/jdk1.8.0_60/bin:/opt/tomcat/bin" >> /etc/profile

#Reload profile
source /etc/profile

#Set JAVA_OPTS in tomcat env file
touch /opt/tomcat/bin/setenv.sh
echo "export JAVA_OPTS='-server -Xms512m -Xmx1024m -XX:PermSize=128m -XX:MaxPermSize=512m -XX:NewSize=192m -XX:MaxNewSize=384m -Djava.awt.headless=true -Dhttp.agent=Sakai -Dorg.apache.jasper.compiler.Parser.STRICT_QUOTE_ESCAPING=false -Dsun.lang.ClassLoader.allowArraySyntax=true'" >> /opt/tomcat/bin/setenv.sh

#Set sakai.properties
cd $CATALINA_HOME
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
cd /home/vagrant
mkdir .m2
cd .m2
touch settings.xml
echo "<settings xmlns="http://maven.apache.org/POM/4.0.0"" >> /home/vagrant/.m2/settings.xml
echo "   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"" >> /home/vagrant/.m2/settings.xml
echo "   xsi:schemaLocation="http://maven.apache.org/POM/4.0.0" >> /home/vagrant/.m2/settings.xml
echo "                      http://maven.apache.org/xsd/settings-1.0.0.xsd">" >> /home/vagrant/.m2/settings.xml
echo "  <profiles>" >> /home/vagrant/.m2/settings.xml
echo "    <profile>" >> /home/vagrant/.m2/settings.xml
echo "      <id>tomcat5x</id>" >> /home/vagrant/.m2/settings.xml
echo "      <activation>" >> /home/vagrant/.m2/settings.xml
echo "        <activeByDefault>true</activeByDefault>" >> /home/vagrant/.m2/settings.xml
echo "      </activation>" >> /home/vagrant/.m2/settings.xml
echo "      <properties>" >> /home/vagrant/.m2/settings.xml
echo "        <appserver.id>tomcat5x</appserver.id>" >> /home/vagrant/.m2/settings.xml
echo "        <appserver.home>/opt/tomcat</appserver.home>" >> /home/vagrant/.m2/settings.xml
echo "        <maven.tomcat.home>/opt/tomcat</maven.tomcat.home>" >> /home/vagrant/.m2/settings.xml
echo "        <sakai.appserver.home>/opt/tomcat</sakai.appserver.home>" >> /home/vagrant/.m2/settings.xml
echo "        <surefire.reportFormat>plain</surefire.reportFormat>" >> /home/vagrant/.m2/settings.xml
echo "        <surefire.useFile>false</surefire.useFile>" >> /home/vagrant/.m2/settings.xml
echo "      </properties>" >> /home/vagrant/.m2/settings.xml
echo "    </profile>" >> /home/vagrant/.m2/settings.xml
echo "  </profiles>" >> /home/vagrant/.m2/settings.xml
echo "</settings>" >> /home/vagrant/.m2/settings.xml
#maven settings ends




echo "-- Environmental Variables Set --"
