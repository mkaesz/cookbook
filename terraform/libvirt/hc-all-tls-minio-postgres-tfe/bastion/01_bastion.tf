resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image
}

resource "libvirt_pool" "bastion" {
  name = "bastion"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-bastion"
}

resource "libvirt_volume" "volume" {
  name           = "volume-bastion"
  base_volume_id = libvirt_volume.os_image.id
}

data "template_file" "minio_client_config" {
  template = file("${path.module}/templates/minio-client.json.tpl")
  vars = {
    minio_server        = var.minio_server
  }
}


data "template_file" "user_data" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname            = "${var.datacenter}-bastion.${var.domain}"
    domain              = var.domain
    consul_ca_file      = base64encode(var.consul_ca_cert_pem)
    minio_ca_file       = base64encode(var.minio_ca_cert_pem)
    vault_ca_file       = base64encode(var.vault_ca_cert_pem)
    nomad_ca_file       = base64encode(var.nomad_ca_cert_pem)
    consul_cert_file    = base64encode(var.consul_cli_cert_pem)
    minio_cert_file     = base64encode(var.minio_cli_cert_pem)
    vault_cert_file     = base64encode(var.vault_cli_cert_pem)
    nomad_cert_file     = base64encode(var.nomad_cli_cert_pem)
    consul_key_file     = base64encode(var.consul_cli_private_key_pem)
    minio_key_file      = base64encode(var.minio_cli_private_key_pem)
    vault_key_file      = base64encode(var.vault_cli_private_key_pem)
    nomad_key_file      = base64encode(var.nomad_cli_private_key_pem)
    consul_master_token = var.consul_master_token
    minio_client_config = data.template_file.minio_client_config.rendered
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit-bastion.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.bastion.name
}

resource "libvirt_domain" "bastion" {
  name      = "${var.datacenter}-bastion"
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  qemu_agent = true

  disk {
    volume_id = libvirt_volume.volume.id
  }

  network_interface {
    network_name   = "br0"
    wait_for_lease = true 
  }
  
  xml {
    xslt = file("qemuagent.xsl")
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

}
