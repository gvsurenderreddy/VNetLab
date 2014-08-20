VNET Labs
==

Virtual Network Lab is built on NFV Technology. 


*Introduction*
--
VnetLab is Inspired from the Open source Network Emulator tools such as ,
  1. Core Network Emulator.
    http://www.nrl.navy.mil/itd/ncs/products/core
  2. Mininet
    http://mininet.org/


*Virtual Network Lab*  provides the full fledged virtual network infrastructure services [includes router, switch, VPN( ipsec vpn, SSL VPN), WAN Links, LAN Links, Host Machines(Traffic capability)] using Network Function Virtualization (NFV) technology.  Also  It simulates the link characterisitcs such as delay, jitter etc.

*Features:
----
Network Elements supported:
   a. Router
        - Routing Protocol (RIP, OSPF, BGP)
        - VPN (IPSEC VPN, SSL VPN)
        - NAT Support
   b. L2 Switch  
   c. Host Machine 
      - UDP/TCP Traffic Generating capability
   e. WAN/LAN Links (configurable bandwidth, latency,jitter, packet loss)

Functions supported:
   a. Topology creation and deletion   
   b. Topology status 
   c. Individual device control (start, stop, status)
   d. Configuration:
     * Auto IP Assignement      
     * device configuration : Auto , Manual     
   e. Device Statistics    
      * interface statistics
      * Route table
   f. Individual device control via SSH   
   g. Packet capturing supported on each interface

Design Features:
 * Horizontally Scalable. 
 * Shared or dedicated  Hardware Infrastructure is supported.
 * Cloud Enabled.
     
Limitation:
 - REST API is available for user access, UI to be developed.


*Technical Details
---
1. OS : Linux
2. Virtualization:  LXC
3. Router Software : Quagga
4. VPN Software : Openvpn, strongswan
5. Linux iproute2 package.
6. Switch :  Linux Bridge, OVS
7. Stormflash Node packages


*RoadMap:
---
    a. SDN Capability  ( SDN Controllers - Floodlight, OpenDayLight  &  Openflow switches)
    
    b. Firewall 
    
   c. VLAN
   
   d. WAN Protocols 
   
   e. MPLS
   
   f. IPS/IDS
   
   g. KVM Virtualization
   
   h. Opensource Routers distribution support - PFSense , IPCop, openWRT, etc.
   
   i. Various Servers  (web, ftp, dns, dhcp etc) support.
   
   UI support.

