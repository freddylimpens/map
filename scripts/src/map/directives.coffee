# -*- tab-width: 4 -*-
module = angular.module("leaflet-directive", [])

class LeafletController
    constructor: (@$scope) ->
        @$scope.marker_instances = []

    addMarker: (lat, lng, options) =>
        marker = new L.marker([lat, lng], options).addTo(@$scope.map)

        return marker

    removeMarker: (aMarker) =>
        @$scope.map.removeLayer(aMarker)


module.controller("LeafletController", ['$scope', LeafletController])

module.directive("leaflet", ["$http", "$log", "$location", ($http, $log, $location) ->
    return {
        restrict: "E"
        replace: true
        transclude: true
        scope:
            center: "=center"
            tilelayer: "=tilelayer"
            path: "=path"
            maxZoom: "@maxzoom"

        template: '<div class="angular-leaflet-map"><div ng-transclude></div></div>'

        controller: 'LeafletController'

        link: ($scope, element, attrs, ctrl) ->
            $el = element[0]

            $scope.map = new L.Map($el,
                zoomControl: true
                zoomAnimation: true
                # crs: L.CRS.EPSG4326
            )

            # Change callback
            $scope.$watch("center", ((center, oldValue) ->
                    console.debug("map center changed")
                    $scope.map.setView([center.lat, center.lng], center.zoom)
                ), true
            )

            # Center
            if not attrs.center
                console.debug("setting default center")
                $scope.map.setView([0, 0], 1)

            # On "get_center" signal
            $scope.$on('map.get_center', (event, callback) =>
                center = $scope.map.getCenter()
                zoom = $scope.map.getZoom()
                callback(center, zoom)
            )

            maxZoom = $scope.maxZoom or 12

            # Tile layers. XXX Should be a sub directive?
            $scope.$watch("tilelayer", (layer, oldLayer) =>
                # Remove current layers
                $scope.map.eachLayer((layer) =>
                    console.debug("removed layer #{layer._url}")
                    $scope.map.removeLayer(layer)
                )

                # Add new ones
                if layer
                    console.debug("installing new layer #{layer.url_template}")
                    L.tileLayer(layer.url_template, layer.attrs).addTo($scope.map)
            , true
            )




            """
            # Manage map center events
            if attrs.center and $scope.center
              if $scope.center.lat and $scope.center.lng and $scope.center.zoom
                map.setView(new L.LatLng($scope.center.lat, $scope.center.lng), $scope.center.zoom)
              else if $scope.center.autoDiscover is true
                map.locate(
                  setView: true
                  maxZoom: maxZoom
                )

              map.on("dragend", (e) ->
                $scope.$apply((s) ->
                  s.center.lat = map.getCenter().lat
                  s.center.lng = map.getCenter().lng
                )
              )

              # Zoom
              map.on("zoomend", (e) ->
                $scope.$apply((s) ->
                  s.center.zoom = map.getZoom()
                )
              )



                $scope.$watch("markers." + mkey + ".draggable", (newValue, oldValue) ->
                  if newValue is false
                    marker.dragging.disable()
                  else if newValue is true
                    marker.dragging.enable()
                )


            if attrs.path
              polyline = new L.Polyline([],
                weight: 10
                opacity: 1
              )
              map.addLayer(polyline)
              $scope.$watch("path.latlngs", ((latlngs) ->
                idx = 0
                length = latlngs.length

                while idx < length
                  if latlngs[idx] is `undefined` or latlngs[idx].lat is `undefined` or latlngs[idx].lng is `undefined`
                    $log.warn("Bad path point inn the $scope.path array ")
                    latlngs.splice(idx, 1)
                  idx++
                polyline.setLatLngs(latlngs)
              ), true
              )

              $scope.$watch("path.weight", ((weight) ->
                polyline.setStyle(weight: weight)
              ), true
              )

              $scope.$watch("path.color", ((color) ->
                polyline.setStyle(color: color)
              ), true
              )
            """
            null
    }
])


module.directive("leafletMarker", ($timeout) ->
    return {
        restrict: 'E'
        require: '^leaflet'

        transclude: true
        replace: true
        template: '<div ng-transclude></div>'

        scope:
            marker: "="

        link: ($scope, $elem, attrs, ctrl) ->
            marker_instance = ctrl.addMarker($scope.marker.lat, $scope.marker.lng, $scope.marker.options)
            $scope.marker.instance = marker_instance
            marker_instance.getLatLng()

            # Marker lat/lng changes
            $scope.$watch("marker.lat", (newValue, oldValue) ->
                if $scope.marker.dragging or not newValue
                    return
                $scope.marker.instance.setLatLng(new L.LatLng(newValue, $scope.marker.instance.getLatLng().lng))
            )

            $scope.$watch("marker.lng", (newValue, oldValue) ->
                if $scope.marker.dragging or not newValue
                    return
                $scope.marker.instance.setLatLng(new L.LatLng($scope.marker.instance.getLatLng().lat, newValue))
            )


            # Dragging
            $scope.marker.instance.on("dragstart", (e) ->
                $scope.marker.dragging = true
            )

            $scope.marker.instance.on("drag", (e) ->
                $scope.$apply((s) ->
                    $scope.marker.lat = $scope.marker.instance.getLatLng().lat
                    $scope.marker.lng = $scope.marker.instance.getLatLng().lng
                )
            )

            $scope.marker.instance.on("dragend", (e) ->
                  $scope.marker.dragging = false
            )


            $scope.$on('$destroy', ->
                ctrl.removeMarker($scope.marker.instance)
            )
    }
)

module.directive("leafletPopup", ($timeout) ->
    return {
        restrict: 'CA'
        replace: false

        link: ($scope, $elem, attrs, ctrl) ->
            # Wait for dom to render
            $timeout(->
                $scope.marker.instance.bindPopup($($elem).html())
            , 0)

    }
)