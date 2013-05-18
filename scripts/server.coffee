#!/usr/bin/env coffee
express = require 'express'
app = module.exports = express()

coffee = require 'coffee-script'		# for on the fly compilation
fs = require 'fs'
root_dir = __dirname + '/..'
public_dir = root_dir + '/app'
src_dir = root_dir + '/src/'

stylus = require 'stylus'

app.configure ->
	app.set 'view engine', 'jade'
	app.set 'views', src_dir
	app.locals.pretty = true
	app.use express.favicon()
	app.use express.logger('dev', @logOptions) if !module.parent	# don't log in test mode
	app.use express.compress()
	app.use express.methodOverride()
	app.use express.bodyParser()
	app.use express.static public_dir
	app.use '/test', express.static root_dir + '/test'
	app.use app.router

app.configure 'development', ->
	app.use express.errorHandler  dumpExceptions: true, showStack: true

app.configure 'production', ->
	app.use express.errorHandler()

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
