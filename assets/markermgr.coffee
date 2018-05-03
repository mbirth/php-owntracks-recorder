class window.MarkerMgr
    constructor: (rpcclient) ->
        console.log 'MarkerMgr::constructor(%o)', rpcclient
        @rpcclient = rpcclient

    getMarkers: (dateFromYMD, dateToYMD, accuracy) ->
        console.log 'MarkerMgr::getMarkers(%o, %o, %o)', dateFromYMD, dateToYMD, accuracy
        @rpcclient.getMarkers dateFromYMD, dateToYMD, accuracy
            .done (data, status, xhr) =>
                console.log 'Got: data=%o status=%o xhr=%o', data, status, xhr
                if data.status? and data.status
                    @markers = data.markers
                else
                    console.error 'Marker result not okay.'
