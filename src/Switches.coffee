util = require('util')
request = require('request-json');
extend = require('util')._extend
switchctrl = require('./builder/switchCtrl')


class switches    
    constructor: (sw)->                
        @config = extend {}, sw
        @config.make ?= "bridge"
        @status = {}
        @statistics = {}
        util.log " switch config " + JSON.stringify @config
        
    create: (callback)->
        switchctrl.create @config, (res) =>
            console.log "post switch response" +res    
            @uuid = res.id 
            callback res

    del: (callback)->
        switchctrl.del @uuid, (res) =>
            console.log res
            callback res    

    get:()->
        "uuid":@uuid
        "config":@config
        "status":@status
        "statistics":@statistics
    stop:()->
        switchctrl.stop @uuid, (res) =>
            console.log res
            callback res                  

    start:()->
        switchctrl.start @uuid, (res) =>
            console.log res
            callback res                  

    connect:(ifname,callback)->
        val =
            "ifname": ifname              
        switchctrl.addInterface @uuid, val, (res) =>
            console.log res
            callback res    

    switchStatus:()->   
        #Todo be done    
    statistics:()->
        #Todo

#####################################################################################################
module.exports = switches
#Todo items:  HTTP Request json timeout, response code to be checked 
