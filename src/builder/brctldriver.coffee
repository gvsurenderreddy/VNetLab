util = require 'util'
exec = require('child_process').exec

class BridgeControl

	execute : (command, callback) ->
        callback false unless command?
        util.log "executing #{command}..."        
        exec command, (error, stdout, stderr) =>
        	util.log "brctldriver: execute - Error : " + error
        	util.log "brctldriver: execute - stdout : " + stdout
        	util.log "brctldriver: execute - stderr : " + stderr
        	if error
                callback false
            else
                callback true    

	createBridge : (bridgname, callback) ->
		command = "brctl addbr #{bridgname}"
		@execute command,(result) =>
			callback result

	addInterface : (bridgname,ifname,callback) ->
		command = "brctl addif #{bridgname} #{ifname}"
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

	deleteBridge : (bridgename, callback) ->
		@disableBridge bridgename, (result)=>
			command = "brctl delbr #{bridgename}"
			@execute command,(result) =>
				callback result

	getStatus: (bridgename, callback) ->
		command = "brctl show #{bridgename}"
		exec command, (error, stdout, stderr) =>
        	util.log "brctldriver: execute - Error : " + error
        	util.log "brctldriver: execute - stdout : " + stdout
        	util.log "brctldriver: execute - stderr : " + stderr
        	if stdout? or error            
                callback "notrunning"
            else
                callback "running" 		

module.exports = new BridgeControl