util = require('util')
request = require('request-json');
extend = require('util')._extend
switchctrl = require('./builder/switchCtrl')

log = require('./utils/logger').getLogger()
log.info "Switches Logger test message"

#global parameter
#log = require('./app').log

class switches    
    constructor: (sw)->                
        @config = extend {}, sw
        @config.make ?= "bridge"
        @status = {}
        @statistics = {}
        @tapifs = []
        log.info "Switches - constructor -  new switch object created " + JSON.stringify @config
        
    create: (callback)->
        log.info "Switches -  creating a switch with config " + JSON.stringify @config
        switchctrl.create @config, (res) =>
            #console.log "post switch response" +res    
            log.info "Switches - switch creation result " + JSON.stringify res
            @uuid = res.id 
            callback res

    del: (callback)->
        log.info "Switches - deleting a switch " + JSON.stringify  @config
        switchctrl.del @uuid, (res) =>
            #console.log res
            log.info "Switches -  switch  deletion result " + res
            callback res    

    get:()->
        "uuid":@uuid
        "config":@config
        "status":@status
        "statistics":@statistics
    stop:()->
        log.info "Switches -   stoping a switch ", + JSON.stringify config
        switchctrl.stop @uuid, (res) =>
            log.info "Switches - switch stop result " + JSON.stringify res
            #console.log res
            callback res                  

    start:()->
        log.info "Switches -  starting a switch ", + JSON.stringify  @config
        switchctrl.start @uuid, (res) =>
            log.info "Switches -   switch start result " + JSON.stringify res
            #console.log res
            callback res                  

    connect:(ifname,callback)->
        val =
            "ifname": ifname              
        log.info "Switches -  connecting a interface  #{ifname} in switch #{@config.name}"
        switchctrl.addInterface @uuid, val, (res) =>
            log.info "Switches - connect-  interface  #{ifname} connection result " + JSON.stringify res
            #console.log res
            callback res    

    createTapInterfaces:(ifname1,ifname2)->
        log.info "Switches - createTapInterfaces - input  #{ifname1}   #{ifname2}"
        result = switchctrl.CreateTapInterfaces ifname1, ifname2
        log.info "Switches - createTapInterfaces - result " + JSON.stringify result
        return result
    
    addTapInterface:(ifname)->
        @tapifs.push ifname if ifname?
        log.info "Switches - addTapInterface - ifname " + ifname
        return

    connectTapInterfaces:(callback)->
        log.info "Switches - connectTapInterfaces ...connecting the inter switch links"
        for tapif in @tapifs
            #Async model to be introduced
            @connect tapif,(result)=>                
                callback result
        callback


    switchStatus:()->   
        #Todo be done    
    statistics:()->
        #Todo

#####################################################################################################
module.exports = switches
#Todo items:  HTTP Request json timeout, response code to be checked 
