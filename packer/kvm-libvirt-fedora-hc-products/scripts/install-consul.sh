#!/bin/sh

CONSUL_VERSION="1.7.4+ent"
cd /tmp/
curl https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip -o consul.zip

sudo unzip consul.zip -d /usr/local/bin

consul -autocomplete-install
complete -C /usr/local/bin/consul consul
sudo rm -rf /tmp/consul.zip

consul version

sudo mkdir -p /opt/consul/{config,data,tls/ca}
sudo mkdir -p /etc/consul.d
sudo chmod a+w /etc/consul.d

sudo chown -R hcops:hcops /opt/consul

cat <<-EOF | sudo tee /etc/systemd/system/consul.service
[Unit]
Description=Consul
Documentation=https://consul.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecReload=/usr/local/bin/consul reload
ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul.d -data-dir /opt/consul
KillMode=process
KillSignal=SIGINT
LimitNOFILE=infinity
LimitNPROC=infinity
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
TasksMax=infinity
User=hcops
Group=hcops

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable consul
