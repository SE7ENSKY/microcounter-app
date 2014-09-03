http = require 'http'

server = http.createServer (req, res) ->
	res.writeHead 200,
		'Content-Type': 'text/plain'
	res.end 'okay'

server.listen process.env.PORT or 3000