class window.MarkerMgr
    constructor: (rpcclient) ->
        console.log 'MarkerMgr::constructor(%o)', rpcclient
        @rpcclient = rpcclient
        @markers = {}
        @markers_old = {}
        @dateFrom = null
        @dateTo = null
        @accuracy = null

    fetchMarkers: (dateFromYMD, dateToYMD, accuracy) ->
        console.log 'MarkerMgr::fetchMarkers(%o, %o, %o)', dateFromYMD, dateToYMD, accuracy
        # TODO: Use stored query values if parameters omitted
        return @rpcclient.getMarkers dateFromYMD, dateToYMD, accuracy
            .then (data) =>
                console.log 'MarkerMgr::fetchMarkers got: %o', data
                @markers_old = @markers
                @markers = data
                @dateFrom = dateFromYMD
                @dateTo = dateToYMD
                @accuracy = accuracy
                return data
