directives = angular.module 'TechGrindApp.directives', []
directives.directive 'appVersion', ['version', (version) ->
	return (scope, elm, attrs) -> elm.text version
]