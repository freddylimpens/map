config = {
    templateBaseUrl: '/views/',
    REST_URI: 'http://localhost\\:8000/api/'
}

angular.module('map', ['map.controllers', 'map.services', 'leaflet-directive']);
angular.module('common', ['common.filters', 'common.controllers', 'common.services']);

app = angular.module('gup', ['common', 'map']);

// Config
app.constant('moduleTemplateBaseUrl', config.templateBaseUrl + 'map/');

app.config(['$locationProvider', '$routeProvider', 'moduleTemplateBaseUrl', function($locationProvider, $routeProvider, moduleTemplateBaseUrl){
					   $locationProvider.html5Mode(true);
					   $routeProvider
					       .when('/:slug', {
						     })
					       .when('/new', {
							 templateUrl: moduleTemplateBaseUrl + 'new.html',
							 controller: 'MapNewCtrl'
						     })
						.when('/marker/detail/:markerId', {
							  templateUrl: moduleTemplateBaseUrl + 'marker_detail.html',
							  controller: 'MapMarkerDetailCtrl'
						      })
						.when('/marker/new', {
							  templateUrl: moduleTemplateBaseUrl + 'marker_new.html',
							  controller: 'MapMarkerNewCtrl'
						      })
					       .otherwise({redirectTo: '/'});
				       }
				      ])

app.run(['$rootScope', function($rootScope) {
  $rootScope.MEDIA_URI = 'http://localhost:8000';
  $rootScope.CONFIG = config;
}]);
