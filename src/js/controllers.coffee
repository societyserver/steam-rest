app = angular.module 'TechGrindApp.controllers', []

app.controller 'MyCtrl1', ['$scope', '$http', (S, http) ->
	http.get('/mock').success (data) -> S.mock = data
]

app.controller 'MyCtrl2', [ -> ]
