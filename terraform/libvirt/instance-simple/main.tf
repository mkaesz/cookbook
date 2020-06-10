provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "os_image" {
  name   = "os_image"
  source = "https://download.fedoraproject.org/pub/fedora/linux/releases/32/Cloud/x86_64/images/Fedora-Cloud-Base-32-1.6.x86_64.qcow2"
}

resource "libvirt_volume" "volume" {
  name           = "volume"
  base_volume_id = libvirt_volume.os_image.id
}

resource "libvirt_domain" "domain" {
  name = "domain"
  disk {
    volume_id = libvirt_volume.volume.id
  }

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
}

output "ips" {
  value = libvirt_domain.domain.network_interface.0.addresses
}
