app = angular.module 'TechGrindApp'
app.config ($provide) ->
	$provide.decorator '$httpBackend', angular.mock.e2e.$httpBackendDecorator

app.run ($httpBackend) ->
	$httpBackend.whenGET('/mock').respond 200, 'MOCK DATA'
	$httpBackend.whenGET().passThrough()
