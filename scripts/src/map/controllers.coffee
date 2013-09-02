module = angular.module('map.controllers', ['imageupload', 'restangular'])

class MapDetailCtrl
        """
        Base controller for interacting with a map
        """
        constructor: (@$scope, @$rootScope, @$stateParams, @$location, @MapService, @geolocation) ->
                @$scope.MapService = @MapService
                @$scope.$stateParams = @$stateParams

                # Load map once the page has loaded
                console.debug("loading map...")
                if @$stateParams.slug
                        @MapService.load(@$stateParams.slug, @$scope, (map) =>
                                console.debug("map loaded...")
                                @$rootScope.page_title = map.name
                        )

                @$scope.goMarkerNew = this.goMarkerNew
                @$scope.goHome = this.goHome
                @$scope.goMarkerDetail = this.goMarkerDetail

        goHome: =>
                @$location.url("/#{@$stateParams.slug}")

        goMarkerNew: =>
                @$location.url("/#{@$stateParams.slug}/marker/new")

        goMarkerDetail: =>
                console.debug("go!")
                @$location.url("/#{@$stateParams.slug}/marker/#{id}")


class MapNewCtrl
        """
        Create a new map
        """
        constructor: (@$scope, @$location, @cookies, @Restangular) ->
                @$scope.form =
                        name: ''
                        center:
                                coordinates: [0, 0]
                                type: 'Point'
                        tile_layers: [
                                {pk: 1}
                        ]

                @$scope.create = this.create

                @$scope.$location = $location

                if @cookies.username
                        @$scope.username = @cookies.username

        create: =>
                """
                Create a new map and redirect to the newly created map url
                """
                console.debug("creating map #{@$scope.form.name}")
                @Restangular.all('scout/map').post(@$scope.form).then((map) =>
                        @$location.url("/#{map.slug}")
                )

class MapMarkerDetailCtrl
        """
        Show the full page of a given Marker
        """
        constructor: (@$scope, @$routeParams, @Restangular) ->
                @$scope.isLoading = true

                @Restangular.one('scout/marker', @$routeParams.markerId).get().then((marker) =>
                        console.debug("marker loaded")
                        @$scope.marker = angular.copy(marker)
                        @$scope.isLoading = false
                )


class MapMarkerNewCtrl
        """
        Wizard to create a new marker
        """
        constructor: (@$scope, @$rootScope, @debounce, @$state, @$location, @MapService, @Restangular, @geolocation) ->
                width = 320
                height = 240

                video = document.querySelector("#video")
                """
                video.addEventListener("canplay", ((ev) ->
                         unless streaming
                                 height = video.videoHeight / (video.videoWidth / width)
                                 video.setAttribute("width", width)
                                 video.setAttribute("height", height)
                                 canvas.setAttribute("width", width)
                                 canvas.setAttribute("height", height)
                                 streaming = true
                         ),
                false)
                """

                # Load marker categories
                @$scope.is_marker_categories_loaded = false
                @Restangular.all("scout/marker_category").getList().then((categories) =>
                        @$scope.marker_categories = angular.copy(categories)
                        @$scope.is_marker_categories_loaded = true
                )

                @$scope.uploads = {}

                # The new marker we'll submit if everything is OK
                @$scope.marker = {}
                @$scope.marker.position =
                        coordinates: null
                        type: "Point"

                # Preview the next marker
                @$scope.marker_preview =
                        lat: @MapService.center.lat
                        lng: @MapService.center.lng
                        options:
                                draggable: true
                                icon: L.icon(
                                        iconUrl: '/images/poi_localisation.png'
                                        shadowUrl: null,
                                        iconSize: [65, 75]
                                        iconAnchor: [4, 37]
                                )

                @MapService.addMarker('marker_preview', @$scope.marker_preview)


                # Geolocation
                # this.geolocateMarker()

                # Wizard Steps
                @$scope.wizard =
                    step: 1

                @$scope.captureInProgress = false
                @$scope.previewInProgress = false

                # add functions and variable to scope
                @$scope.takePicture = this.takePicture
                @$scope.skipPicture  = this.skipPicture
                @$scope.grabCamera = this.grabCamera
                @$scope.cancelGrabCamera = this.cancelGrabCamera
                @$scope.submitForm = this.submitForm
                @$scope.pictureDelete = this.pictureDelete
                @$scope.geolocateMarker = this.geolocateMarker
                @$scope.lookupAddress = this.lookupAddress

                # Use debounce to prevent multiple calls
                @$scope.on_marker_preview_moved = @debounce(this.on_marker_preview_moved, 2)

                # Cursor move callback
                @$scope.$watch('marker_preview.lat + marker_preview.lng', =>
                        @$scope.on_marker_preview_moved()
                )

                # @$rootScope.page_title = "#{@MapService.map.name} | Ajouter un POI"


        submitForm: =>
                """
                Submit the form to create a new point
                """
                # XXX Hacky, hardcoded
                console.debug(@MapService)
                console.debug(@MapService.getCurrentLayer())
                @$scope.marker.tile_layer = @MapService.getCurrentLayer().uri

                # Prepare file upload
                if @$scope.uploads.picture
                        console.debug(@$scope.uploads.picture)
                        @$scope.marker.picture =
                                name: @$scope.uploads.picture.file.name
                                file: @$scope.uploads.picture.dataURL.replace(/^data:image\/(png|jpg|jpeg);base64,/, "")
                                content_type: @$scope.uploads.picture.file.type

                # Use 'pk' for category
                @$scope.marker.category = {'pk': @$scope.marker.category}

                # Now save the marker
                console.debug("saving...")
                console.debug(@$scope.marker)
                @Restangular.all('scout/marker').post(@$scope.marker).then((marker) =>
                        console.debug("new marker saved")

                        # Delete temp marker
                        @MapService.removeMarker('marker_preview')

                        # Create new marker
                        @MapService.addMarker(marker.id,
                                lat: marker.position.coordinates[0]
                                lng: marker.position.coordinates[1]
                                data: angular.copy(marker)
                        )

                        # Show the newly created marker
                        @$state.go('map.marker_detail', {markerId: marker.id})
                )


        skipPicture: =>
                """
                Button callback for 'Skip adding picture'
                """
                @$scope.captureInProgress = false
                @$scope.previewInProgress = false

        pictureDelete: =>
                """
                Callback when one decide to delete the uploaded picture
                """
                @$scope.marker.picture = null
                @$scope.uploads.picture = null
                @$scope.previewInProgress = false

        grabCamera: =>
                """
                Setup and grab the camera in a canvas
                """
                console.debug("Initializing webcam...")

                video = document.querySelector("#video")
                canvas = document.querySelector("#canvas")

                navigator.getMedia = (navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia)

                navigator.getMedia(
                        video: true
                        audio: false
                        , ((stream) =>
                                if navigator.mozGetUserMedia
                                        video.mozSrcObject = stream
                                else
                                        vendorURL = window.URL or window.webkitURL
                                        video.src = vendorURL.createObjectURL(stream)
                                video.play()
                                console.debug("Webcam grab in progress...")
                                @$scope.captureInProgress = true
                                @$scope.$apply()
                        ), (err) =>
                                console.log("An error occured! " + err)
                )



        cancelGrabCamera: =>
                """
                Release handle on camera
                """
                console.debug('Disabling camera...')
                video = document.querySelector("#video")
                video.src = ""
                @$scope.captureInProgress = false

        takePicture: =>
                width = 320
                height = 240

                canvas.width = width
                canvas.height = height
                canvas.getContext("2d").drawImage(video, 0, 0, width, height)
                data = canvas.toDataURL("image/jpg")

                photo = document.querySelector("#selected-photo")
                photo.setAttribute("src", data)

                video = document.querySelector("#video")
                video.src = ""

                @$scope.captureInProgress = false
                @$scope.previewInProgress = true


        on_marker_preview_moved: =>
                """
                When the marker was moved, update position and geocode
                """
                if (not @$scope.marker_preview.lat) or (not @$scope.marker_preview.lng)
                        return

                # Update marker position
                @$scope.marker.position.coordinates = [@$scope.marker_preview.lat, @$scope.marker_preview.lng]
                console.debug("pos set @#{@$scope.marker.position.coordinates}")

                # Resolve lat/lng to a human readable address
                pro = @geolocation.resolveLatLng(@$scope.marker_preview.lat, @$scope.marker_preview.lng).then((address) =>
                        console.debug("Found address match: #{address.formatted_address}")
                        @$scope.marker.address = angular.copy(address.formatted_address)
                )


        geolocateMarker: =>
                console.debug("Getting user position...")
                p = @geolocation.position().then((pos) =>
                        console.debug("Resolving #{pos.coords.latitude}")
                        @$scope.marker_preview.lat = pos.coords.latitude
                        @$scope.marker_preview.lng = pos.coords.longitude

                        # Focus on new location
                        @MapService.center =
                                lat: @$scope.marker_preview.lat
                                lng: @$scope.marker_preview.lng
                                zoom: 20

                )

        lookupAddress: =>
                """
                Given an address, find lat/lng
                """
                console.debug("looking up #{@$scope.marker.position.address}")
                pos_promise = @geolocation.lookupAddress(@$scope.marker.address).then((coords)=>
                        console.debug("Found pos #{coords}")

                        # move preview marker
                        @$scope.marker_preview.lat = coords[0]
                        @$scope.marker_preview.lng = coords[1]

                        # Focus on new position
                        @MapService.center =
                                lat: @$scope.marker_preview.lat
                                lng: @$scope.marker_preview.lng
                                zoom: 15

                )


# Controller declarations
module.controller("MapDetailCtrl", ['$scope', '$rootScope', '$stateParams', '$location', 'MapService', 'geolocation', MapDetailCtrl])
module.controller("MapNewCtrl", ['$scope', '$location', '$cookies', 'Restangular', MapNewCtrl])
module.controller("MapMarkerDetailCtrl", ['$scope', '$stateParams', 'Restangular', MapMarkerDetailCtrl])
module.controller("MapMarkerNewCtrl", ['$scope', '$rootScope', 'debounce', '$state', '$location', 'MapService', 'Restangular', 'geolocation', MapMarkerNewCtrl])
