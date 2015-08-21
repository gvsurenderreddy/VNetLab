StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
async = require 'async'
util = require 'util'


IPManager = require('./IPManager')
node = require('./Node')
switches = require('./Switches')


#Log handler
log = require('./utils/logger').getLogger()
log.info "Topology Logger test message"


## Global IP Manager for  -- To be relooked the design
#MGMT_SUBNET = "10.0.3.0"
#WAN_SUBNET = "172.16.1.0"
#LAN_SUBNET = "10.10.10.0"

#============================================================================================================
class TopologyRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            #log.debug "restoring #{key} with:",val
            entry = new TopologyData key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            entry.destructor() if entry.destructor?

        super filename

    add: (data) ->
        return unless data instanceof TopologyData
        entry = super data.id, data

    update: (data) ->        
        super data.id, data    

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof TopologyData
            entry.data.id = entry.id
            entry.data
        else
            entry

#============================================================================================================

class TopologyData extends StormData
    TopologySchema =
        name: "Topology"
        type: "object"        
        #additionalProperties: true
        properties:                        
            name: {type:"string", required:true}
            switches:
                type: "array"
                items:
                    name: "switch"
                    type: "object"
                    required: true
                    properties:
                        name: {type:"string", required:false}            
                        type:  {type:"string", required:false}                                                            
            nodes:
                type: "array"
                items:
                    name: "node"
                    type: "object"
                    required: true
                    properties:
                            name: {type:"string", required:true}            
            links:
                type: "array"
                items:
                    name: "node"
                    type: "object"
                    required: true            
                    properties:                
                        type: {type:"string", required:true}
                        switches:
                            type : "array"                     
                            required: false
                            items:
                                type : "object"
                                required: false
                        connected_nodes:
                            type: "array"
                            required: false
                            items:
                                type: "object"
                                required: false
                                properties:
                                    name:{"type":"string", "required":true}

    constructor: (id, data) ->
        super id, data, TopologySchema

#============================================================================================================
class Topology   

    constructor :() ->        
        @config = {}
        @sysconfig = {}
        @status = {}
        @statistics = {}        
        @switchobj = []
        @nodeobj =  []
        @linksobj = []

    systemconfig:(config) ->
        @sysconfig = extend {},config
    # Object Iterator functions... Async each is used in many place.. hence cannot be removed currently.
    # To be converted in to Hash model.
    getNodeObjbyName:(name) ->
        log.debug "getNodeObjbyName - input " + name
        for obj in @nodeobj
            log.debug "getNodeObjbyName - checking with " + obj.config.name
            if obj.config.name is name
                log.debug "getNodeObjbyName found " + obj.config.name
                return obj
        log.debug "getNodeObjbyName not found " + name
        return null

    getSwitchObjbyName:(name) ->
        log.debug "inpjut for check " + name
        for obj in @switchobj
            log.debug "getSwitchObjbyName iteratkon " + obj.config.name
            if obj.config.name is name
                log.debug "getSwitchObjbyName found " + obj.config.name
                return obj
        return null

    getSwitchObjbyUUID:(uuid) ->
        for obj in @switchobj
            log.debug "getSwitchObjbyUUID " + obj.uuid
            if obj.uuid is uuid
                log.debug "getSwitchObjbyUUID found " + obj.uuid
                return obj
        return null

    getNodeObjbyUUID:(uuid) ->
        for obj in @nodeobj
            log.debug "getNodeObjbyUUID" + obj.uuid
            if obj.uuid is uuid
                log.debug "getNodeObjbyUUID found " + obj.config.uuid
                return obj
        return null


    createSwitches :(cb)->
        async.each @switchobj, (sw,callback) =>
            log.info "create switch "
            sw.create (result) =>   
                #Todo:  Result value - Error Check to be done.
                log.debug "create switch result " + JSON.stringify result
                callback()
        ,(err) =>
            if err
                log.error "Error occured on createswitches function " + JSON.stringify err
                cb(false)
            else
                log.info "createswitches completed "
                cb (true)

    startSwitches :(cb)->
        async.each @switchobj, (sw,callback) =>
            log.info "start switch "
            sw.start (result) =>   
                #Todo : Result vaue to be checked.
                log.info "start switch result " + JSON.stringify result
            #this callback place to be relooked
            callback()
        ,(err) =>
            if err
                log.error "error occured " + JSON.stringify err
                cb(false)
            else
                log.info "startswitches all are processed "
                cb (true)

    #create and start the nodes
    # The node creation process is async.  node create (create) call immediately respond with "creation-in-progress"
    # creation process may take few minutes dependes on the VM SIZE.
    # poll the node status(getStatus) function, to get the creation status.  Once its created, the node will be 
    # started with (start ) function.
    # 
    # Implementation:
    #  async.each is used to process all the nodes.
    #  async.until is used for poll the status  until the node creation is success. once creation is success it start the node.

    createNodes :(cb)->    
        async.each @nodeobj, (n,callback) =>
            log.info "createing a node "
            
            n.create (result) =>   
                log.info "create node result " + JSON.stringify result
                #check continuosly till we get the creation status value 
                create = false
                async.until(
                    ()->
                        return create
                    (repeat)->
                        n.getstatus (result)=>
                            log.info "node creation #{n.uuid} status " + result.data.status
                            unless result.data.status is "creation-in-progress"
                                create = true
                                n.start (result)=>                    
                                    log.info "node start #{n.uuid} result " + JSON.stringify result
                                    return
                            setTimeout(repeat, 30000);
                    (err)->                        
                        log.info "createNodes completed execution"
                        callback(err)                        
                )
        ,(err) =>
            if err
                log.error "createNodes error occured " + err
                cb(false)
            else
                log.info "createNodes all are processed "
                cb (true)


    provisionNodes :(cb)->
        async.each @nodeobj, (n,callback) =>
            log.info "provisioning a node #{n.uuid}"
            n.provision (result) =>   
                #Todo : Result to be checked.
                log.info "provision node #{n.uuid} result  " + JSON.stringify  result
                callback()
        ,(err) =>
            if err
                log.error "ProvisionNodes error occured " + JSON.stringify err
                cb(false)
            else
                log.info "provisionNodes all are processed "
                cb (true)

    destroyNodes :()->
        #@tmparray = []
        #@destroySwithes()
        log.info "destroying the Nodes"

        async.each @nodeobj, (n,callback) =>
            log.info "delete node #{n.uuid}"
            n.del (result) =>                
                #@tmparray.push result
                #Todo: result to be checked
                callback()
        ,(err) =>
            if err
                log.error  "destroy nodes error occured " + JSON.stringify err
                return false
            else
                log.info "destroyNodes all are processed " + @tmparray
                return true
    
    destroySwitches :()->
        #@tmparray = []
        #@destroySwithes()
        log.info "destroying the Switches"

        async.each @switchobj, (n,callback) =>
            log.info "delete switch #{n.uuid}"
            n.del (result) =>                
                #Todo result to be checked
                #@tmparray.push result
                callback()
        ,(err) =>
            if err
                log.error "Destroy switches error occured " +  JSON.stringify err
                return false
            else
                log.info "Destroy Switches all are processed " + @tmparray
                return true

    #Create Links  
    createNodeLinks :(cb)->
        #travel each node and travel each interface 
        #get bridgename and vethname
        # call the api to add virtual interface to the switch
        async.each @nodeobj, (n,callback) =>
            log.info "create a Link"
            #travelling each interface

            for ifmap in n.config.ifmap
                if ifmap.veth?
                    obj = @getSwitchObjbyName(ifmap.brname)
                    if obj?
                        obj.connect ifmap.veth , (res) =>
                            log.info "Link connect result" + res
            #once all the ifmaps are processed, callback it.
            # TOdo : check whether async each to be used  for ifmap processing.
            callback()    

        ,(err) =>
            if err
                log.error "createNodeLinks error occured " + JSON.stringify err
                cb(false)
            else
                log.info "createNodeLinks  all are processed "
                cb (true)

    #createSwitchLinks
    createSwitchLinks :(cb)->
        #travel each switch object and call connect tapinterfaces        
        async.each @switchobj, (sw,callback) =>
            log.info "create a interconnection  switch Link"            
            sw.connectTapInterfaces (res)=>
                log.info "result" , res
            callback()    

        ,(err) =>
            if err
                log.error "createSwitchLinks error occured " + JSON.stringify err
                cb(false)
            else
                log.info "createSwitchLinks  all are processed "
                cb (true)



    #Topology REST API functions
    create :(@tdata )->
        #util.log "Topology create - topodata: " + JSON.stringify @tdata                             
        @config = extend {}, @tdata        
        @uuid = @tdata.id
        log.info "Topology - create - configdata " + JSON.stringify @config        
        #ipmgr = new IPManager(WAN_SUBNET,LAN_SUBNET, MGMT_SUBNET)
        ipmgr = new IPManager(@sysconfig.wansubnet,@sysconfig.lansubnet,@sysconfig.mgmtsubnet)
        if @tdata.data.switches?            
            for sw in @tdata.data.switches   
                sw.make = @sysconfig.switchtype
                sw.controller = @sysconfig.controller
                obj = new switches(sw)
                @switchobj.push obj

        for val in @tdata.data.nodes
            obj = new node(val)
            mgmtip = ipmgr.getFreeMgmtIP() 
            obj.addMgmtInterface mgmtip , '255.255.255.0'
            @nodeobj.push obj
        sindex = 1
        for val in @tdata.data.links                                    
            x = 0
            if val.type is "lan"
                temp = ipmgr.getFreeLanSubnet()  
                for sw in val.switches         
                    #switch object
                    log.info "processing the switch ",sw.name
                    swobj = @getSwitchObjbyName(sw.name)

                    for n in  sw.connected_nodes
                        obj = @getNodeObjbyName(n.name)
                        if obj?
                            startaddress = temp.iparray[x++]                        
                            obj.addLanInterface(sw.name, startaddress, temp.subnetMask, temp.iparray[0], sw.config)
                    if sw.connected_switches?
                        for n in  sw.connected_switches 
                            obj = @getSwitchObjbyName(n.name)
                            if obj?                            
                                srctaplink = "#{sw.name}_#{n.name}"
                                dsttaplink = "#{n.name}_#{sw.name}"                                                        
                                #swobj.createTapInterfaces srctaplink,dsttaplink
                                exec = require('child_process').exec
                                command = "ip link add #{srctaplink} type veth peer name #{dsttaplink}"
                                exec command, (error, stdout, stderr) =>

                                #console.log "createTapinterfaces completed", result
                                obj.addTapInterface(dsttaplink) 
                                swobj.addTapInterface(srctaplink)  

            if val.type is "wan"
                temp = ipmgr.getFreeWanSubnet()
                #swname = "#{val.type}_#{val.connected_nodes[0].name}_#{val.connected_nodes[1].name}"
                swname = "#{val.type}_sw#{sindex}"
                sindex++
                log.debug "  wan swname is "+ swname
                obj = new switches
                    name : swname
                    ports: 2
                    type : val.type
                    make : @sysconfig.switchtype
                    controller : @sysconfig.controller
                @switchobj.push obj
                for n in  val.connected_nodes
                    console.log n.name
                    log.info "updating wan interface for ", n.name
                    obj = @getNodeObjbyName(n.name)
                    if obj?
                        startaddress = temp.iparray[x++]
                        obj.addWanInterface(swname, startaddress, temp.subnetMask, null, val.config)                        

        #Todo : Below functions (create) to be placed in asyn framework
        @createSwitches (res)=>
            log.info "createswitches result" + res   
                     
            @createNodes (res)=>
                log.info "topologycreation status" + res
                #Check the sttatus and do provision
                @createNodeLinks (res)=>
                    log.info "create Nodelinks result " + res

                    @createSwitchLinks (res)=>
                        log.info "create Switchlinks result " + res

                        @startSwitches (res)=>
                            log.info "start switches result "  + res

                            log.info "Topology creation completed"
        
                        #provision
                        #@provisionNodes (res)=>
                        #    util.log "provision" + res



    del :()->
        res = @destroyNodes() 
        res1 = @destroySwitches()
        return {
            "id" : @uuid
            "status" : "deleted"
        }


    get :()->
        nodestatus = []
        switchstatus = []

        for n in @nodeobj
            nodestatus.push n.get()
        for n in @switchobj
            switchstatus.push n.get()
        #"config" : @config        
        "nodes" : nodestatus
        "switches":  switchstatus    

#============================================================================================================


class TopologyMaster
    constructor :(filename) ->
        @registry = new TopologyRegistry filename if filename?
        @registry = new TopologyRegistry unless filename?
        @topologyObj = {}
        @sysconfig = {}
        log.info "TopologyMaster - constructor - TopologyMaster object is created"  

    configure : (config)->        
        @sysconfig = extend {}, config
        log.debug "Topologymaster system config " + JSON.stringify @sysconfig
        
    #Topology specific REST API functions
    list : (callback) ->
        return callback @registry.list()

    create : (data, callback)->
        try	            
            topodata = new TopologyData null, data    
        catch err
            log.error "TopologyMaster - create - invalid schema " + JSON.stringify err
            return callback new Error "Invalid Input "
        finally				
            #log.info "TopologyMaster - create - topologyData " + JSON.stringify topodata 

        #finally create a project                    
        log.info "TopologyMaster - create - creating a new Topology with " + JSON.stringify topodata
        obj = new Topology
        obj.systemconfig @sysconfig
        obj.create topodata              
        @topologyObj[obj.uuid] = obj
        return callback @registry.add topodata                
   
    del : (id, callback) ->
        obj = @topologyObj[id]
        if obj? 
            #remove the registry entry
            @registry.remove obj.uuid
            #remove the topology object entry from hash
            delete @topologyObj[id]
            #call the del method to remove the nodes, switches etc.
            result = obj.del()
            #Todo : delete the object (to avoid memory leak)- dont know how.
            #delete obj
            return callback result
        else
            return callback new Error "Unknown Topology ID"

    get : (id, callback) ->
        obj = @topologyObj[id]
        if obj? 
            return callback obj.get()
        else
            return callback new Error "Unknown Topology ID"
       
    #Device specific rest API f#unctions

    deviceStats: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.stats (result)=>
                    callback result
            else                
                callback new Error "Unknown Device ID"
        else
            callback new Error "Unknown Topology ID"


     deviceGet: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.getstatus (result)=>
                    return callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"


    deviceStatus: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.getrunningstatus (result)=>
                    return callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"

    deviceStart: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.start (result)=>
                    callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"


    deviceStop: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]        
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.stop (result)=>
                    callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"

    deviceTrace: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]        
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.trace (result)=>
                    callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"

    deviceDelete: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.del (result)=>    
                    return callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"


#============================================================================================================
#module.exports =  new TopologyMaster '/tmp/topology.db'
module.exports =  new TopologyMaster