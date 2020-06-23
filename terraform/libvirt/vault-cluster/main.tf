provider "libvirt" {
  uri   = "qemu+ssh://root@192.168.0.171/system"
}

resource "libvirt_pool" "vault" {
  name = "vault"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-vault"
}
resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = "http://192.168.0.171:8088/workspace/images/fedora32-kvm-hc-products-cloudinit.qcow2"
}

resource "libvirt_volume" "volume" {
  name           = "volume-vault-${count.index}"
  base_volume_id = libvirt_volume.os_image.id
  count	         = var.vault_cluster_size
}

data "template_file" "vault_server_config" {
  template = "${file("${path.module}/templates/vault-server.hcl.tpl")}"
  vars = {
    node_name = "vault-node-${count.index}"
  }
  count = var.vault_cluster_size
}

data "template_file" "consul_client_config" {
  template = "${file("${path.module}/templates/consul-client.json.tpl")}"
vars = {
  node_name = "vault-node-${count.index}"
}
  count = var.vault_cluster_size
}
data "template_file" "user_data" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname = "vault-node-${count.index}"
    vault_server_config = base64encode(data.template_file.vault_server_config[count.index].rendered)
    consul_client_config = base64encode(data.template_file.consul_client_config[count.index].rendered)
  }
  count	= var.vault_cluster_size
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit-${count.index}.iso"
  user_data      = data.template_file.user_data[count.index].rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.vault.name
  count          = var.vault_cluster_size
}

resource "libvirt_domain" "vault-node" {
  name = "vault-node-${count.index}"
  count = var.vault_cluster_size

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  disk {
    volume_id = element(libvirt_volume.volume.*.id, count.index)
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true 
  }

  provisioner "local-exec" {
    when = create
    command = <<EOT
sudo podman pull quay.io/coreos/etcd
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl put /skydns/local/msk/${self.name} '{"host":"${self.network_interface.0.addresses.0}","ttl":60}'
EOT  
}

   provisioner "local-exec" {
    when = destroy 
    command = <<EOT
sudo podman pull quay.io/coreos/etcd
sudo podman exec -ti --env=ETCDCTL_API=3 etcd /usr/local/bin/etcdctl del /skydns/local/msk/${self.name}
EOT  
}

}

output "nodes" {
  value = libvirt_domain.vault-node.*.name
}

output "ips" {
  value = libvirt_domain.vault-node.*.network_interface.0.addresses
}
