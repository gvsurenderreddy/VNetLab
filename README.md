VNET Labs
==

*Introduction*
--

*Virtual Network Lab*  provides the full fledged virtual network infrastructure services includes, router, switch, firewall, ipsec vpn, SSL VPN, WAN Links, WAN Protocol, LAN Links, Servers include (Web, ftp, ...), Work stations, etc. 
Also  It simulates the link characterisitcs such as delay jitter.  

Also it provides SDN Infrastructure too, such as SDN Controller, SDN Switches and links..

Supported protocol, feature capabilities listed in the Annexure 1.


How it works
--
1. Installs the VNetLabs Application in Ubuntu .
2. Start the application
3. Open the Web GUI Page.
4. In the Left side panel, consists of the devices supported (such as Router, Switch, Desktop, SDN Controller, SDN Switch), Links suppported (E1,  E2, E3, Ethernet etc).
5. Create a topology (Drag and Drop the devices, connect the devices with links.)
6. Configure each device services (optional), such as routing protocol, firewall, switch ports, etc.
6. Start the topology.
7. Topology is getting created and device status will be updated in the screen (Such as device is created, configured, started) with different colors.
8. Once all the devices are up and running, 
9. individual device statistics (such as interface packat statistics, routing tables, firewall statistics, services running etc) can be seen.
10. Individual device and device services can be controlled, such as configure, start ,stop.


Features:

1. Virtualization: 	LXC, KVM 

2. Supported Devices:  Linux Router, Switch, Host , SDN Controller, LinuxFirewall, VPN, OpenSource Routers/firewalls (PFSense, IPCop,OpenWRT, etc )
  
   a. Switch  -  linux bridge, OVSwitch
            
   b. Router  -  Quagga (ripv2, ospfv2, Bgp)
              
   c. Host  - Traffic Generator (MGEN, IPERF, ...)

   d. SDN Controller (Floodlight, OpenDayLight)
   
   e. Firewall - Linux IPTables
   
   f. SSL VPN - openvpn
   
   g. IPSEC VPN - strongswan

   h. PFSense , IPCop, openWRT, etc.

3. Links:

   a. Virtual Ethernet 
   
   b. Netem, TC -  Bandwidth, delay, jitter configuration
   
   c. Wan protocol (PPPoE, PPP)

4. Functions:

   a. Topology creation
   
   b. Topology status
   
   c. Individual device control (start, stop, status)
   
   d. Configuration:
   
     * IPv4
     * IP Addressing :  Auto , Manual
     * device configuration : Auto  , Manual
     
   e. Device Statistics collection
   
      * interface statistics
      * Route table

   f.  Individual device control via SSH, Web.
      
