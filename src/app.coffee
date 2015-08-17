restify = require 'restify'
topology = require('./Topology')        
util = require('util')


#---------------------------------------------------------------------------------------#
# REST APIs
#---------------------------------------------------------------------------------------#
topologyPost = (req,res,next)->   
    util.log "Topology Post received body - ", req.body
    topology.create req.body, (result) =>
        util.log "POST Topology result " + result 
        res.send result        
        next()

topologyGet = (req,res,next)->           
    next()

topologyStatusGet = (req,res,next)->   
    next()

topologyDelete = (req,res,next)->  
    next() 

#---------------------------------------------------------------------------------------#
# Main Server routine starts here
#---------------------------------------------------------------------------------------#
server = restify.createServer()
server.use(restify.acceptParser(server.acceptable));
server.use(restify.queryParser());
server.use(restify.jsonp());
server.use(restify.bodyParser());


server.post '/Topology', topologyPost
server.post '/Topology', topologyGet
server.get '/Topology/:id/status', topologyStatusGet
server.del '/Topology/:id', topologyDelete

#server.get '/Topology/:id/device/:id',deviceGet
#server.get '/Topology/:id/device/:id/stats',deviceStatsGet
#server.put '/Topology/:id/device/:id/start',deviceStart
#server.put '/Topology/:id/device/:id/stop',deviceStop
#server.delete '/Topology/:id/device/:id/', deviceDelete

server.listen 5050,()->
    console.log 'VNetLab listening on port : 5050.....'
