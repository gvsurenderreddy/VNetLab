StormData = require('stormdata')
StormRegistry = require('stormregistry')
vm = require('./lxcdriver')
util = require('util')

#===============================================================================================#

class VmRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            #console.log "restoring #{key} with:" + val
            entry = new VmData key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            entry.destructor() if entry.destructor?

        super filename

    add: (data) ->
        return unless data instanceof VmData
        entry = super data.id, data

    update: (data) ->        
        super data.id, data    

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof VmData
            entry.data.id = entry.id
            entry.data
        else
            entry

#===============================================================================================#

class VmData extends StormData
    Schema =
        name: "vm"
        type: "object"
        required: true
        properties:
            name : {"type":"string", "required":true}        
            projectid   : {"type":"string", "required":false}
            type : {"type":"string", "required":false}
            memory : {"type":"string", "required":false}   
            vcpus : {"type":"string", "required":false}		
            ifmap:
                type: "array"
                required: false
                items:
                    type: "object"
                    name: "ifmapp"
                    required: false
                    properties:
                        ifname: {type:"string","required":true}
                        hwAddress: {type:"string","required":true}
                        brname: {type:"string","required":false}
                        ipaddress:{type:"string","required":true}
                        netmask:{type:"string","required":true}
                        gateway:{tye:"string","required":false}
                        type:{tye:"string","required":true}
        
    constructor: (id, data) ->
        super id, data, Schema

#===============================================================================================#
class VmBuilder
    @records = []
    constructor: () ->		
        @registry = new VmRegistry #"/tmp/vm.db"
    		
        @registry.on 'load',(key,val) ->
            #util.log "Loading key #{key} with val #{val}"	

    list : (callback) ->
        callback @registry.list()

    get: (data, callback) ->
        
        callback @registry.get data

    create:(data,callback) ->
        try         
            vmdata = new VmData(null, data )
        catch err
            util.log "invalid schema" + err
            return callback new Error "Invalid Input "
        finally 
            vmdata.data.status = "creation-in-progress"
            @registry.add vmdata
            callback 
                "id": vmdata.id
                "status":vmdata.data.status          
            #Delete the VM if already in the same name exists
            console.log "stopcontainer", vmdata.data.name
            vm.stopContainer vmdata.data.name, (result) =>
                #Need to check the result?
                vm.destroyContainer vmdata.data.name, (result) =>
                    #Need to check the result

                    vm.createContainer vmdata.data.name, "device", (result) =>
                        util.log "createvm " + result
                        if result is false
                            vmdata.data.status = "failure"
                            vmdata.data.reason = "VM already exists"
                            @registry.update vmdata.id, vmdata.data
                            return                     
                        if vmdata.data.ifmap?
                            for x in vmdata.data.ifmap                      
                                if x.type is "mgmt"
                                    result2 = vm.assignIP(vmdata.data.name,x.ifname,x.ipaddress,x.netmask,null)
                                    console.log "assignIP " + result2
                                    if result2 is false
                                        vmdata.data.status = "failure"
                                        vmdata.data.reason = "Fail to assign mgmt ip"
                                        @registry.update vmdata.id, vmdata.data
                                        return 
                                else # for wan, lan interfaces
                                    #result1 = vm.addEthernetInterface(vmdata.data.name,x.brname,x.hwAddress)              
                                    result1 = vm.addEthernetInterface(vmdata.data.name,x.veth,x.hwAddress)
                                    console.log "addEthernetInterface " + result1               
                                    if result is false
                                        vmdata.data.status = "failure"
                                        vmdata.data.reason = "Fail to add Interface"
                                        @registry.update vmdata.id, vmdata.data
                                        return 
                                    result2 = vm.assignIP(vmdata.data.name,x.ifname,x.ipaddress,x.netmask,x.gateway)
                                    console.log "assignIP " + result2
                                    if result is false
                                        vmdata.data.status = "failure"
                                        vmdata.data.reason = "Fail to add Interface"
                                        @registry.update vmdata.id, vmdata.data
                                        return 
                        #write in to db
                        vmdata.data.id = vmdata.id
                        vmdata.data.status = "created"                                
                        @registry.update vmdata.id, vmdata.data
                        return 

    status:(data,callback) ->
        vmdata = @registry.get data
        return callback new Error "VM details not found in DB" unless vmdata?
        vm.getStatus vmdata.data.name, (res) =>
            util.log "statusvm" + res           
            vmdata.data.status = res  
            @registry.update vmdata.id, vmdata.data
            return callback 
                "id": vmdata.id
                "status":vmdata.data.status           

    start:(data,callback) ->        
        vmdata = @registry.get data
        return callback new Error "VM details not found in DB" unless vmdata?
        vm.startContainer vmdata.data.name, (res) =>
            util.log "startvm" + res
            if res is true
                vmdata.data.status = "started"   
                @registry.update vmdata.id, vmdata.data
                return callback 
                    "id": vmdata.id
                    "status":vmdata.data.status
            else
                vmdata.data.status = "failed"
                vmddata.data.reason = "failed to start"   
                @registry.update vmdata.id, vmdata.data
                return callback 
                        "id": vmdata.id
                        "status":vmdata.data.status
                        "reason": vmdata.data.reason

    stop:(data,callback) ->
        vmdata = @registry.get data
        return callback new Error "VM details not found in DB" unless vmdata?
        vm.stopContainer vmdata.data.name, (result) =>
            util.log "stopvm" + result
            if result is true
                vmdata.data.status = "stopped"   
                @registry.update vmdata.id, vmdata.data
                return callback  
                    "id":vmdata.id
                    "status":vmdata.data.status
            else
                vmdata.data.status = "failed"
                vmdata.data.reason = "failed to stop"   
                @registry.update vmdata.id, vmdata.data
                return callback 
                    "id":vmdata.id
                    "status":vmdata.data.status
                    "reason" : vmdata.data.reason

    del:(data,callback)->
        vmdata = @registry.get data
        return callback new Error "VM details not found in DB" unless vmdata?
        @stop data, (res) =>
            vm.destroyContainer vmdata.data.name, (result) =>
                util.log "deleteVM " + result
                if result is true
                    vmdata.data.status = "deleted"   
                    @registry.remove vmdata.id
                    return callback 
                        "id":vmdata.id
                        "status":vmdata.data.status
                else
                    vmdata.data.status = "failed"
                    vmddata.data.reason = "failed to stop"   
                    @registry.update vmdata.id, vmdata.data
                    return callback 
                        "id":vmdata.id
                        "status":VmDataa.data.status
                        "reason":vmdata.data.reason

    packettrace:(data, callback)->
        vmdata = @registry.get data
        return callback new Error "VM details not found in DB" unless vmdata?
        #check whether trace is already enabled
        if vmdata.data.traceEnabled is true
            return callback     
                "id":vmdata.id
                "status":"Packet Trace already enabled"  

        vmdata.data.traceEnabled = true
        @registry.update vmdata.id, vmdata.data

        if vmdata.data.ifmap?
            for x in vmdata.data.ifmap  
                unless x.type is "mgmt"
                    command = "tcpdump -vv -S -i #{x.veth} > /var/log/#{x.veth}.txt &"
                    util.log "executing #{command}..."    
                    exec = require('child_process').exec    
                    exec command, (error, stdout, stderr) =>
                        util.log "lxcdriver: execute - Error : " + error
                        util.log "lxcdriver: execute - stdout : " + stdout
                        util.log "lxcdriver: execute - stderr : " + stderr    

            return callback        
                "id":vmdata.id
                "status":"Packet Trace enabled"                

module.exports = new VmBuilder
