#!/bin/sh

# echo "Installing Docker... actually Podman"
# sudo yum -y install podman-docker
# sudo touch /etc/containers/nodocker
# docker --version
# podman --version

# echo "Installing some packages"
# sudo yum -y install unzip curl tree vim

NOMAD_VERSION="0.10.4"
cd /tmp/
curl https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip

sudo unzip nomad.zip -d /usr/local/bin

nomad -autocomplete-install
complete -C /usr/local/bin/nomad nomad
sudo rm -rf /tmp/nomad.zip

nomad version

sudo mkdir -p /opt/nomad
sudo mkdir -p /etc/nomad.d
sudo chmod a+w /etc/nomad.d

sudo chown -R hcops:hcops /opt/nomad

cat <<-EOF | sudo tee /etc/systemd/system/nomad.service
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/nomad agent -config /etc/nomad.d -data-dir /opt/nomad
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable nomad
