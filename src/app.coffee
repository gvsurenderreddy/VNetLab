restify = require 'restify'
util = require('util')
fs = require 'fs'


argv = require('minimist')(process.argv.slice(2))
if argv.h?
    console.log """
        -h view this help
        -l logfile (ex: /var/log/vnetlabs.log)
        -z log level: trace, debug, info, warn, error
        -C sdn controller ip (eg " loalhost:6633)
        -S switch type ('openvswitch' or 'linuxbridge')
        -V virtualization type ('lxc' or 'docker')
        -W wan subnet 
        -L Lan subnet
        -M Mgmt subnet
        -I Lxc image name (eg: "node")  
    """
    return

config =
    logfile: argv.l ? "/var/log/vnetlabs.log"
    loglevel: if argv.z in [ 'trace','debug','info','warn','error' ] then argv.z else 'info'
    controller: argv.C ? null
    switchtype: if argv.S in ['openvswitch','linuxbridge'] then argv.S else 'linuxbridge'
    virtualization : if argv.V in ['lxc','docker']  then argv.V else 'lxc'
    wansubnet : argv.W  ? '172.27.1.0'
    lansubnet : argv.L  ? '10.10.10.0'
    mgmtsubnet : argv.M ? '10.0.3.0'
    lxcimage : argv.I ? 'device'

#console.log config

#setting up the logger
log = require('./utils/logger').createLogger(config.loglevel,config.logfile)
log.info "VnetLab application starts..... "
log.info "System Configuration " + JSON.stringify config
console.log "System Configuration " + JSON.stringify config
#log.debug, log.info, log.warn, log.notice,log.warning, log.critical, log.alert, log.emergency

#check the system capability to run vnetlab
systemcheck = ()->
    log.info "performing system check"
	log.debug "checking the lxc installation files"
	log.info "system check passed"

systemcheck()


log.info "starting the REST api services..."
#---------------------------------------------------------------------------------------#
# REST APIs
#---------------------------------------------------------------------------------------#

topology = require('./Topology')
topology.configure(config)

topologyPost = (req,res,next)->   
    log.info "REST API - POST /Topology received, body contents - " + JSON.stringify req.body
    topology.create req.body, (result) =>
        log.info "POST /Topology result " + JSON.stringify result 
        res.send result        
        next()

topologyList = (req,res,next)->     
    log.info "REST API - GET /Topology received "
    topology.list (result) =>
        log.info "REST API - GET /Topology result " + JSON.stringify result
        res.send result        
        next()

topologyGet = (req,res,next)->           
    log.info "REST API - GET /Topology/:id received ", req.params.id
    topology.get req.params.id, (result) =>
        util.log "REST API - GET /Topology/id result " + JSON.stringify result        
        res.send result   
        next()

topologyDelete = (req,res,next)->  
    log.info "REST API - DELETE /Topology/:id received - ",req.params.id
    topology.del req.params.id, (result) =>
        log.info "REST API - DELETE /Topology/:id result  " + JSON.stringify result
        res.send result   
        next()
 

#---------------------------------------------------------------------------------------#
# REST Server routine starts here
#---------------------------------------------------------------------------------------#
server = restify.createServer()
server.use(restify.acceptParser(server.acceptable));
server.use(restify.queryParser());
server.use(restify.jsonp());
server.use(restify.bodyParser());


server.post '/Topology', topologyPost
server.get '/Topology', topologyList
server.get '/Topology/:id', topologyGet
server.del '/Topology/:id', topologyDelete

server.listen 5050,()->
    console.log 'VNetLab listening on port : 5050.....'