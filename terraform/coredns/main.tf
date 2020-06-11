provider "coredns" {
    etcd_endpoints = "http://arch:2379"
    zones = "msk.local"
}

resource "coredns_record" "foo" {
    fqdn = "foo.msk.local"
    type = "A"
    rdata = [ "10.10.10.10", "10.10.10.20" ]
    ttl = "60"
}

