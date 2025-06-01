# inside ubuntu1

ip netns exec $NS1 ping -c2 172.16.0.2   # ubuntu1's own NS1

ip netns exec $NS1 ping -c2 172.16.0.1   # ubuntu1’s bridge

ip netns exec $NS1 ping -c2 172.16.0.3   # ubuntu1's own NS2

ip netns exec $NS1 ping -c2 192.168.0.11 # ubuntu2’s host IP

ip netns exec $NS1 ping -c2 172.16.1.1   # ubuntu2’s bridge

ip netns exec $NS1 ping -c2 172.16.1.2   # ubuntu2’s NS1

ip netns exec $NS1 ping -c2 172.16.1.3   # ubuntu2’s NS2
