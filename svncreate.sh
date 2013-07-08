#!/bin/bash

######################################################
# Description : Script to create the SVN repository
# Date Created : 31st October 2011
# Author : Poonguzhali P
######################################################

######################################################
# Date Modified: 25th Nov 2011
# Author : Tapas
######################################################


# Change this to point the url and path of the repository
#REPO_URL=svn+ssh://mac@192.168.51.95
#REPO_URL=svn+ssh://cdac@192.168.70.70
REPO_URL=file://
#REPOS_PATH=/home/cdac/Desktop
REPOS_PATH=/tmp
 
SVNADMIN=`which svnadmin`
EXPECTED_ARGS=1
E_BADARGS=65
REPO=$1
PASSWDFILE=$REPOS_PATH/$REPO"/passwd"
AUTHZFILE=$REPOS_PATH/$REPO"/authz"
PASSWDSLIST=$REPOS_PATH/$REPO/password.txt

function setupHTTP(){
	TEMPFILE='mynewlist'
	echo "Creating HTTP configuration..."
	echo "DAV svn" > $TEMPFILE
	#echo "SVNPath "$REPOS_PATH/$REPO >> $TEMPFILE
	echo "SVNParentPath "$REPOS_PATH/$REPO >> $TEMPFILE
	#echo "AuthzSVNAccessFile /etc/subversion/authz" >> $TEMPFILE
	echo "AuthType Basic" >> $TEMPFILE
	echo 'AuthName "DESD Subversion Repository"' >> $TEMPFILE
	echo "AuthUserFile $PASSWDFILE" >> $TEMPFILE
	echo "AuthzSVNAccessFile $AUTHZFILE" >> $TEMPFILE
	echo 'SVNIndexXSLT "/svnindex.xsl"' >> $TEMPFILE
	echo "Require valid-user" >> $TEMPFILE

	echo "Creating BACKUP file for 'dav_svn.conf' --> 'dav_svn.conf.bak'"
	sudo cp /etc/apache2/mods-available/dav_svn.conf /etc/apache2/mods-available/dav_svn.conf.bak

	echo "Writing into the 'dav_svn.conf' file..."
	sed "/^<Location\ \/svn>/r $TEMPFILE" /etc/apache2/mods-available/dav_svn.conf > /tmp/file.tmp

	#sed "/^<\Location>/r $TEMPFILE" /etc/apache2/mods-available/dav_svn.conf > /tmp/file.tmp
	sudo cp $TEMPFILE /etc/apache2/mods-available/dav_svn.conf

	sudo /etc/init.d/apache2 restart
	#exit
}
function updateAUTHZ(){
	userName=$1-$2
	echo "Setting Permissions for :"$userName
	echo "["$userName":/trunk]" >> $AUTHZFILE
	echo $userName" = rw" >> $AUTHZFILE
}

function setupPasswords(){
	echo "Creating password for"$1-$2
	userPassword=$1$2
	if [ -e $PASSWDFILE ]
	then
		echo "existing"
		htpasswd -b $PASSWDFILE $1-$2 $userPassword
	else 
		echo "Not existing, Creating ..."
		#touch $PASSWDFILE
		htpasswd -b -c $PASSWDFILE $1-$2 $userPassword
	fi
	echo "Password for "$1-$2"->$userPassword" >> $PASSWDSLIST
	updateAUTHZ $1 $2
}

function setupComplexPassword(){
	echo "Creating password for"$1-$2
	userPassword=`makepasswd --chars=6`
	if [ -e $PASSWDFILE ]
	then
		echo "password file existing"
		htpasswd -b $PASSWDFILE $1-$2 $userPassword
	else 
		echo "password file Not existing, Creating ..."
		#touch $PASSWDFILE
		htpasswd -b -c $PASSWDFILE $1-$2 $userPassword
	fi
	echo "Password for "$1-$2"->$userPassword" >> $PASSWDSLIST
	updateAUTHZ $1 $2
}

 
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 reponame"
  exit $E_BADARGS
fi

if [ ! -e /etc/apache2/mods-available/dav_svn.load ]; then
echo 'SVN module for apache not present.'
exit 1
fi
 
#$SVNADMIN create --fs-type fsfs $REPOS_PATH/$REPO
mkdir $REPOS_PATH/$REPO
 
chmod -R 2775 $REPOS_PATH/$1


BATCH1=
BATCH2=

#echo "ENTER TOTAL STUDENTS IN BATCH 1 "
#read Batch1Total

read -p "ENTER TOTAL STUDENTS IN BATCH 1 :" Batch1Total


#svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH1 -m "Added Batch1"
echo "YOU ENTERED TOTAL BATCH 1  :$Batch1Total"

numOfDir=`expr $Batch1Total/2`
#echo $numOfDir

#echo "ENTER STARTING ROLL NO FOR BATCH 1"
#read startVal

read -p "ENTER STARTING ROLL NO FOR BATCH 1 :" startVal


for ((i = 0 ;i<$numOfDir;i++))
do	
	endVal=$(( startVal + 1))
	$SVNADMIN create $REPOS_PATH/$REPO/$BATCH1/$startVal-$endVal
	svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH1/$startVal-$endVal/trunk \
	$REPO_URL/$REPOS_PATH/$REPO/$BATCH1/$startVal-$endVal/branches \
	$REPO_URL/$REPOS_PATH/$REPO/$BATCH1/$startVal-$endVal/tags -m "Trunk branches Tags Added"

	#svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH1/$startVal-$endVal/OS -m "OS Folder Added"
	#svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH1/$startVal-$endVal/DD -m "DD Folder Added"

	setupPasswords $startVal $endVal
	#setupComplexPassword $startVal $endVal

	startVal=$(( endVal + 1))
done


#svn mkdir  $REPO_URL/$REPOS_PATH/$REPO/$BATCH2 -m "Added Batch2"
#echo "TOTAL STUDENTS IN BATCH 2 "
#read Batch2Total

read -p "ENTER TOTAL STUDENTS IN BATCH 2: " Batch2Total

echo "YOU ENTEREDD TOTAL BATCH 2  :$Batch2Total"

numOfDir=`expr $Batch2Total/2`


#echo "STARTING ROLL NO FOR BATCH 2"
#read startVal2

read -p "ENTER STARTING ROLL NO FOR BATCH 2: " startVal2


for ((i = 0 ;i<$numOfDir;i++))
do	
	endVal2=$(( startVal2 + 1))
	$SVNADMIN create $REPOS_PATH/$REPO/$BATCH2/$startVal2-$endVal2
	svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH2/$startVal2-$endVal2/trunk -m "Trunk Folder Added"

	#svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH2/$startVal2-$endVal2/OS -m "OS Folder Added"
	#svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH2/$startVal2-$endVal2/DD -m "DD Folder Added"

	setupPasswords $startVal2 $endVal2
	#setupComplexPassword $startVal2 $endVal2

	startVal2=$(( endVal2 + 1))
done

echo "Setting up HTTP..."
setupHTTP

echo "Changing Ownerships..."
sudo chown -cR www-data:subversion $REPOS_PATH/$REPO

echo "SVN Repository Creation Done !"

