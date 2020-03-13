#!/bin/bash
echo 'Starting Salesforce Prepare Build Job'
echo 'Branch_Name = ' $1
git checkout master
#cd /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/src
cd $2/sf_dev_ops_sbxsync/src

echo 'cd to base dir'

pwd
#cp -r -v * /var/lib/jenkins/sf-build-job/git/sf_dev_ops/src
cp -rf -v * /var/lib/jenkins/workspace/DreamHouseDemo_Pipeline/src
echo 'copy files to workspace dir'
cd /var/lib/jenkins/workspace/DreamHouseDemo_Pipeline
pwd
echo 'switch to workspace'
#git init
pwd
echo 'current dir'
echo "#File creted on `date`" >> test
git checkout $Branch_Name
git add .
echo "Add "
#git commit -m "FIle checked-in on `date +'%Y-%m-%d %H:%M:%S'`";
echo 'commit files'
#git commit -m "first commit"

#git remote add origin git@github.com:renupawar95/dreamhousedemo.git
#git remote set-url origin git@github.com:renupawar95/dreamhousedemo.git
#git remote add mon1 https://nitika-sfdc:January2019@github.com/nitika-sfdc/Salesforce-Checkin.git
#git remote -v
git push -u origin master
#rm -rf /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/src/src1/





