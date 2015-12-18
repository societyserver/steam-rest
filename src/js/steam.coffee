# File: services.coffee
#   defines angular.js services

services = angular.module 'steam-service', []
services.value 'version', '0.1'

# Service: steam
#   wraps around the $http service to access the sTeam REST api.
#   ( http://docs.angularjs.org/api/ng.$http )
#
#   uses http://angularjs.org/object/localStorageService
#   to store data in the browsers localstorage
#
#   provides functions to handle login, get data, put new objects and post updates
#
#   functions return a promise object which expects a callback function as argument:
#
#   steam.<function>(args).then(callback_handler)
#
#   callback_handler needs to be defined before calling the service.
#   it receives the data from the server as argument:
#
#   handle_request = (data) ->
#      # do something with the data
#
#   public functions are:
#      login(username, password): 
#          take and store login data
#      logout: remove login data
#      loginp: return true if the user is logged in, false otherwise
#      user: return userdetails if logged in
#      get(resource):
#          make a GET request and return resulting JSON data
#          resource describes the path to the sTeam object within sTeam
#          returns the data of the requested object
#      post(resource, data):
#          POST data to update existing sTeam objects
#          resource describes the path to the sTeam object to be updated
#          returns the data of the updated object
#      put(resource, data):
#          PUT data to create new objects
#          resource is the parent object within which the new object is to be created
#          returns the data of the updated object
#  (not sure in how much detail get, put and post descriptions should go. their
#  semantics are defined by the REST api so this should actually be part of the
#  REST api documentation)

services.factory 'steam', ($http, localStorageService) ->
	baseurl = 'http://dev-back1.techgrind.asia/'
	restapi = baseurl+'scripts/rest.pike?request='

	# helperfunction to preprocess the returned data.
	# the sTeam server includes the current user whith which the request was made
	# because we are using basic authentication there is no seperate login step,
	# but login happens again with each request.
	# the sTeam response includes the user-data for the user of this request 
	# and we store that user data in the browser for later access.
	handle_request = (response) ->
		localStorageService.add('user', JSON.stringify(response.data.me))
		console.log("steam-service", "response", response)
		response.data

	# test if the user is logged in.
	# this does not make a request to the server but only verifies that we have
	# received valid user-data before.
	loginp = ->
		logindata = JSON.parse(localStorageService.get('logindata'))
		user = JSON.parse(localStorageService.get('user'))
		logindata and user and user.id and user.id != "guest"

	# headers which are needed to be added to every request
	headers = (login) ->
		logindata = JSON.parse(localStorageService.get('logindata'))
		if loginp() or (login and logindata)
			headers: logindata
		else
			{}

	# store username and password in the browser and then make a login request to test them
	# handle_request will store the user-data sent by the server to complete the login. 
	login: (userid, password) ->
		console.log("steam-service", "login:", userid, password)
		if userid != "" and password != ""
			localStorageService.add('logindata', JSON.stringify(Authorization: 'Basic '+window.btoa(userid + ":" + password)))
			$http.get(restapi+"login", headers(true)).then(handle_request)

	# wipe username and password from local storage and send a login request to
	# the server which will cause the server to respond with 'guest' user data,
	# replacing our previously stored user data
	logout: ->
		localStorageService.remove('logindata')
		localStorageService.remove('user')
		$http.get(restapi+"login", headers()).then(handle_request)

	# same as the loginp function above
	loginp: loginp

	# only return user data if we are logged in.
	user: ->
		if loginp()
			JSON.parse(localStorageService.get('user'))

	get: (request) ->
		console.log("steam-service", "GET", request)
		$http.get(restapi+request, headers()).then(handle_request)

	post: (request, data) ->
		console.log("steam-service", "POST", request, data)
		$http.post(restapi+request, data, headers()).then(handle_request)

	put: (request, data) ->
		console.log("steam-service", "PUT", request, data)
		$http.put(restapi+request, data, headers()).then(handle_request)

	delete: (request) ->
		console.log("steam-service", "DELETE", request)
		$http.delete(restapi+request, headers()).then(handle_request)

