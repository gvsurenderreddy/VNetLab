util = require 'util'
exec = require('child_process').exec
fs = require('fs')

class LXCControl
	execute : (command, callback) ->
        callback false unless command?
        util.log "executing #{command}..."        
        exec command, (error, stdout, stderr) =>
        	util.log "lxcdriver: execute - Error : " + error
        	util.log "lxcdriver: execute - stdout : " + stdout
        	util.log "lxcdriver: execute - stderr : " + stderr
        	if error
                callback false
            else
                callback true
                
	createContainer : (containerName, ref, callback) ->
		#Todo : check the ref container is availble
		command = "lxc-clone -o #{ref} -n #{containerName}"
		util.log "createContainer command : " + command
		@execute command,(result) =>			
		 	callback result

	startContainer : (contaninerName, callback) ->
		command = "lxc-start --name #{contaninerName} -d "
		util.log "startContainer command : " + command
		@execute command,(result) =>
		 	callback result


	stopContainer : (containerName, callback) ->
		command = "lxc-stop --name #{containerName} "
		util.log "stopContainer command : " + command
		@execute command,(result) =>
		 	callback result

	destroyContainer : (containerName, callback) ->
		command = "lxc-destroy --name #{containerName} "
		util.log "destroyContainer command : " + command
		@execute command,(result) =>
		 	callback result
	#addEthernetInterface: (containerName, bridgename, hwAddress) ->
	addEthernetInterface: (containerName, vethname, hwAddress) ->
		#update the config file
		#util.log " addEthernetInterface #{containerName}  bridgename #{bridgename}  hwAddress #{hwAddress} "
		util.log " addEthernetInterface #{containerName}  vethname #{vethname}  hwAddress #{hwAddress} "
		filename = "/var/lib/lxc/#{containerName}/config"
		util.log " filname " + filename
		#text = "\nlxc.network.type = veth \nlxc.network.hwaddr= #{hwAddress} \nlxc.network.link = #{bridgename} \nlxc.network.flags = up"
		text = "\nlxc.network.type = veth \nlxc.network.hwaddr= #{hwAddress} \nlxc.network.veth.pair = #{vethname} \nlxc.network.flags = up"
		fs.appendFileSync(filename,text)
		return true

	assignIP: (containerName, ifname, ipaddress, netmask, gateway) ->
		filename= "/var/lib/lxc/#{containerName}/rootfs/etc/network/interfaces"			
		#filename = "/var/lib/lxc/#{containerName}/rootfs/etc/init.d/rcS"
		text = "\nauto #{ifname}\niface #{ifname} inet static \n\t address #{ipaddress} \n\t netmask #{netmask} \n\t gateway #{gateway}\n" if gateway?
		text = "\nauto #{ifname}\niface #{ifname} inet static \n\t address #{ipaddress} \n\t netmask #{netmask} \n" unless gateway?
		#text = "\n /bin/ifconfig #{ifname} #{ipaddress} #{netmask}\n" 
		#text1 = "\n route add default gw #{gateway}\n" if gateway?
		fs.appendFileSync(filename,text)
		#fs.appendFileSync(filename,text1) if text1?
		return true

	getStatus: (containerName , callback) ->
		command = "lxc-ls --running #{containerName} "
		util.log "executing #{command}..."        
		exec command, (error, stdout, stderr) =>
			util.log "lxcdriver: execute - Error : " + error
			util.log "lxcdriver: execute - stdout : " + stdout
			util.log "lxcdriver: execute - stderr : " + stderr
			if error or not stdout?
				callback "notrunning"
			else
				callback "running"			

module.exports = new LXCControl
