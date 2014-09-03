unless process.env.MONGOLAB_URI or process.env.MONGODB_URL
	console.log 'App requires mongodb database. Provide MONGOLAB_URI or MONGODB_URL env var.'
	process.exit 1

unless process.env.ACCEPT_HOSTS
	console.log 'App requires to know what referers to accept. Provide ACCEPT_HOSTS env var.'
	process.exit 1

ACCEPT_HOSTS = process.env.ACCEPT_HOSTS.split ','

initMongoDb = (uri, done) ->
	MongoClient = require('mongodb').MongoClient
	MongoClient.connect uri, done

initHttpServer = (port, handler, done) ->
	http = require 'http'

	server = http.createServer handler

	server.listen port
	done null, server

counters = {}
counterAutoIncrement = (host, path, done) ->
	counters[host] = {} unless counters[host]
	done null, if counters[host][path]
		++counters[host][path]
	else
		counters[host][path] = 1

handleRequest = (req, res) ->
	URL = require 'url'
	respondError = (message, code = 500) ->
		res.writeHead code,
			'Content-Type': 'text/plain'
			'Access-Control-Allow-Origin': '*'
		res.end "Error: #{message}"
	respondValue = (value, code = 200) ->
		res.writeHead code,
			'Content-Type': 'text/plain'
			'Access-Control-Allow-Origin': '*'
		if typeof value is 'string'
			res.end value
		else
			res.end "#{value}"

	if req.url is '/auto'
		return respondError "Referer required for auto mode.", 409 unless req.headers.referer
		parsedReferer = URL.parse req.headers.referer, yes
		return respondError "This referer won't be counted!", 403 unless parsedReferer.host in ACCEPT_HOSTS
		counterAutoIncrement parsedReferer.host, parsedReferer.path, (err, value) ->
			if err
				console.log err
				respondError "Error performing count!"
			else
				respondValue value
	else
		respondError "Not found", 404

initMongoDb process.env.MONGOLAB_URI or process.env.MONGODB_URL, (err, db) ->
	throw err if err
	console.log "Connected to mongodb."
	
	initHttpServer process.env.PORT or 3000, handleRequest, (err, server) ->
		throw err if err
		console.log "Started microcounter at port #{process.env.PORT or 3000}."
