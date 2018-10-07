class window.MarkerMgr
    constructor: (rpcclient) ->
        console.log 'MarkerMgr::constructor(%o)', rpcclient
        @rpcclient = rpcclient
        @startstop_only = false
        @markers = {}
        @markers_old = {}
        @dateFrom = null
        @dateTo = null
        @accuracy = null
        @markers_drawn = {}
        @lines_drawn = {}
        @filter_tids = []

    fetchMarkers: (dateFrom, dateTo, accuracy) ->
        console.log 'MarkerMgr::fetchMarkers(%o, %o, %o)', dateFrom, dateTo, accuracy
        # TODO: Use stored query values if parameters omitted
        return @rpcclient.getMarkers dateFrom, dateTo, accuracy
            .then (data) =>
                console.log 'MarkerMgr::fetchMarkers got: %o', data
                @markers_old = @markers
                @markers = data
                @dateFrom = dateFrom
                @dateTo = dateTo
                @accuracy = accuracy
                return data

    getTrackerIds: ->
        return Object.keys @markers

    getMarkers: ->
        console.log 'MarkerMgr::getMarkers()'
        console.log 'Active filter is: %o', @filter_tids
        result = {}
        for tid, tidmarkers of @markers
            if @filter_tids.length is 0 or tid in @filter_tids
                result[tid] = tidmarkers
        return result

    setFilter: (new_filter) ->
        console.log 'MarkerMgr::setFilter(%o)', new_filter
        if new_filter?
            @filter_tids = new_filter
        else
            @filter_tids = []

    getMarkerBounds: ->
        max_lat = -90
        min_lat = 90
        max_lon = -180
        min_lon = 180

        for tid, tidmarkers of @getMarkers()
            # TODO: Implement some way of filtering by tid
            for tidmarker, i in tidmarkers
                if max_lat < tidmarker.latitude then max_lat = tidmarker.latitude
                if min_lat > tidmarker.latitude then min_lat = tidmarker.latitude
                if max_lon < tidmarker.longitude then max_lon = tidmarker.longitude
                if min_lon > tidmarker.longitude then min_lon = tidmarker.longitude

        return [[min_lat, min_lon], [max_lat, max_lon]]

    getMarkerTooltip: (marker) ->
        #console.log 'MarkerMgr::getMarkerTooltip(%o)', marker
        trackerIDString = "<br/>TrackerID: #{marker.tracker_id} / #{marker.lid}"
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
            locationString = "<br/>Location: <a href=\"#\" onclick=\"showBoundingBox(#{marker.lid});\" title=\"Show location bounding box\">#{marker.display_name}</a>"
        else
            locationString = "<br/>Location: <span id=\"loc_#{marker.lid}\"><a href=\"#\" onclick=\"geodecodeMarker(#{marker.lid});\" title=\"Get location (geodecode)\">Get location</a></span>"
        
        removeString = "<br/><br/><a href=\"#\" onclick=\"deleteMarker(#{marker.lid});\">Delete marker</a>"
        
        # prepare popup HTML code for marker
        popupString = dateString + trackerIDString + accuracyString + headingString + velocityString + locationString + removeString
        return popupString

    getMarkerIcon: (tid, icon_is_first, icon_is_last) ->
        console.log 'MarkerMgr::getMarkerIcon(%o, %o, %o)', tid, icon_is_first, icon_is_last
        # TODO: make colour depending on tid?
        #colours = ['blue', 'red', 'orange', 'green', 'purple', 'cadetblue', 'darkred', 'darkgreen', 'darkpurple']
        #for fg, i in colours
        #    bg1 = if fg is 'green' then 'darkgreen' else 'green'
        #    bg2 = if fg is 'red' then 'darkred' else 'red'
        colour = 'blue'
        icon_type = 'user'
        icon_colour = 'white'
        if icon_is_first
            icon_type = 'flag'
            icon_colour = 'green'
        else if icon_is_last
            icon_type = 'flag-checkered'
            icon_colour = 'red'
        marker_icon = L.AwesomeMarkers.icon
            icon: icon_type
            prefix: 'fa'
            markerColor: colour
            iconColor: icon_colour
        return marker_icon

    addMarkersTo: (map) ->
        console.log 'MarkerMgr::addMarkersTo(%o)', map
        mapid = map.getContainer().id
        if not @markers_drawn[mapid]?
            @markers_drawn[mapid] = []
        for tid, tidmarkers of @getMarkers()
            # TODO: Implement some way of filtering by tid
            for tidmarker, i in tidmarkers
                tooltip_txt = @getMarkerTooltip tidmarker
                icon_is_first = i is 0
                icon_is_last = i+1 is tidmarkers.length
                if @startstop_only and not (icon_is_first or icon_is_last)
                    continue
                icon = @getMarkerIcon tid, icon_is_first, icon_is_last
                marker = L.marker [tidmarker.latitude, tidmarker.longitude], {icon: icon}
                .bindPopup tooltip_txt
                .addTo map
                @markers_drawn[mapid].push marker

    removeMarkersFrom: (map) ->
        console.log 'MarkerMgr::removeMarkersFrom(%o)', map
        mapid = map.getContainer().id
        if @markers_drawn[mapid]?
            while marker = @markers_drawn[mapid].shift()
                marker.remove()

    addLinesTo: (map) ->
        console.log 'MarkerMgr::addLinesTo(%o)', map
        mapid = map.getContainer().id
        if not @lines_drawn[mapid]?
            @lines_drawn[mapid] = []
        for tid, tidmarkers of @getMarkers()
            # TODO: Implement some way of filtering by tid
            line_track = []
            for tidmarker, i in tidmarkers
                line_track.push [tidmarker.latitude, tidmarker.longitude, i]

            line = L.hotline line_track,
                min: 0
                max: tidmarkers.length
                palette:
                    0.00: 'red'
                    0.17: 'gold'
                    0.33: 'yellow'
                    0.50: 'lime'
                    0.67: 'deepskyblue'
                    0.83: 'indigo'
                    1.00: 'violet'
                weight: 4
                outlineColor: '#000000'
                outlineWidth: 0.5
            .addTo map
            @lines_drawn[mapid].push line
        
    removeLinesFrom: (map) ->
        console.log 'MarkerMgr::removeLinesFrom(%o)', map
        mapid = map.getContainer().id
        if @lines_drawn[mapid]?
            while line = @lines_drawn[mapid].shift()
                line.remove()
