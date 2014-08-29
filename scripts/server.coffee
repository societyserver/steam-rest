#!/usr/bin/env coffee

express = require 'express'
logger = require 'morgan'
compress = require 'compression'
methodOverride = require 'method-override'
bodyParser = require 'body-parser'
serveStatic = require 'serve-static'
errorHandler = require 'errorhandler'

app = module.exports = express()

coffee = require 'coffee-script'		# for on the fly compilation
fs = require 'fs'
root_dir = __dirname + '/..'
public_dir = root_dir + '/app'
src_dir = root_dir + '/src/'

#app.set 'view engine'
#app.set 'views', src_dir
#app.locals.pretty = true
app.use logger('dev', @logOptions) if !module.parent	# don't log in test mode
app.use compress()
app.use methodOverride()
app.use bodyParser()
app.use serveStatic public_dir
app.use '/test', serveStatic root_dir + '/test'

#app.configure 'development', ->
env = process.env.NODE_ENV || 'development'
if 'development' == env
	app.use errorHandler  dumpExceptions: true, showStack: true
else
	#app.configure 'production', ->
	app.use errorHandler()

if !module.parent
	app.listen port = 8000
	console.log 'Listening on port ' + port

app.get '/js/:script.js', (req, res) ->
	res.header 'Content-Type', 'application/javascript'
	res.send coffee.compile fs.readFileSync(
		"#{src_dir}/js/#{req.params.script}.coffee", "utf-8")
app.get /(\/test\/(.+\/)?[^\/]+).js/, (req, res) ->
	res.header 'Content-Type', 'application/javascript'
	res.send coffee.compile fs.readFileSync(
		"#{root_dir + req.params[0]}.coffee", "utf-8")

app.get '/', (req, res) -> res.render 'index'
app.get '/:dir?/:file.html', (req, res) ->
	res.render (req.params.dir || '.') + '/' + req.params.file
