#!/bin/bash
set -e

#### Variables for Ubuntu1 side ####
NS1="NS1"
NS2="NS2"
NODE_IP="192.168.0.10"
BRIDGE_SUBNET="172.16.0.0/24"
BRIDGE_IP="172.16.0.1"
IP1="172.16.0.2"
IP2="172.16.0.3"
# Point at ubuntu2’s Docker IP on the same Docker bridge
TO_NODE_IP="192.168.0.11"
TO_BRIDGE_SUBNET="172.16.1.0/24"

#### 1) Create network namespaces on ubuntu1 ####
ip netns add $NS1
ip netns add $NS2

#### 2) Create veth pairs: one end in default NS, the peer in each namespace ####
ip link add veth10 type veth peer name veth11
ip link add veth20 type veth peer name veth21

#### 3) Move the “.11” and “.21” ends into their namespaces ####
ip link set veth11 netns $NS1
ip link set veth21 netns $NS2

#### 4) Assign IPs inside each namespace and bring them up ####
ip netns exec $NS1 ip addr add $IP1/24 dev veth11
ip netns exec $NS2 ip addr add $IP2/24 dev veth21

ip netns exec $NS1 ip link set dev veth11 up
ip netns exec $NS2 ip link set dev veth21 up

#### 5) Create a bridge br0 in the default NS of ubuntu1 ####
ip link add br0 type bridge

#### 6) Attach the “.10” and “.20” ends to br0 ####
ip link set dev veth10 master br0
ip link set dev veth20 master br0

#### 7) Assign the bridge IP and bring everything up ####
ip addr add $BRIDGE_IP/24 dev br0
ip link set dev br0 up
ip link set dev veth10 up
ip link set dev veth20 up

#### 8) Bring up loopback inside each namespace ####
ip netns exec $NS1 ip link set lo up
ip netns exec $NS2 ip link set lo up

#### 9) Add default‑routes inside each namespace via br0 ####
ip netns exec $NS1 ip route add default via $BRIDGE_IP dev veth11
ip netns exec $NS2 ip route add default via $BRIDGE_IP dev veth21

#### 10) Enable IPv4 forwarding and allow forwarding in iptables ####
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT

#### 11) Add a host‑level route on ubuntu1 → to reach 172.16.1.0/24 via ubuntu2 ####
ip route add $TO_BRIDGE_SUBNET via $TO_NODE_IP dev eth0

echo "== ubuntu1 setup complete =="
echo "Namespaces: $(ip netns list)"
echo "Bridge br0: $(ip addr show br0 | grep inet)"
echo "Ubuntu1 host routes: $(ip route show | grep 172.16.1.0/24)"
