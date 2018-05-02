class window.RpcClient
    constructor: (url) ->
        console.log 'RpcClient::constructor(%o)', url
        @url = url
        @markers = {}

    getMarkers: (dateFromYMD, dateToYMD, accuracy) ->
        console.log 'RpcClient::getMarkers(%o, %o, %o)', dateFromYMD, dateToYMD, accuracy
        params =
            'action': 'getMarkers'
            'dateFrom': dateFromYMD
            'dateTo': dateToYMD
            'accuracy': accuracy
            #'trackerID' : trackerID
            #'epoc': time()
        xhr = $.getJSON @url, params
        xhr.fail (xhr, status, error) ->
            console.error 'XHR error: xhr=%o status=%o error=%o', xhr, status, error
        return xhr
