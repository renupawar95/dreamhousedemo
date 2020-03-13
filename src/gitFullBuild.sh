#!/bin/bash

################################################################################
echo 'Starting Salesforce Prepare Build Job'
echo 'Command Name = ' $0
echo 'Start Date   = ' $1
echo 'End Date     = ' $2
echo 'Branch Name  = ' $3
#echo 'Production Build         = ' $
echo 'Build Number =' $4
echo 'Build Prefix =' $5
################################################################################

#cd /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync
cd /var/lib/jenkins/workspace/DreamHouseDemo_Pipeline/src

if [[ `git branch --list $3`  ]];then
	echo "Branch " $3 "exists !"
else
	echo "Branch " $3 "does not exists !"
	exit;

fi

 sudo cp /dev/null /var/lib/jenkins/sf-build-job/git/out.log
sudo chmod 777 /var/lib/jenkins/sf-build-job/git/out.log
cp /dev/null /var/lib/jenkins/sf-build-job/git/main.log
chmod 777 /var/lib/jenkins/sf-build-job/git/main.log
cp /dev/null /var/lib/jenkins/sf-build-job/git/mainprocessed.log
chmod 777 /var/lib/jenkins/sf-build-job/git/mainprocessed.log

rm -rf /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/src
echo "Cleaned up Workspace looks like below..."
ls -alR /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/src

#cd /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync
cd /var/lib/jenkins/workspace/DreamHouseDemo_Pipeline/src
git pull
git checkout $3
git log --since $Start_Date --until $End_Date --name-only --pretty=format:"%H$" >> /var/lib/jenkins/sf-build-job/git/main.log


#svn log --stop-on-copy -r{$Start_Date}:{$End_Date} --username 'mbolt' --password 'mbolt' http://ec2-13-58-242-26.us-east-2.compute.amazonaws.com/repos/sfdc/$Branch_Name -v | egrep "^r[0-9]*|[A-Z] " | cut -d'|' -f1 | awk -F"[A-Z] " '{print $2$1}' >> /var/lib/jenkins/sf-build-job/main.log

index=0;
lines=`cat /var/lib/jenkins/sf-build-job/git/main.log`
IFS=$'\n'
        for line in $lines
        do
                echo '>> '$line
         #       echo $index "rev = " $rev "and value = " ${filenameArray[$index]}
#                pattern="[0-9a-z]+"
                if [[ $line = *\$ ]]; then
                        echo "pattern" $line
                        rev=`echo $line | cut -d '$' -f1`
                        echo "rev =" $rev
                else
                        filex=$(basename "$line")
                        echo "filex = "$filex
                        if [[ $filex = *.* ]] ; then
                                echo "hello"
                                filenameArray[$index]=$index" & "$line" & "$rev
                        else
                                filenameArray[$index]=$index" & "$line" & "$rev
                        fi
                        ((index++))
                 fi
        done
echo ${#filenameArray[@]}
echo ${filenameArray[@]}

num=${#filenameArray[@]}
echo "num = " $num

for (( i=0; i<=num+1; i++ ))
do
        if [ "${#filenameArray[i]}" -eq 0 ]; then
                echo "i = " $i position has no elements
                continue
        fi

        echo ${filenameArray[i]} >> /var/lib/jenkins/sf-build-job/git/mainprocessed.log
done


cat /var/lib/jenkins/sf-build-job/git/mainprocessed.log | awk -F"&" '{print$1"@"$2"@"$3}' | sort -n | awk -F " " '!arr[$3]++' >> /var/lib/jenkins/sf-build-job/git/out.log

mkdir -p /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/src/

cat /var/lib/jenkins/sf-build-job/git/out.log | while read line
do
  file=$(echo $line | awk -F"@" '{printf" "$2" "}'|xargs)
  version=$(echo $line | awk -F"@" '{printf" "$3" "}'|xargs)
  echo "Processing file " $file   " Version:=>" $version

  fileName=$(basename "$file")
  #echo "fileName = "$fileName
  if [[ $fileName = *.* ]] ; then
        dir=$(dirname "$file")
        mkdir -p /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/"$dir"
        exportDir=$dir
  else
  #     echo "Its not file..."
        mkdir -p /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/"$file"
        exportDir=$file
  fi


  if [[ $file == *".cls"* ]];then
     #sync1=`p4 sync -f $file`
         cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     if [[ $file != *".cls-meta.xml"* ]];then
        #echo "Getting the Meta XML"
        metaXML=$(echo $file |cut -d '@' -f1 |sed 's/\.cls/.cls-meta.xml/')
        echo $metaXML
        #sync1=`p4 sync -f $metaXML`
        cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$metaXML /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     fi
  fi

  # component File Filter
  if [[ $file == *".component"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     if [[ $file != *".component-meta.xml"* ]];then
        metaXML=$(echo $file |cut -d '#' -f1 |sed 's/\.component/.component-meta.xml/')
        cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$metaXML /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     fi
  fi

  # Email File Filter
  if [[ $file == *".email"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     if [[ $file != *".email-meta.xml"* ]];then
        metaXML=$(echo $file |cut -d '#' -f1 |sed 's/\.email/.email-meta.xml/')
        cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$metaXML /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     fi
  fi

  # Page File Filter
  if [[ $file == *".page"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     if [[ $file != *".page-meta.xml"* ]];then
        metaXML=$(echo $file |cut -d '#' -f1 |sed 's/\.page/.page-meta.xml/')
        cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$metaXML /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     fi
  fi

  # resource File Filter
  if [[ $file == *".resource"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     if [[ $file != *".resource-meta.xml"* ]];then
        metaXML=$(echo $file |cut -d '#' -f1 |sed 's/\.resource/.resource-meta.xml/')
        cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$metaXML /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     fi
  fi

   # trigger File Filter
  if [[ $file == *".trigger"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     if [[ $file != *".trigger-meta.xml"* ]];then
        metaXML=$(echo $file |cut -d '#' -f1 |sed 's/\.trigger/.trigger-meta.xml/')
        cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$metaXML /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
     fi
  fi

  # analyticSnapshots File Filter
  if [[ $file == *".snapshots"* ]];then
        cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # applications File Filter
  if [[ $file == *".app"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # dashboards File Filter
  if [[ $file == *".dashboard"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # datacategorygroups File Filter
  if [[ $file == *".datacategorygroup"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # flows File Filter
  if [[ $file == *".flow"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  
   # homePageLayouts File Filter
  if [[ $file == *".homePageLayout"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # labels File Filter
  if [[ $file == *".labels"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # layouts File Filter
  if [[ $file == *".layout"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # object File Filter
  if [[ $file == *".object"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # objectTranslations File Filter
 # if [[ $file == *".objectTranslation"* ]];then
 # cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
 #
 # fi

  # portals File Filter
  if [[ $file == *".portal"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # profiles File Filter
  if [[ $file == *"profile"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

   # remoteSiteSettings File Filter
  if [[ $file == *".remoteSite"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # reports File Filter
  if [[ $file == *".report"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # reportTypes File Filter
  if [[ $file == *".reportType"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # sites File Filter
  if [[ $file == *".site"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  # tabs File Filter
  if [[ $file == *".tab"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

 # # translations File Filter
 # if [[ $file == *".translation"* ]];then
 #    cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir
 #
 # fi

  # weblinks File Filter
  if [[ $file == *".weblink"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi

  
   # workflows File Filter
  if [[ $file == *".workflow"* ]];then
     cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/$file /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/$exportDir

  fi



done

branchName=$(echo $3 | sed 's/\/\...//g')
echo "Branch Name:" $branchName


#p4 sync -f $branchName/ant-salesforce.jar#head
cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/src/ant-salesforce.jar /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/src/
#p4 sync -f $branchName/deployable-package.xml#head
cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/src/deployable-package.xml /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/src/
#p4 sync -f $branchName/package.xml#head
cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/src/package.xml /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/src/
#p4 sync -f $branchName/jenkins-build.xml#head
cp /var/lib/jenkins/sf-build-job/git/sf_dev_ops_sbxsync/src/jenkins-build.xml /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/src/

#p4 sync -f $branchName/pages/version.page-fragment.1#head
#p4 sync -f $branchName/pages/version.page-fragment.2#head
#p4 sync -f $branchName/pages/version.page-meta.xml.rename#head

###################################################################################
mkdir -p /var/lib/jenkins/sf-build-job/git/build/build-$4
cd /var/lib/jenkins/sf-build-job/git/build/build-$4/
#cp -r /opt/jenkins.new/jobs/SF-Build-Pipeline/workspace/sfdc/RELEASES/Release59-Deployable/src .
cp -r /var/lib/jenkins/jobs/MBOLT-ContinuousDelivery-GIT/workspace/sfdc/src .
cd /var/lib/jenkins/sf-build-job/git/build/build-$4/
###################################################################################
#echo "Now Updating Version Information..."
#systemDate=$(date +%m-%d-%Y@%H:%M:%S%Z)
#echo "System Date : " $systemDate
#version="$6_$5"
#echo "Version Information :" $version
#sed -i 's/PUT_VERSION_HERE/'$version'/g' /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-fragment.1

#echo $systemDate
#sed -i 's/PUT_BUILD_DATE_HERE/'$systemDate'/g' /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-fragment.1

#sed -i 's/PUT_BUILD_OWNER_HERE/'Jenkins-User'/g' /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-fragment.1
#echo "Delete If version.page exists in source control.. we want to create a new page every time"
#rm /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page
#cat /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-fragment.1 /opt/jenkins.new/sf-build-job/out.log /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-fragment.2 > /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page

#mv /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-meta.xml.rename /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-meta.xml
#rm /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-fragment.1
#rm /opt/jenkins.new/sf-build-job/build/build-$5/src/pages/version.page-fragment.2
###################################################################################
buildZip=$(echo salesforce-build-$4.zip)
pwd
zip -r $buildZip *
