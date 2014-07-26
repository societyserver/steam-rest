app = angular.module 'myapp', ['LocalStorageModule','myapp.services']

app.controller "MyCtrl", ($scope, steam) ->
  steam.get("techgrind.events/order-by-date").then (data) ->
    console.log("we have data!!!")
    console.log(JSON.stringify(data['event-list']))
    console.log(JSON.stringify(data))
    $scope.events = data['event-list']
    console.log(JSON.stringify($scope.events))
