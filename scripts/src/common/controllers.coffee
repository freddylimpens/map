module = angular.module('common.controllers', ['http-auth-interceptor', 'ngCookies'])

class LoginCtrl
        """
        Login a user
        """
        constructor: (@$scope, @$rootScope, @$http, @$cookies, @authService) ->
                # set authorization header if already logged in
                if @$cookies.username and @$cookies.key
                        console.debug("Already logged in.")
                        @$http.defaults.headers.common['Authorization'] = "ApiKey #{@$cookies.username}:#{@$cookies.key}"
                        @authService.loginConfirmed()
                @$scope.loginrequired = false

                # On login required
                @$scope.$on('event:auth-loginRequired', =>
                        @$scope.loginrequired = true
                        console.debug("Login required")
                )

                # On login successful
                @$scope.$on('event:auth-loginConfirmed', =>
                        console.debug("Login OK")
                        @$scope.loginrequired = false
                )

                # Add methods to scope
                @$scope.submit = this.submit

        submit: =>
                console.debug('submitting login like a mofo')
                console.debug("#{@$rootScope.CONFIG.REST_URI}account/v0/user/login/")
                @$http.post("http://carpe.local:8000/account/v0/user/login/", JSON.stringify( # XXX HARDCODED
                        username: @$scope.username
                        password: @$scope.password
                )).success((data) =>
                        @$cookies.username = data.username
                        @$cookies.key = data.key
                        @$http.defaults.headers.common['Authorization'] = "ApiKey #{data.username}:#{data.key}"
                        @authService.loginConfirmed()
                ).error((data) =>
                        console.debug("LoginController submit error: #{data.reason}")
                        @$scope.errorMsg = data.reason
                )

LoginCtrl.$inject = ['$scope', '$rootScope', "$http", "$cookies", "authService"]

module.controller("LoginCtrl", LoginCtrl)