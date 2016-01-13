app = angular.module 'app', [
	'LocalStorageModule'
	'steam-service'
	'steam-rest-examples.main'
	'steam-rest-examples.register'
	'ui.router'
	'ui.bootstrap'
]

app.config ['$urlRouterProvider', '$stateProvider', ($urlRouterProvider, $stateProvider) ->
	$urlRouterProvider
		.otherwise '/home'
	
	$stateProvider.state 'home',
			url: '/home'
			templateUrl: 'partials/home.html'
			controller: 'HomeCtrl'

	$stateProvider.state 'register',
			url: '/register'
			templateUrl: 'partials/register.html'
			controller: 'RegisterCtrl'
]
