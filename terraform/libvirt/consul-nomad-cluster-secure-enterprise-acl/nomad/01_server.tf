resource "libvirt_pool" "nomad" {
  name = "nomad"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-nomad"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image 
}

resource "tls_private_key" "nomad_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "nomad_ca" {
  key_algorithm   = tls_private_key.nomad_ca.algorithm
  private_key_pem = tls_private_key.nomad_ca.private_key_pem

  subject {
    common_name  = "nomad.msk.local"
    organization = "mskmania"
  }

  validity_period_hours = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "key_encipherment",
  ]
}

resource "tls_private_key" "nomad" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "random_string" "nomad_gossip_password" {
  length = 16
  special = true
}

resource "libvirt_volume" "volume_server" {
  name           = "volume-nomad-server-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.cluster_size
}

resource "tls_cert_request" "consul_client" {
  key_algorithm   = var.consul_private_key_algorithm
  private_key_pem = var.consul_private_key_pem

  dns_names = [
    "${var.datacenter}-client-consul-${count.index}",
    "${var.datacenter}-server-nomad-${count.index}",
    "client.${var.datacenter}.consul",
    "localhost"
  ]

  ip_addresses = [
    "127.0.0.1"
  ]

  subject {
    common_name  = "${var.datacenter}-client-consul-${count.index}"
    organization = "mskmania"
  }
  count = var.cluster_size
}

resource "tls_locally_signed_cert" "consul_client" {
  cert_request_pem   = tls_cert_request.consul_client[count.index].cert_request_pem
  ca_key_algorithm   = var.consul_private_key_algorithm
  ca_private_key_pem = var.consul_private_key_pem 
  ca_cert_pem        = var.consul_ca_cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  count = var.cluster_size
}

resource "tls_cert_request" "nomad_server" {
  key_algorithm   = tls_private_key.nomad.algorithm
  private_key_pem = tls_private_key.nomad.private_key_pem

  dns_names = [
    "${var.datacenter}-server-nomad-${count.index}",
    "server.${var.datacenter}.nomad",
    "server.global.nomad",
    "server.europe.nomad",
    "localhost",
    "127.0.0.1",
  ]

  subject {
    common_name  = "${var.datacenter}-server-nomad-${count.index}"
    organization = "mskmania"
  }
  count = var.cluster_size
}

resource "tls_locally_signed_cert" "nomad_server" {
  cert_request_pem   = tls_cert_request.nomad_server[count.index].cert_request_pem
  ca_key_algorithm   = tls_private_key.nomad_ca.algorithm
  ca_private_key_pem = tls_private_key.nomad_ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.nomad_ca.cert_pem

  validity_period_hours = 8760

  allowed_uses = [
    "cert_signing",
    "client_auth",
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]
  count = var.cluster_size
}

data "template_file" "consul_client_config" {
  template = "${file("${path.module}/templates/consul-client.json.tpl")}"
  vars = {
    node_name = "${var.datacenter}-server-nomad-${count.index}"
    consul_cluster_nodes = jsonencode(values(var.consul_cluster_servers))
    gossip_password = base64encode(var.consul_gossip_password)
    datacenter = var.datacenter
    consul_default_token = random_uuid.consul_default_token[count.index].result
  }
  count = var.cluster_size
}

data "template_file" "nomad_server_config" {
  template = "${file("${path.module}/templates/nomad-server.hcl.tpl")}"
  vars = {
    cluster_size     = var.cluster_size
    node_name        = "${var.datacenter}-server-nomad-${count.index}"
    datacenter       = var.datacenter
    gossip_password  = base64encode(random_string.nomad_gossip_password.result)
  }
  count = var.cluster_size
}

data "template_file" "user_data_nomad_server" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname         = "${var.datacenter}-server-nomad-${count.index}"
    consul_config    = base64encode(data.template_file.consul_client_config[count.index].rendered)
    nomad_config     = base64encode(data.template_file.nomad_server_config[count.index].rendered)
    consul_ca_file   = base64encode(var.consul_ca_cert_pem)
    nomad_ca_file    = base64encode(tls_self_signed_cert.nomad_ca.cert_pem)
    consul_cert_file = base64encode(tls_locally_signed_cert.consul_client[count.index].cert_pem)
    nomad_cert_file  = base64encode(tls_locally_signed_cert.nomad_server[count.index].cert_pem)
    consul_key_file  = base64encode(var.consul_private_key_pem)
    nomad_key_file   = base64encode(tls_private_key.nomad.private_key_pem)
  }
  count	= var.cluster_size
}

data "template_file" "network_config_client" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit_nomad_server" {
  name           = "commoninit-nomad-server-${count.index}.iso"
  user_data      = data.template_file.user_data_nomad_server[count.index].rendered
  network_config = data.template_file.network_config_client.rendered
  pool           = libvirt_pool.nomad.name
  count          = var.cluster_size
}

resource "random_uuid" "consul_default_token" { 
  count = var.cluster_size
}

resource "libvirt_domain" "nomad_server" {
  name       = "${var.datacenter}-server-nomad-${count.index}"
  count      = var.cluster_size
  cloudinit  = libvirt_cloudinit_disk.commoninit_nomad_server[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume_server.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'
EOT  
}

  provisioner "local-exec" {
    when = destroy 
    command = <<EOT
sudo podman pull quay.io/coreos/etcd > /dev/null 2>&1
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name}
EOT  
}
  provisioner "remote-exec" {
   inline = [
       "consul acl token create -policy-name ${self.name} -secret ${random_uuid.consul_default_token[count.index].result} -description '${self.name}'",
     ]

 connection {
   type = "ssh"
   user = "mkaesz"
   host = "dc1-bastion.msk.local"
   private_key = file("~/.ssh/id_rsa")
 }
}
  depends_on = [
    consul_acl_policy.nomad_server_policy,
  ]
}
