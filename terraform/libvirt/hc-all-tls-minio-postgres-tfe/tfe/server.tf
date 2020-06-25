resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = var.os_image
}

resource "libvirt_pool" "tfe" {
  name = "tfe"
  type = "dir"
  path = "/tmp/terraform-provider-libvirt-pool-tfe"
}

resource "libvirt_volume" "volume" {
  name           = "volume-tfe"
  base_volume_id = libvirt_volume.os_image.id
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/cloud_init.cfg.tpl")}"
  vars = {
    hostname            = "${var.datacenter}-tfe.${var.domain}"
    domain              = var.domain
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/templates/network_config.cfg.tpl")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit-tfe.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.tfe.name
}

resource "libvirt_domain" "tfe" {
  name      = "${var.datacenter}-tfe"
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  disk {
    volume_id = libvirt_volume.volume.id
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

}
