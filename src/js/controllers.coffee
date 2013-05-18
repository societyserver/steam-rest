app = angular.module 'TechGrindApp.controllers', []

app.controller 'AppCtrl', ['$scope', '$location', (S, loc) ->
	S.active = (menuItem) -> if loc.path() == menuItem then 'active'
]

app.controller 'HomeCtrl', ['$scope', '$http', (S, http) ->
	http.get('/mock').success (data) -> S.mock = data
]
