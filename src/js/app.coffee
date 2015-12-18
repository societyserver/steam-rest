app = angular.module 'SteamRestExamples', [
        'ngRoute'
        'LocalStorageModule'
        'steam-service'
        'SteamRestExamples.register'
]

app.config ['$routeProvider', ($routeProvider) ->
	$routeProvider.when '/home',
		templateUrl: 'partials/home.html'
		controller: 'HomeCtrl'

	$routeProvider.when '/register',
		templateUrl: 'partials/register.html'
		controller: 'RegisterCtrl'

	$routeProvider.otherwise redirectTo: '/register'
]
