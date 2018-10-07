class window.RpcClient
    constructor: (url) ->
        console.log 'RpcClient::constructor(%o)', url
        @url = url
        @markers = {}

    getMarkers: (dateFrom, dateTo, accuracy) ->
        console.log 'RpcClient::getMarkers(%o, %o, %o)', dateFrom, dateTo, accuracy
        params =
            'action': 'getMarkers'
            'dateFrom': dateFrom
            'dateTo': dateTo
            'accuracy': accuracy
            #'trackerID' : trackerID
            #'epoc': time()
        xhr = $.getJSON @url, params
        return xhr
            .fail (xhr, status, error) ->
                console.error 'XHR error: xhr=%o status=%o error=%o', xhr, status, error
            .then (data) =>
                console.log 'RpcClient::getMarkers got: data=%o', data
                if data.status? and data.status
                    return data.markers
                else
                    console.error 'Marker result not okay.'
                    return $.Deferred().reject 'Marker result not okay.'
