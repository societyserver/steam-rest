app = angular.module 'SteamRestExamples', [
        'ngRoute'
        'LocalStorageModule'
        'steam-service'
]

app.config ['$routeProvider', ($routeProvider) ->
	$routeProvider.when '/home',
		templateUrl: 'partials/home.html'
		controller: 'HomeCtrl'

	$routeProvider.otherwise redirectTo: '/home'
]
