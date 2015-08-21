util = require 'util'
exec = require('child_process').exec

class BridgeControl

	execute : (command, callback) ->
        callback false unless command?
        util.log "executing #{command}..."        
        exec command, (error, stdout, stderr) =>
        	util.log "ovsdriver: execute - Error : " + error
        	util.log "ovsdriver: execute - stdout : " + stdout
        	util.log "ovsdriver: execute - stderr : " + stderr
        	if error
                callback false
            else
                callback true    

	createBridge : (bridgname, callback) ->
		command = "ovs-vsctl add-br #{bridgname}"
		@execute command,(result) =>
			callback result

	addInterface : (bridgname,ifname,callback) ->
		command = "ovs-vsctl add-port #{bridgname} #{ifname}"
		@execute command,(result) =>
			callback result

	enableBridge : (bridgname, callback) ->
		command = "ifconfig #{bridgname} up"
		@execute command,(result) =>
			callback result


	disableBridge : (bridgname , callback) ->
		command = "ifconfig #{bridgname} down"
		@execute command,(result) =>
			callback result
    
	setController : (bridgename , controllerip, callback)->
		command = "ovs-vsctl set-controller #{bridgename} #{controllerip}"
		@execute command,(result) =>
			callback result

	deleteBridge : (bridgename, callback) ->
		@disableBridge bridgename, (result)=>
			command = "ovs-vsctl del-br #{bridgename}"
			@execute command,(result) =>
				callback result

	getStatus: (bridgename, callback) ->
		command = "ovs-vsctl show #{bridgename}"
		exec command, (error, stdout, stderr) =>
        	util.log "ovsdriver: execute - Error : " + error
        	util.log "ovsdriver: execute - stdout : " + stdout
        	util.log "ovsdriver: execute - stderr : " + stderr
        	if stdout? or error            
                callback "notrunning"
            else
                callback "running" 		

module.exports = new BridgeControl