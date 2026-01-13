#!/usr/bin/env bash
set -Eeuo pipefail

TERRAFORM_VERSION="1.11.1"
DOCKERCOMPOSE_VERSION="v2.32.2"
HOME="/home/vagrant"

sudo apt-get update
sudo apt-get install -y unzip

echo "installing: docker-compose"
pushd /usr/local/bin
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKERCOMPOSE_VERSION}/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" -o docker-compose
sudo chmod +x docker-compose
popd

echo "installing: terraform"
mkdir -p ${HOME}/bin
pushd ${HOME}/bin
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip
. ${HOME}/.profile
popd

pushd /vagrant
docker-compose up -d
popd

cp -a /vagrant/terraform/. ${HOME}/terraform/
pushd ${HOME}/terraform
terraform init
terraform apply -auto-approve
popd