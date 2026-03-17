#!/usr/bin/env bash
set -Eeuo pipefail

# APP_ENV is passed from Vagrant (dev/test/qa)
ENV_FILE="/vagrant/.env.${APP_ENV}"

set -a
. ${ENV_FILE}
set +a


if ! command -v unzip >/dev/null 2>&1; then
    echo "inzip not installed"
    sudo apt-get update
    sudo apt-get install -y unzip
else
    echo "unzip installed"
fi

if ! command -v docker >/dev/null 2>&1; then
    echo "install docker"
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ``
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "docker installed"
fi

if ! command -v docker-compose >/dev/null 2>&1; then
    echo "installing: docker-compose"
    pushd /usr/local/bin
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKERCOMPOSE_VERSION}/docker-compose-$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)" -o docker-compose
    sudo chmod +x docker-compose
    popd
else
    echo "docker-compose installed"
fi

if ! command -v terraform >/dev/null 2>&1; then
    echo "installing: terraform"
    mkdir -p ${HOME}/bin
    pushd ${HOME}/bin
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -O terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    unzip -o terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    . ${HOME}/.profile
    popd
else
    echo "Terraform installed"
fi

pushd /vagrant

echo "[run.sh] Using ${ENV_FILE}"
docker compose --env-file "${ENV_FILE}" up -d

popd

echo "run terraform apply"
cp -a /vagrant/terraform/. ${HOME}/terraform/
pushd ${HOME}/terraform
terraform init
terraform apply -auto-approve -var-file ./vars/${APP_ENV}.tfvars
popd