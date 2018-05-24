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

    getTrackerIds: ->
        return Object.keys @markers

    getMarkers: ->
        return @markers

    getMarkerBounds: ->
        pass

    getMarkerTooltip: (mid, marker) ->
        trackerIDString = "<br/>TrackerID: #{marker.tracker_id} / #{mid}"
        dateString = marker.dt
        if marker.epoch != 0
            newDate = new Date()
            newDate.setTime marker.epoch * 1000
            dateString = newDate.toLocaleString()
        
        accuracyString = "<br/>Accuracy: #{marker.accuracy} m"
        headingString = if marker.heading? then "<br/>Heading: #{marker.heading}°" else ''
        velocityString = if marker.velocity? then "<br/>Velocity: #{marker.velocity} km/h" else ''
        locationString = ''
        if marker.display_name?
            locationString = "<br/>Location: <a href=\"#\" onclick=\"showBoundingBox('#{marker.tracker_id}', #{mid});\" title=\"Show location bounding box\">#{marker.display_name}</a>"
        else
            locationString = "<br/>Location: <span id=\"loc_#{marker.tracker_id}_#{mid}\"><a href=\"#\" onclick=\"geodecodeMarker('#{marker.tracker_id}', #{mid});\" title=\"Get location (geodecode)\">Get location</a></span>"
        
        removeString = "<br/><br/><a href=\"#\" onclick=\"deleteMarker('#{marker.tracker_id}', #{mid});\">Delete marker</a>"
        
        # prepare popup HTML code for marker
        popupString = dateString + trackerIDString + accuracyString + headingString + velocityString + locationString + removeString
        return popupString

    addMarkersTo: (map) ->
        console.log 'MarkerMgr::addMarkersTo(%o)', map
        mapid = map.getContainer().id
        for tid, tidmarkers of @markers
            # TODO: Implement some way of filtering by tid
            for i, tidmarker of tidmarkers
                tooltip_txt = @getMarkerTooltip i, tidmarker

    removeMarkersFrom: (map) ->
        console.log 'MarkerMgr::removeMarkersFrom(%o)', map
        mapid = map.getContainer().id
