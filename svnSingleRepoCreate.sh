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

######################################################
# Date Modified: 19th Jul 2013
# Author : Tapas
######################################################


# Change this to point the url and path of the repository
#REPO_URL=svn+ssh://mac@192.168.51.95
#REPO_URL=svn+ssh://cdac@192.168.70.70
REPO_URL=file://
#REPOS_PATH=/home/cdac/Desktop
REPOS_PATH=$HOME
 
SVNADMIN=`which svnadmin`
EXPECTED_ARGS=1
E_BADARGS=65
REPO=$1
PASSWDFILE=$REPOS_PATH/$REPO"/passwd"
AUTHZFILE=$REPOS_PATH/$REPO"/authz"
PASSWDSLIST=$REPOS_PATH/$REPO/password.txt

folder[0]='trunk'
folder[1]='branches'
folder[2]='tags'

numOfFolders=${#folder[@]}
#for i in $(seq 0 $numOfFolders)
#do
#        echo ${folder[$i]}
#done



function setupHTTP(){
	TEMPFILE='mynewlist'
	echo "Creating HTTP configuration..."
	echo "<Location /svn>" > $TEMPFILE
	echo "DAV svn" >> $TEMPFILE
	#echo "SVNPath "$REPOS_PATH/$REPO >> $TEMPFILE
	echo "SVNParentPath "$REPOS_PATH/$REPO >> $TEMPFILE
	#echo "AuthzSVNAccessFile /etc/subversion/authz" >> $TEMPFILE
	echo "AuthType Basic" >> $TEMPFILE
	echo 'AuthName "DESD Subversion Repository"' >> $TEMPFILE
	echo "AuthUserFile $PASSWDFILE" >> $TEMPFILE
	echo "AuthzSVNAccessFile $AUTHZFILE" >> $TEMPFILE
	#echo 'SVNIndexXSLT "/svnindex.xsl"' >> $TEMPFILE
	echo "Require valid-user" >> $TEMPFILE
	echo "</Location>" >> $TEMPFILE

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
	userName=$1
	echo "Setting Permissions for :"$userName
	for i in $(seq 0 `expr $numOfFolders - 1`)
	do
	echo "["$userName":/${folder[$i]}]" >> $AUTHZFILE
	echo $userName" = rw" >> $AUTHZFILE
	done
}

function setupPasswords(){
	echo "Creating password for"$1
	userPassword=$1
	if [ -e $PASSWDFILE ]
	then
		echo "existing"
		htpasswd -b $PASSWDFILE $1 $userPassword
	else 
		echo "Not existing, Creating ..."
		#touch $PASSWDFILE
		htpasswd -b -c $PASSWDFILE $1 $userPassword
	fi
	echo "Password for "$1"->$userPassword" >> $PASSWDSLIST
	updateAUTHZ $1
}

function setupComplexPassword(){
	echo "Creating password for"$1
	userPassword=`makepasswd --chars=6`
	if [ -e $PASSWDFILE ]
	then
		echo "password file existing"
		htpasswd -b $PASSWDFILE $1 $userPassword
	else 
		echo "password file Not existing, Creating ..."
		#touch $PASSWDFILE
		htpasswd -b -c $PASSWDFILE $1 $userPassword
	fi
	echo "Password for "$1"->$userPassword" >> $PASSWDSLIST
	updateAUTHZ $1
}
function addSVNGrp(){
	sudo addgroup subversion
	sudo usermod -a -G subversion www-data	
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

addSVNGrp
 
#$SVNADMIN create --fs-type fsfs $REPOS_PATH/$REPO
mkdir $REPOS_PATH/$REPO
 
chmod -R 2775 $REPOS_PATH/$1


read -p "ENTER user name :" Batch1Total


#svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH1 -m "Added Batch1"
echo "YOU ENTERED user name :$Batch1Total"

numOfDir=1
#echo $numOfDir

#echo "ENTER STARTING ROLL NO FOR BATCH 1"
#read startVal


for ((i = 0 ;i<$numOfDir;i++))
do	
	#userDir=$REPO_URL/$REPOS_PATH/$REPO/$startVal-$endVal
	userDir=$REPOS_PATH/$REPO/$Batch1Total
	echo $userDir
	$SVNADMIN create $userDir
	userDir=$REPO_URL$userDir
	addDirCmds="svn mkdir "
	for i in $(seq 0 `expr $numOfFolders - 1`)
	do
	        addDirCmds="$addDirCmds $userDir/${folder[$i]} "
	done
	#addDirCmds="$addDirCmds -m 'Initial Folders ${folder[@]} Added'"
	echo $addDirCmds
	$addDirCmds
	#svn mkdir $userDir/trunk \
	#$userDir/branches \
	#$userDir/tags 

	#svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH1/$startVal-$endVal/OS -m "OS Folder Added"
	#svn mkdir $REPO_URL/$REPOS_PATH/$REPO/$BATCH1/$startVal-$endVal/DD -m "DD Folder Added"

	setupPasswords $Batch1Total
	#setupComplexPassword $startVal $endVal

done

echo "Setting up HTTP..."
setupHTTP

echo "Changing Ownerships..."
sudo chown -cR www-data:subversion $REPOS_PATH/$REPO

echo "SVN Repository Creation Done !"

