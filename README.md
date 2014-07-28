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


Development plan:  
--
###Release-0.1 : Supported features   
---

1. Virtualization: 	LXC

2. Supported Devices:  Linux Router, Switch , Host
  
   a. Switch  -  linux bridge
            
   b. Router  -  Quagga (ripv2, ospfv2)
              
   c. Host
   
   

3. Links:

   a. Virtual Ethernet 

4. Functions:

   a. Topology creation
   
   b. Topology status
   
   c. Individual device control (start, stop, status)
   
   d. Configuration:
   
     * IPv4
     * IP Addressing :  Auto
     * device configuration : Auto   
     
   e. Device Statistics collection
   
      * interface statistics
      * Route table
      
5. UI:  Basic UI 
####*Volunteer required for UI development *






###Release-0.2 : Supported features
---

1. Virtualization: 	LXC, KVM

2. Supported Devices:  Linux Router, Switch, Host , SDN Controller
  
   a. Switch  -  linux bridge
            
   b. Router  -  Quagga (ripv2, ospfv2)
              
   c. Host

   d. SDN Controller

3. Links:

   a. Virtual Ethernet 
   
   b. Bandwidth, delay, jitter configuration

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
      
5. UI:  Basic UI 





###Release-0.3 : Supported features
---

1. Virtualization: 	LXC, KVM 

2. Supported Devices:  Linux Router, Switch, Host , SDN Controller, Firewall, VPN
  
   a. Switch  -  linux bridge
            
   b. Router  -  Quagga (ripv2, ospfv2)
              
   c. Host

   d. SDN Controller
   
   e. Firewall - Linux IPTables
   
   f. SSL VPN - openvpn
   
   g. IPSEC VPN - strongswan

3. Links:

   a. Virtual Ethernet 
   
   b. Bandwidth, delay, jitter configuration
   
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
      
5. UI:  Enhanced UI 





Current Status :
--
Release 0.1 development is in progress.

Expected completion :  Aug 15-2014