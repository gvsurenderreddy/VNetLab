StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
async = require 'async'

vmctrl = require('./builder/vmCtrl')


#utility functions 
#Todo:  Not scalable....To be modified
#HWADDR_PREFIX = "00:16:3e:5a:55:"
HWADDR_PREFIX = "00:00:00:00:00:"

HWADDR_START = 10
getHwAddress = () ->
    HWADDR_START++      
    hwaddr= "#{HWADDR_PREFIX}#{HWADDR_START}"
    hwaddr


class node
    constructor:(data) ->
        @ifmap = []        
        @ifindex = 1
        @config = extend {}, data   
        @config.ifmap = @ifmap        
        @statistics = {}
        @status = {}
        console.log "inside node creation", @config

   
    addLanInterface :(brname, ipaddress, subnetmask, gateway, characterstics) ->         
        interf =
            "ifname" : "eth#{@ifindex}"
            "hwAddress" : getHwAddress()
            "brname" : brname 
            "ipaddress": ipaddress 
            "netmask" : subnetmask
            "gateway" : gateway if gateway?
            "type":"lan"
            "veth" : "#{@config.name}_veth#{@ifindex}"
            "config": characterstics
        @ifindex++
        @ifmap.push  interf

    addWanInterface :(brname, ipaddress, subnetmask, gateway , characterstics) ->         
        console.log "inside addWanInterface function"
        interf =
            "ifname" : "eth#{@ifindex}"
            "hwAddress" : getHwAddress()
            "brname" : brname
            "ipaddress": ipaddress
            "netmask" : subnetmask
            "gateway" : gateway if gateway?
            "type":"wan"
            "veth" : "#{@config.name}_veth#{@ifindex}"
            "config": characterstics
        console.log "waninterface " , interf
        @ifindex++
        @ifmap.push  interf

    addMgmtInterface :(ipaddress, subnetmask) ->
        interf =
            "ifname" : "eth0"
            "hwAddress" : getHwAddress()                
            "ipaddress": ipaddress
            "netmask" : subnetmask                
            "type":"mgmt"
        @ifmap.push  interf
        console.log @ifmap

    create : (callback)->
        console.log "createing node" + JSON.stringify @config       
        vmctrl.create @config, (result) =>
            @uuid = result.id
            @config.id = @uuid
            @status.result = result.status
            @status.result = result.reason if result.reason?
            console.log result
            callback result
    start : (callback)->
        vmctrl.start @uuid, (result) =>
            console.log result
            callback result
    stop : (callback)->
        vmctrl.stop @uuid, (result) =>
            console.log result
            callback result
    trace : (callback)->
        vmctrl.packettrace @uuid, (res) =>
            console.log res
            @send res    
    del : (callback)->
        vmctrl.del @uuid, (res) =>
            console.log res
            @send res    
    getstatus : (callback)->
        console.log "getstatus called",@uuid
        vmctrl.get @uuid, (result) =>
            console.log result
            callback result
    getrunningstatus : (callback)->
        vmctrl.status @params.id, (res) =>
            console.log res
            callback res  

    get : () ->
        "id" : @uuid
        "config": @config
        "status": @status
        "statistics":@statistics
module.exports = node


#Todo items
#request.json - HTTP response  code
#Timeout condition - if server is not reachable
     