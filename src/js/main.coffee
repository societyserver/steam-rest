app = angular.module 'steam-rest-examples.main', []

app.controller 'NavCtrl', ['$scope', '$location', 'steam', (S, loc, steam) ->
	S.activeTab = 'Register'

	S.mainMenu = [
		name: 'Register'
		url: 'register'
		active: false
	,
		name: 'Login'
		url: 'login'
		active: false
	,
		name: 'Accessing a Room'
		url: 'room'
		active: false
	,
		name: 'Access a Document'
		url: 'document'
		active: false
	]

	S.selectTab = (tabName) ->
		S.activeTab = tabName

	S.isSelected = (tabName) ->
		return tabName == S.activeTab
	
]
