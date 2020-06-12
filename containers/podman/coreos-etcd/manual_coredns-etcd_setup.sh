ETCD_VERSION=3.3.11
COREDNS_VERSION=1.3.1
HostIP=$(ip route get 1.1.1.1 | awk 'NR==1 { print $7 }')

## Start the etcd backend
### NOTE: Added 0.0.0.0 to advertised client urls to allow direct container communication
podman pull quay.io/coreos/etcd:v${ETCD_VERSION}
podman stop etcd && podman rm etcd
podman run -d \
  -v /usr/share/ca-certificates/:/etc/ssl/certs \
  -p 4001:4001 -p 2380:2380 -p 2379:2379 \
  --name etcd \
  quay.io/coreos/etcd:v${ETCD_VERSION} etcd \
    -name etcd0 \
    -advertise-client-urls http://${HostIP}:2379,http://${HostIP}:4001,http://0.0.0.0:2379,http://0.0.0.0:4001 \
    -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
    -initial-advertise-peer-urls http://${HostIP}:2380  \
    -listen-peer-urls http://0.0.0.0:2380 \
    -initial-cluster-token etcd-cluster-1 \
    -initial-cluster etcd0=http://${HostIP}:2380 \
    -initial-cluster-state new

etcd_ip=$(podman inspect etcd | jq -r '.[].NetworkSettings.IPAddress')

## Start CoreDNS
### Drop Corefile
# sudo mkdir -p /etc/coredns
cat << 'EOF' > Corefile
. {
    etcd msk.local {
        stubzones
        path /skydns
        endpoint http://{$ETCD_IP}:4001
        upstream /etc/resolv.conf
    }
    cache 160 skydns.local
    proxy . /etc/resolv.conf
    log
}
EOF

### Pull and run container with above config
podman pull docker.io/coredns/coredns:${COREDNS_VERSION}
podman stop coredns && podman rm coredns
podman run -d \
  --name coredns \
  -v ${PWD}:/data:ro \
  --env ETCD_IP=${HostIP} \
  docker.io/coredns/coredns:${COREDNS_VERSION} -conf /data/Corefile

coredns_ip=$(podman inspect coredns | jq -r '.[].NetworkSettings.IPAddress')
## Create some test data
### Add Forward entries
podman exec -ti --env=ETCDCTL_API=3  etcd /usr/local/bin/etcdctl \
  put /skydns/local/msk/arch "{\"host\":\"${HostIP}\",\"ttl\":60}"

### Reverse entries
podman exec -ti --env=ETCDCTL_API=3  etcd /usr/local/bin/etcdctl \
  put /skydns/arpa/in-addr/$(echo $HostIP | tr '.' '/') '{"host": "arch.msk.local"}'

### Check resolution
dig +short arch.msk.local @$coredns_ip
dig +short -x ${HostIP} @$coredns_ip
