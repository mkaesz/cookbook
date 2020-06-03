#!/bin/sh
echo "Starting HashiCorp Consul in Server Mode..."
sleep 1
echo "CMD: nohup consul agent -config-dir=/consul/config > /consul.out &"
nohup consul agent -config-dir=/consul/config > /consul.out &
echo "Log output will appear in consul.out..."
sleep 1
echo "Consul server startup complete."
