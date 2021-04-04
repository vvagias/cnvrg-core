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
if [ "$1" != "" ]; then
    export CLUSTER_IP="$1"
    echo "✅ CLUSTER_IP is $1"
else
    echo "⛔️ CLUSTER_IP - parameter 1 is empty"
    exit
fi
sudo -Es
curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
sudo apt-get update && \
sudo apt-get install docker.io -y
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
sudo apt-get install -y conntrack
minikube start --vm-driver=none
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
helm repo add cnvrg https://charts.cnvrg.io
helm repo update
echo "📌 Domain is set to "
echo ${CLUSTER_IP}.nip.io
#minikube AWS EC2 install
echo "☸️  helm installing cnvrg 🛠"
helm install cnvrg cnvrg/cnvrg -n cnvrg --create-namespace --timeout 1500s --set networking.istio.externalIp=$(minikube ip) --set clusterDomain=$CLUSTER_IP.nip.io --set computeProfile=small --set global.high_availability=false --set cnvrgApp.image=cnvrg/core:3.6.99
#minikube local install
#helm install cnvrg cnvrg/cnvrg -n cnvrg --create-namespace --set networking.istio.externalIp=$(minikube ip) --set clusterDomain=$(minikube ip) --set computeProfile=small --set global.high_availability=false
#Cloud install no minikube workaround
#helm install cnvrg cnvrg/cnvrg -n cnvrg --create-namespace --timeout 1500s --set networking.istio.externalIp=$CLUSTER_IP --set clusterDomain=$CLUSTER_IP.nip.io --set computeProfile=small --set global.high_availability=false
exit
