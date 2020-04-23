## Create 2 Virtual networks
```
kubectl create -f left-net.yml
kubectl create -f right-net.yml
```

## Verify using kubectl
```
kubectl get network-attachment-definition
kubectl describe network-attachment-definition

kubectl create -f left-ubuntu-pod.yml
kubectl create -f right-ubuntu-pod.yml
```

## All in one
```sh
kubectl create -f left.yml
kubectl create -f right.yml
kubectl create -f csrx-pod.yml 
#If error in Image pull, manually go to the slave and docker pull the image

kubectl exec -it left-ubuntu-pod bash
ip a
# It's 1 network ip: 1.0.0.252
# It's 10 network ip: 10.47.255.249

kubectl exec -it right-ubuntu-pod bash
ip a
# It's 2 network ip: 2.0.0.252
# It's 10 network ip: 10.47.255.248

kubectl exec -it csrx-pod bash
ip a
# It's 10 network ip: 
# We see that eth1 and eth2 are not having ip

Note: 
* Unlike other PODs the CSRX didn’t acquire IP with DHCP and it start with factory default configuration hence it need to be configured

* By default, CSRX eth0 is visible only from shell and used for management. And when attaching networks, the first attach network is mapped to eth1 which is GE-0/0/1 And the second attach is mapped to eth2 which is GE-0/0/0

### Configure CSRX ip

kubectl exec -it csrx-pod cli
show interfaces
edit
# Need to configure the below interfaces
1.0.0.251
2.0.0.251

set interfaces ge-0/0/1 unit 0 family inet address 1.0.0.251/24
set interfaces ge-0/0/0 unit 0 family inet address 2.0.0.251/24
set security zones security-zone trust interfaces ge-0/0/0
set security zones security-zone untrust interfaces ge-0/0/1
set security policies default-policy permit-all
commit

### Interface details
root@csrx-pod# run show interfaces 
Physical interface: ge-0/0/1, Enabled, Physical link is Up
Interface index: 100
Link-level type: Ethernet, MTU: 1514
Current address: 02:12:d8:21:36:85, Hardware address: 02:12:d8:21:36:85

Logical interface ge-0/0/1.0 (Index 100)
Flags: Encapsulation: ENET2
Protocol inet
Destination: 1.0.0.0/24, Local: 1.0.0.251

Physical interface: ge-0/0/0, Enabled, Physical link is Up
Interface index: 200
Link-level type: Ethernet, MTU: 1514
Current address: 02:12:fd:dd:e0:85, Hardware address: 02:12:fd:dd:e0:85

Logical interface ge-0/0/0.0 (Index 200)
Flags: Encapsulation: ENET2
Protocol inet
Destination: 2.0.0.0/24, Local: 2.0.0.251
###

### Ping test
kubectl exec -it left-ubuntu-pod -- ping 2.0.0.252
# Ping fails
ip r
# A ping test on the left pod would fail as there is no route
# Add a static route to the left and right pods and then try to ping again
# In left-pod
ip r add 2.0.0.0/24 via 1.0.0.251
# In right-pod
ip r add 1.0.0.0/24 via 2.0.0.251

The ping still failed, as we didn’t create the service chaining, which will also take care of the routing
```

## Cause explained
```sh
kubectl exec -it csrx-pod cli
edit
root@csrx-pod# run show security flow session 
Total sessions: 0

There’s no session on the cSRX. To troubleshoot the ping issue, log in to the com- pute node cent22 that hosts this container to dump the traffic using TShark and check the routing. 
```
### On compute c21
To get the interface linking the containers
```sh
vif -l
<snipped>
#Left
vif0/5      OS: tapeth0-bc1c69 NH: 52
            Type:Virtual HWaddr:00:00:5e:00:01:00 IPaddr:10.47.255.249
            Vrf:2 Mcast Vrf:2 Flags:PL3DEr QOS:-1 Ref:6
            RX packets:1094  bytes:46172 errors:0
            TX packets:1733  bytes:72786 errors:0
            Drops:1097

vif0/10     OS: tapeth1-129a93 NH: 63
            Type:Virtual HWaddr:00:00:5e:00:01:00 IPaddr:1.0.0.251
            Vrf:4 Mcast Vrf:4 Flags:PL3L2DEr QOS:-1 Ref:6
            RX packets:652  bytes:27384 errors:0
            TX packets:1449  bytes:60858 errors:0
            Drops:654

#Right
vif0/7      OS: tapeth0-c08755 NH: 67
            Type:Virtual HWaddr:00:00:5e:00:01:00 IPaddr:10.47.255.248
            Vrf:2 Mcast Vrf:2 Flags:PL3DEr QOS:-1 Ref:6
            RX packets:1091  bytes:45934 errors:0
            TX packets:1733  bytes:72786 errors:0
            Drops:1092

vif0/11     OS: tapeth2-129a93 NH: 62
            Type:Virtual HWaddr:00:00:5e:00:01:00 IPaddr:2.0.0.251
            Vrf:5 Mcast Vrf:5 Flags:PL3L2DEr QOS:-1 Ref:6
            RX packets:659  bytes:27958 errors:0
            TX packets:1456  bytes:61432 errors:0

#CSRX
vif0/9      OS: tapeth0-129a93 NH: 78
            Type:Virtual HWaddr:00:00:5e:00:01:00 IPaddr:10.47.255.247
            Vrf:2 Mcast Vrf:2 Flags:PL3DEr QOS:-1 Ref:6
            RX packets:1376  bytes:70120 errors:0
            TX packets:1503  bytes:63126 errors:0
            Drops:1254

vif0/10     OS: tapeth1-129a93 NH: 63
            Type:Virtual HWaddr:00:00:5e:00:01:00 IPaddr:1.0.0.251
            Vrf:4 Mcast Vrf:4 Flags:PL3L2DEr QOS:-1 Ref:6
            RX packets:652  bytes:27384 errors:0
            TX packets:1449  bytes:60858 errors:0
            Drops:654

vif0/11     OS: tapeth2-129a93 NH: 62
            Type:Virtual HWaddr:00:00:5e:00:01:00 IPaddr:2.0.0.251
            Vrf:5 Mcast Vrf:5 Flags:PL3L2DEr QOS:-1 Ref:6
            RX packets:659  bytes:27958 errors:0
            TX packets:1456  bytes:61432 errors:0

```