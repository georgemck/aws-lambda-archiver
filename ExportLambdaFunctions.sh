#!/bin/bash
#Credits to Github user https://gist.github.com/TheNetJedi and friends
#Requires installation of jq https://www.programmerhat.com/jq-command-not-found/

#tested on Ubuntu-20

echo "Enter AWS profile name (type default)"
read profile
echo "The AWS profile is: $profile"

echo "Enter AWS region (such as us-east-1)"
read region
echo "The region is: $region"

echo "Enter bucketname"
read bucketname
echo "The bucket name is: $bucketname"

echo "Enter folder name"
read folder
echo "The bucket name is: $folder"

#printf "%s\n" "c"

#!/usr/bin/env bash
#You need to have aws-cli installed and configured
#Credits to Reddit user u/aa93 for the suggestions
timestamp="$(date +%s)"
foldername="${folder}${timestamp}"

mkdir $foldername
aws --profile $profile --region $region lambda list-functions | \
grep FunctionName | \
cut -d '"' -f4 | \
while read -r name; do
    aws --profile $profile --region $region lambda get-function --function-name $name | tee ./$foldername/$name.json | jq -r '.Code.Location' | xargs curl --output ./$foldername/$name.zip
done

bucketstatus=$(aws --profile $profile --region $region s3api head-bucket --bucket "${bucketname}" 2>&1)
if echo "${bucketstatus}" | grep 'Not Found';
then
  echo "bucket doesn't exist";
  aws --profile $profile --region $region s3api create-bucket --bucket $bucketname --no-cli-pager
  aws --profile $profile --region $region s3 cp ./$foldername "s3://$bucketname" --recursive 
elif echo "${bucketstatus}" | grep 'Forbidden';
then
  echo "Bucket exists but not owned"
elif echo "${bucketstatus}" | grep 'Bad Request';
then
  echo "Bucket name specified is less than 3 or greater than 63 characters"
else
  echo "Bucket owned and exists";
fi
