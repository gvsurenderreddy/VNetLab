brctl = require('./brctldriver')
ovs= require('./ovsdriver')
util = require('util')
StormData = require('stormdata')
StormRegistry = require('stormregistry')
#===============================================================================================#

class SwitchRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            #console.log "restoring #{key} with:" + val
            entry = new SwitchData key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            entry.destructor() if entry.destructor?

        super filename

    add: (data) ->
        return unless data instanceof SwitchData
        entry = super data.id, data

    update: (data) ->        
        super data.id, data    

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof SwitchData
            entry.data.id = entry.id
            entry.StormData
        else
            entry

#===============================================================================================#

class SwitchData extends StormData
    Schema =
        name: "switch"
        type: "object"        
        properties:                        
            name: {type:"string", required:true}                       
            type:{ type: "string", required: true}
            make: { type: "string", required: false}           	
            controller: { type: "string", required: false}
            
    constructor: (id, data) ->
        super id, data, Schema
#===============================================================================================#

class SwitchBuilder
	@records = []
	bridge = null
	constructor: () ->		
		@registry = new SwitchRegistry #"/tmp/switches.db"
		
		@registry.on 'load',(key,val) ->
			#util.log "Loading key #{key} with val #{val}"	

	list : (callback) ->
        return callback @registry.list()

    get: (data, callback) ->
    	callback @registry.get data
		#callback @registry.get data

	create:(data,callback) ->
		try			
			sdata = new SwitchData(null, data )
		catch err
			util.log "invalid schema" + err
			return callback new Error "invalid schema"
		finally			

			if data.make is "openvswitch"
				bridge  = ovs
			else
				bridge  = brctl

			# if switch make is "bridge"
			bridge.createBridge data.name, (result) =>
				util.log "Bridge creation " + result				
				
				if result is false
					sdata.data.status = "failed"
					sdata.data.reason = "failed to create"
				else
					sdata.data.status = "created"
					@registry.add sdata
					return callback
									"id" : sdata.id
									"status" : sdata.data.status
									"reason" : sdata.data.reason if sdata?.data?.reason?
									
				
		# if switch make is "ovs"
	addInterface : (data, body, callback) ->
		util.log "addInterface body is "+ JSON.stringify body
		sdata = @registry.get data
		return callback new Error "Switch details not found in DB" unless sdata?
		if sdata.data.make is "openvswitch"
			bridge  = ovs
		else
			bridge  = brctl

		bridge.addInterface sdata.data.name, body.ifname, (result) =>
			util.log "addif" + result			
			if result is false	
				sdata.data.status = "failed"
				sdata.data.reason = "failed to add interface"
			else
				sdata.data.status = "interface added"
			@registry.update sdata.id , sdata
			return callback 
				"id" : sdata.id
				"status" : sdata.data.status					
				"reason" : sdata.data.reason if sdata.data?.reason?


	CreateTapInterfaces : (ifname1,ifname2) ->		
		bridge = brctl
		bridge.createTapPeers ifname1, ifname2, (result) =>
			util.log "createTapPeers " + result			
			return result 

	start : (data, callback) ->
		sdata = @registry.get data
		return callback new Error "Switch details not found in DB" unless sdata?
		if sdata.data.make is "openvswitch"
			bridge  = ovs
			if sdata.data.controller?
				bridge.setController sdata.data.name, sdata.data.controller, (result) =>
					util.log.log result
		else
			bridge  = brctl



		bridge.enableBridge sdata.data.name, (result) =>
			util.log "enableBridge" + result			
			if result is false	
				sdata.data.status = "failed"
				sdata.data.reason = "failed to start"
			else
				sdata.data.status = "started"				
			@registry.update sdata.id , sdata
			return callback 
				"id" : sdata.id
				"status" : sdata.data.status					
				"reason" : sdata.data.reason if sdata.data?.reason?

	stop : (data, callback) ->
		sdata = @registry.get data
		return callback new Error "Switch details not found in DB" unless sdata?

		if sdata.data.make is "openvswitch"
			bridge  = ovs
		else
			bridge  = brctl

		bridge.disableBridge sdata.data.name, (result) =>
			util.log "disableBridge" + result			
			if result is false	
				sdata.data.status = "failed"
				sdata.data.reason = "failed to stop"
			else
				sdata.data.status = "stopped"
			@registry.update sdata.id , sdata
			return callback 
				"id" : sdata.id
				"status" : sdata.data.status					
				"reason" : sdata.data.reason if sdata.data?.reason?

	del: (data,callback) -> 	 
		#Get the Switchname from db
		sdata = @registry.get data
		if sdata.data.make is "openvswitch"
			bridge  = ovs
		else
			bridge  = brctl
		return callback new Error "Switch details not found in DB" unless sdata?
		bridge.deleteBridge sdata.data.name, (result) =>
			util.log "deletBridge" + result
			return callback new Error "Failed to Delete the Switch" if result is false
			#delete the switch from db
			@registry.remove sdata.id
			return callback 
				"id":sdata.id
				"status": "deleted"

	status: (data, callback) ->
		#Todo
		sdata = @registry.get data
		return callback new Error "Switch details not found in DB" unless sdata?
		if sdata.data.make is "openvswitch"
			bridge  = ovs
		else
			bridge  = brctl
		bridge.getStatus sdata.data.name, (result) =>
			util.log "getStatus" + result
			sdata.data.status = result
			@registry.update sdata
			return callback sdata
			#delete the switch from db


module.exports = new SwitchBuilder
