#!/bin/bash
set -e

#### Variables for Ubuntu2 side ####
NS1="NS1"
NS2="NS2"
NODE_IP="192.168.0.11"
BRIDGE_SUBNET="172.16.1.0/24"
BRIDGE_IP="172.16.1.1"
IP1="172.16.1.2"
IP2="172.16.1.3"
# Point at ubuntu1’s Docker IP
TO_NODE_IP="192.168.0.10"
TO_BRIDGE_SUBNET="172.16.0.0/24"

#### 1) Create network namespaces on ubuntu2 ####
ip netns add $NS1
ip netns add $NS2

#### 2) Create veth pairs and move peers into namespaces ####
ip link add veth10 type veth peer name veth11
ip link add veth20 type veth peer name veth21

ip link set veth11 netns $NS1
ip link set veth21 netns $NS2

#### 3) Assign IPs inside each namespace and bring them up ####
ip netns exec $NS1 ip addr add $IP1/24 dev veth11
ip netns exec $NS2 ip addr add $IP2/24 dev veth21

ip netns exec $NS1 ip link set dev veth11 up
ip netns exec $NS2 ip link set dev veth21 up

#### 4) Create bridge br0 and attach the “.10”/.20” ends ####
ip link add br0 type bridge

ip link set dev veth10 master br0
ip link set dev veth20 master br0

#### 5) Assign bridge IP and bring up interfaces ####
ip addr add $BRIDGE_IP/24 dev br0
ip link set dev br0 up
ip link set dev veth10 up
ip link set dev veth20 up

#### 6) Bring up loopback inside each namespace ####
ip netns exec $NS1 ip link set lo up
ip netns exec $NS2 ip link set lo up

#### 7) Add default‑routes inside namespaces via 172.16.1.1 ####
ip netns exec $NS1 ip route add default via $BRIDGE_IP dev veth11
ip netns exec $NS2 ip route add default via $BRIDGE_IP dev veth21

#### 8) Enable forwarding and allow forwarding in iptables ####
sysctl -w net.ipv4.ip_forward=1
iptables -P FORWARD ACCEPT

#### 9) Add a host‑level route on ubuntu2 → to reach 172.16.0.0/24 via ubuntu1 ####
ip route add $TO_BRIDGE_SUBNET via $TO_NODE_IP dev eth0

echo "== ubuntu2 setup complete =="
echo "Namespaces: $(ip netns list)"
echo "Bridge br0: $(ip addr show br0 | grep inet)"
echo "Ubuntu2 host routes: $(ip route show | grep 172.16.0.0/24)"
