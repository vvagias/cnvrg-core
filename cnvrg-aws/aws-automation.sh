#!/bin/bash
#automated AWS Linux deployments
#GET DOWNLOAD URL
cat << "EOF"
                                            _       _
                                           (_)     (_)
  ___ _ ____   ___ __ __ _ ______ _ __ ___  _ _ __  _
 / __| '_ \ \ / / '__/ _` |______| '_ ` _ \| | '_ \| |
| (__| | | \ V /| | | (_| |      | | | | | | | | | | |
 \___|_| |_|\_/ |_|  \__, |      |_| |_| |_|_|_| |_|_|
                     __/  |
                    |___ /

EOF
read -p "📝 What region are we deploying into? [ex. us-east-2] > " region
read -p "📝 AWS Key Name? [name of your local key in this dir ex. sshkey / blank to have one created] > " keyname
read -p "📝 AWS instance size? [ex. m4.4xlarge] > " ec2size
#set up the Manager
#us-east-1 ami-01ca03df4a6012157
echo "🛰 Creating a Minikube AMI Instance"
if [ "$keyname" != "" ]; then
    echo "Key Name is $keyname"
else
    echo "🛰 Creating Key Pair cnvrgKey.pem"
    aws ec2 create-key-pair --key-name cnvrgKey --region $region --query "KeyMaterial" --output text > cnvrgKey.pem
    chmod 400 $keyname.pem
    exit
fi
sleep 1
echo "🛰 Sending Instance Details to AWS"
MANAGER_ID=$(aws ec2 run-instances --image-id ami-02aa7f3de34db391a --count 1 --instance-type $ec2size --key-name $keyname  --region $region --output json --block-device-mappings '[
                        {
                            "DeviceName": "/dev/sda1",
                            "Ebs": {
                                "DeleteOnTermination": true,
                                "VolumeType": "standard",
                                "VolumeSize": 200
                            }
                        }
                    ]' | jq -r '.Instances[0].InstanceId')
echo "🟢 Manager ID is : $MANAGER_ID"
aws ec2 create-tags --resources $MANAGER_ID --tags Key=Name,Value=cnvrg-minikube-automated  --region $region --output json
sleep 5
MANAGER_IP=$(aws ec2 describe-instances --instance-id $MANAGER_ID --region $region --output json |  jq -r '.Reservations[0].Instances[0].PublicIpAddress')
echo "🟢 MANAGER IP : $MANAGER_IP"
MANAGER_PIP=$(aws ec2 describe-instances --instance-id $MANAGER_ID --region $region --output json |  jq -r '.Reservations[0].Instances[0].PrivateIpAddress')
STATUS=$(aws ec2 describe-instance-status --instance-id $MANAGER_ID  --region $region --output json |  jq -r '.InstanceStatuses[0].InstanceState.Code')
echo "Status : $STATUS"
while test $STATUS != "16"
do
  sleep 5
  echo "⌚️waiting for minikube to be ready 🛰 $STATUS ..."
  STATUS=$(aws ec2 describe-instance-status --instance-id $MANAGER_ID  --region $region --output json)
done
GROUP=$(aws ec2 describe-instance-attribute --instance-id $MANAGER_ID --attribute groupSet --region $region --output json | jq -r '.Groups[0].GroupId')
echo "Group ID for $CLUSTER_IP is : $GROUP"
aws ec2 authorize-security-group-ingress --group-id $GROUP --protocol all --region $region --cidr  $MANAGER_IP"/32" --output json
HOME_IP=$(curl https://ipecho.net/plain ; echo)
echo "$HOME_IP is your home ip"
aws ec2 authorize-security-group-ingress --group-id $GROUP --protocol all --region $region --cidr $HOME_IP"/32" --output json
X_READY=''
while [ ! $X_READY ]; do
    echo "⌚️ Waiting for ready status"
    sleep 10
    set +e
    OUT=$(ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no -o BatchMode=yes ubuntu@$MANAGER_IP 2>&1 | grep 'Permission denied' )
    [[ $? = 0 ]] && X_READY='ready'
    set -e
done
#get public ip $MANAGER_IP
#run setup
echo "🚀running setup with $keyname and $MANAGER_IP"
echo "🛠 setting up cnvrg... May take a few minutes. ⏱"
echo "Great time to grab a ☕️  coffee or 💧 water or 🍺 beer... or bacon  🥓  😋 "
echo "🛠or just enjoy these lovely automated logs doing work for you!"
ssh -i "$keyname".pem ubuntu@"$MANAGER_IP" 'bash -s' < cnvrg-setup-headless.sh $MANAGER_IP
echo "✅ cnvrg is up and running! Go to http://app.$MANAGER_IP.nip.io"
echo "💻 Sign in and create your user and a new organization. Enjoy! let us know if we can help help@cnvrg.io  📧"
