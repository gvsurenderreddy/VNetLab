
StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
async = require 'async'

IPManager = require('./IPManager')
node = require('./Node')
switches = require('./Switches')

util = require 'util'


## Global IP Manager for  -- To be relooked the design
MGMT_SUBNET = "10.0.3.0"
WAN_SUBNET = "172.16.1.0"
LAN_SUBNET = "10.10.10.0"

#Todo : 
#Global MGMT_SUBNET  and WAN, LAN SUBNET per topology-  currently all 3 subnets are global.
#ipmgr = new IPManager(WAN_SUBNET,LAN_SUBNET, MGMT_SUBNET)
#============================================================================================================
class TopologyRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            util.log "restoring #{key} with:",val
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
                        ports: {type:"integer", required:false}
                        make: {type:"string", required:true}
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
        @status = {}
        @statistics = {}        
        @switchobj = []
        @nodeobj =  []
        @linksobj = []

    # Object Iterator functions... Async each is used in many place.. hence cannot be removed currently.
    # To be converted in to Hash model.
    getNodeObjbyName:(name) ->
        util.log "getNodeObjbyName - input " + name
        for obj in @nodeobj
            util.log "getNodeObjbyName - checking with " + obj.config.name
            if obj.config.name is name
                util.log "getNodeObjbyName found " + obj.config.name
                return obj
        util.log "getNodeObjbyName not found " + name
        return null

    getSwitchObjbyName:(name) ->
        util.log "inpjut for check " + name
        for obj in @switchobj
            util.log "getSwitchObjbyName iteratkon " + obj.config.name
            if obj.config.name is name
                util.log "getSwitchObjbyName found " + obj.config.name
                return obj
        return null

    getSwitchObjbyUUID:(uuid) ->
        for obj in @switchobj
            util.log "getSwitchObjbyUUID " + obj.uuid
            if obj.uuid is uuid
                util.log "getSwitchObjbyUUID found " + obj.uuid
                return obj
        return null

    getNodeObjbyUUID:(uuid) ->
        for obj in @nodeobj
            util.log "getNodeObjbyUUID" + obj.uuid
            if obj.uuid is uuid
                util.log "getNodeObjbyUUID found " + obj.config.uuid
                return obj
        return null


    createSwitches :(cb)->
        async.each @switchobj, (sw,callback) =>
            util.log "create switch "
            sw.create (result) =>   
                #Todo:  Result value - Error Check to be done.
                util.log "create switch result " + JSON.stringify result
                callback()
        ,(err) =>
            if err
                util.log "Error occured on createswitches function " + err
                cb(false)
            else
                util.log "createswitches completed "
                cb (true)

    startSwitches :(cb)->
        async.each @switchobj, (sw,callback) =>
            util.log "start switch "
            sw.start (result) =>   
                #Todo : Result vaue to be checked.
                util.log "start switch result " + JSON.stringify result
                callback()
        ,(err) =>
            if err
                util.log "error occured " + err
                cb(false)
            else
                util.log "startswitches all are processed "
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
            util.log "createing a node "
            
            n.create (result) =>   
                console.log "create node result " ,result
                #check continuosly till we get the creation status value 
                create = false
                async.until(
                    ()->
                        return create
                    (repeat)->
                        n.getstatus (result)=>
                            util.log "node creation #{n.uuid} status " + result.data.status
                            unless result.data.status is "creation-in-progress"
                                create = true
                                n.start (result)=>                    
                                    util.log "node start #{n.uuid} result " + result
                                    return
                            setTimeout(repeat, 30000);
                    (err)->                        
                        util.log "createNodes completed execution"
                        callback(err)                        
                )
        ,(err) =>
            if err
                util.log "createNodes error occured " + err
                cb(false)
            else
                util.log "createNodes all are processed "
                cb (true)


    provisionNodes :(cb)->
        async.each @nodeobj, (n,callback) =>
            util.log "provisioning a node #{n.uuid}"
            n.provision (result) =>   
                #Todo : Result to be checked.
                util.log "provision node #{n.uuid} result  " + result
                callback()
        ,(err) =>
            if err
                util.log "ProvisionNodes error occured " + err
                cb(false)
            else
                util.log "provisionNodes all are processed "
                cb (true)

    destroyNodes :()->
        #@tmparray = []
        #@destroySwithes()
        util.log "destroying the Nodes"

        async.each @nodeobj, (n,callback) =>
            util.log "delete node #{n.uuid}"
            n.del (result) =>                
                #@tmparray.push result
                #Todo: result to be checked
                callback()
        ,(err) =>
            if err
                util.log  "destroy nodes error occured " + err
                return false
            else
                util.log "destroyNodes all are processed " + @tmparray
                return true
    
    destroySwitches :()->
        #@tmparray = []
        #@destroySwithes()
        util.log "destroying the Switches"

        async.each @switchobj, (n,callback) =>
            util.log "delete switch #{n.uuid}"
            n.del (result) =>                
                #Todo result to be checked
                #@tmparray.push result
                callback()
        ,(err) =>
            if err
                util.log "Destroy switches error occured " + err
                return false
            else
                util.log "Destroy Switches all are processed " + @tmparray
                return true

    #Create Links  
    createNodeLinks :(cb)->
        #travel each node and travel each interface 
        #get bridgename and vethname
        # call the api to add virtual interface to the switch
        async.each @nodeobj, (n,callback) =>
            util.log "create a Link"
            #travelling each interface

            for ifmap in n.config.ifmap
                if ifmap.veth?
                    obj = @getSwitchObjbyName(ifmap.brname)
                    if obj?
                        obj.connect ifmap.veth , (res) =>
                            util.log "Link connect result" + res
            #once all the ifmaps are processed, callback it.
            # TOdo : check whether async each to be used  for ifmap processing.
            callback()    

        ,(err) =>
            if err
                util.log "createNodeLinks error occured " + err
                cb(false)
            else
                util.log "createNodeLinks  all are processed "
                cb (true)

    #createSwitchLinks
    createSwitchLinks :(cb)->
        #travel each switch object and call connect tapinterfaces        
        async.each @switchobj, (sw,callback) =>
            util.log "create a interconnection  switch Link"            
            sw.connectTapInterfaces (res)=>
                console.log "result" , res
            callback()    

        ,(err) =>
            if err
                util.log "createNodeLinks error occured " + err
                cb(false)
            else
                util.log "createNodeLinks  all are processed "
                cb (true)





    #Topology REST API functions
    create :(@tdata )->
        #util.log "Topology create - topodata: " + JSON.stringify @tdata                             
        @config = extend {}, @tdata        
        @uuid = @tdata.id
        util.log "topology config data " + JSON.stringify @config        
        ipmgr = new IPManager(WAN_SUBNET,LAN_SUBNET, MGMT_SUBNET)

        if @tdata.data.switches?
            for sw in @tdata.data.switches   
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
                    console.log "processing the switch ",sw.name
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
                util.log "  wan swname is "+ swname
                obj = new switches
                    name : swname
                    ports: 2
                    type : val.type
#                   make : val.make 
                @switchobj.push obj
                for n in  val.connected_nodes
                    console.log n.name
                    util.log "updating wan interface for ", n.name
                    obj = @getNodeObjbyName(n.name)
                    if obj?
                        startaddress = temp.iparray[x++]
                        obj.addWanInterface(swname, startaddress, temp.subnetMask, null, val.config)                        

        #Todo : Below functions (create) to be placed in asyn framework
        @createSwitches (res)=>
            util.log "createswitches result" + res   
                     
            @createNodes (res)=>
                util.log "topologycreation status" + res
                #Check the sttatus and do provision
                @createNodeLinks (res)=>
                    util.log "create Nodelinks result " + res

                    @createSwitchLinks (res)=>
                        util.log "create Switchlinks result " + res

                        @startSwitches (res)=>
                            util.log "start switches result "  + res

                            util.log "Topology creation completed"
        
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

    #below function is not used- to be removed
    #vmstatus :(callback)->
    #    arr = []
    #    util.log "inside topoloy status function"
    #    for n in @nodeobj
    #        n.nodestatus (val) =>
    #            arr.push val
    #            callback arr
    #Device specific rest api functions


#============================================================================================================


class TopologyMaster
    constructor :(filename) ->
        @registry = new TopologyRegistry filename        
        @topologyObj = {}
        

    #Topology specific REST API functions
    list : (callback) ->
        return callback @registry.list()

    create : (data, callback)->
        try	            
            topodata = new TopologyData null, data    
        catch err
            util.log "invalid schema" + err
            return callback new Error "Invalid Input "
        finally				
            util.log JSON.stringify topodata           

        #finally create a project                    
        util.log "in topology creation"
        obj = new Topology
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
module.exports =  new TopologyMaster '/tmp/topology.db'



#Limitations ---  To be addressed later
#1. vm name is used as given in the REST API.  Hence there is a  possibility that node (VM may exists in the same name)
#  No check in the code,  User should take care of the vmname name .
#There is a limitation in the lxcname and vm name ---  Name should not exceed 5 chars
#2. Application LOST the topology details upon restarts, it lost the existing topology object .
#  Application doesnt  and poll the status of the existing topology and get the object.
#4.   some code cleanup - wherever mentioned in the code.
#5.   config file to read the port number for ventbuilder, ventprovisioner, venetcontroller and default port.. ?
#6. secure communication to vnetbuilder and provisioner


