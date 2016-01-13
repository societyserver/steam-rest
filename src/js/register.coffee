app = angular.module 'steam-rest-examples.register', []

app.controller 'RegisterCtrl', ['$scope', '$location', 'steam', (S, loc, steam) ->
	S.registerdata = {}
	S.passwordmatch = true
	tested_users = {}
	S.tested_users = () ->
		tested_users
	S.user_checking = ->
		S.registerdata.userid and typeof tested_users[S.registerdata.userid] == 'undefined'
	S.user_available = ->
		typeof tested_users[S.registerdata.userid] != 'undefined' and !tested_users[S.registerdata.userid]
	S.user_taken = ->
		typeof tested_users[S.registerdata.userid] != 'undefined' and tested_users[S.registerdata.userid]

	S.register = ->
		S.registerdata.group = 'techgrind'
		steam.post('register', S.registerdata).then(handle_request)

	handle_request = (data) ->
		S.data = data

	S.$watch('[registerdata.password, registerdata.password2]', ->
		if S.registerdata.password and S.registerdata.password2 and S.registerdata.password != S.registerdata.password2
			S.passwordmatch = false
		else
			S.passwordmatch = true
	true)

	S.$watch('registerdata.fullname', ->
		count = 0
		if S.registerdata.fullname
			S.testname = S.registerdata.fullname.toLowerCase().replace(/[^a-z ]/g, "").trim().replace(/\s+/g, ".")
		S.registerdata.userid = S.testname

		handle_user = (data) ->
			console.log(sexpr("user-result", data))
			if data.error == "request not found"
				tested_users[data.request] = false
			else
				count++
				tested_users[data.request] = true
				if data.request==S.registerdata.userid
					S.registerdata.userid = S.testname+"."+count
					steam.get(S.registerdata.userid).then(handle_user)
		if S.registerdata.userid
			steam.get(S.registerdata.userid).then(handle_user))

	S.$watch('registerdata.userid', ->
		handle_user = (data) ->
			console.log(sexpr("userid-result", data))
			if data.error == "request not found"
				tested_users[data.request] = false
			else
				tested_users[data.request] = true
		if S.registerdata.userid
			steam.get(S.registerdata.userid).then(handle_user))
]
