class window.OwnMap
    constructor: (markermgr) ->
        console.log 'OwnMap::constructor(%o)', markermgr

        @markermgr = markermgr

        @my_markers = {}
        @trackerIDs = []
        @live_view = false

        show_markers = Cookies.get 'show_markers'
        console.log 'initMap: show_markers = %o', show_markers

        @marker_start_icons = {}
        @marker_finish_icons = {}
        @marker_icons = {}

        colours = ['blue', 'red', 'orange', 'green', 'purple', 'cadetblue', 'darkred', 'darkgreen', 'darkpurple']
        for fg, i in colours
            bg1 = if fg is 'green' then 'darkgreen' else 'green'
            bg2 = if fg is 'red' then 'darkred' else 'red'
            @marker_start_icons[i] = L.AwesomeMarkers.icon({icon: 'play', prefix: 'fa', markerColor: fg, iconColor: bg1 })
            @marker_finish_icons[i] = L.AwesomeMarkers.icon({icon: 'stop', prefix: 'fa', markerColor: fg, iconColor: bg2 })
            @marker_icons[i] = L.AwesomeMarkers.icon({icon: 'user', prefix: 'fa', markerColor: fg })

        # set checkbox
        if show_markers is '1'
            # hideMarkers();
            # $('#show_markers').prop('checked',false);
            $('#show_markers').removeClass('btn-default').addClass('btn-primary').addClass('active')

        layers =
            'OpenStreetMap': L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            'OSM/DE': L.tileLayer 'https://{s}.tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                attribution: '© <a href="https://www.openstreetmap.de/faq.html#lizenz">OpenStreetMap</a>'
            'OpenTopoMap': L.tileLayer 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                maxZoom: 17
                attribution: 'Map data: © <a href="https://openstreetmap.org/copyright">OpenStreetMap</a>-Mitwirkende, SRTM | Map tiles: © <a href="http://opentopomap.org/">OpenTopoMap</a> (<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a>)'
            'Hike&amp;Bike': L.tileLayer 'http://{s}.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            'Stamen Toner': L.tileLayer 'http://{s}.tile.stamen.com/toner/{z}/{x}/{y}.png',
                subdomains: 'abcd'
                detectRetina: true
                attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org">OpenStreetMap</a>, under <a href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>.'
            'Stamen Watercolor': L.tileLayer 'http://{s}.tile.stamen.com/watercolor/{z}/{x}/{y}.jpg',
                subdomains: 'abcd'
                detectRetina: true
                attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org">OpenStreetMap</a>, under <a href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>.'
            'TopPlusOpen': L.tileLayer 'http://sgx.geodatenzentrum.de/wmts_topplus_web_open/tile/1.0.0/web/default/WEBMERCATOR/{z}/{y}/{x}.png',
                detectRetina: true
                attribution: '© <a href="http://www.bkg.bund.de/">Bundesamt für Kartographie und Geodäsie</a> 2018, <a href="http://sg.geodatenzentrum.de/web_public/Datenquellen_TopPlus_Open.pdf">Datenquellen</a>'
            'ESRI Satellite': L.tileLayer 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                detectRetina: true
                attribution: 'Tiles © Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'

        overlays =
            'Hillshades': L.tileLayer 'http://{s}.tiles.wmflabs.org/hillshading/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c']

        @mymap = L.map 'mapid',
            center: [52.52, 13.44]
            zoom: 11
            layers: [layers['OpenStreetMap']]

        L.control.layers(layers, overlays).addTo @mymap
        @fetchMarkers()

    fetchMarkers: ->
        console.log 'OwnMap::fetchMarkers()'
        @markermgr.fetchMarkers window.dateFrom, window.dateTo, window.accuracy
            .done (data) =>
                console.log '### data=%o', data
                jsonMarkers = data
                window.updateTrackerIDs()
                if @drawMap jsonMarkers
                    $('#mapid').css 'filter', 'blur(0px)'

    eraseMap: ->
        console.log 'OwnMap::eraseMap()'
        for own _tid, markers of @my_markers
            if _tid of @polylines
                @polylines[_tid].removeFrom @mymap
            for own _index2, _marker of markers
                _marker.remove()
        return true

    drawMap: ->
        console.log 'OwnMap::drawMap()'
        if @map_drawn
            @markermgr.removeMarkersFrom @mymap

        @markermgr.addMarkersTo @mymap

        # TODO: Handle polyline
        # TODO: Zoom to bounds

        # LEGACY CODE:
        tid_markers = @markermgr.getMarkers()
        trackerIDs  = @markermgr.getTrackerIds()
        try
            console.log 'drawMap: tid_markers = %o', tid_markers

            # vars for map bounding
            max_lat = -1000
            min_lat = 1000
            max_lon = -1000
            min_lon = 1000

            if @map_drawn
                @eraseMap()

            nb_markers = 0   # global markers counter

            @my_markers = {}
            my_latlngs = []
            @polylines = []

            if trackerIDs.length is 0
                console.error 'drawMap: No location data found for any trackerID!'
                alert 'No location data found for any trackerID!'

            for tid, j in trackerIDs
                console.log 'Handling trackers: %o, %o', tid, j
                my_latlngs[tid] = []
                @my_markers[tid] = []

                if window.trackerID is 'all' or window.trackerID is tid
                    markers = tid_markers[tid]
                    console.log 'Markers set is: %o', markers
                    if markers.length is 0
                        console.error 'drawMap: No location data for trackerID "%o" found!', window.trackerID
                        alert "No location data for trackerID '#{window.trackerID}' found!"

                    for marker, i in markers
                        nb_markers += 1
                        # prepare popup HTML code for marker
                        popupString = @markermgr.getMarkerTooltip i, marker
                            
                        # create leaflet marker object with custom icon based on tid index in array
                        if i == 0
                            # first marker
                            my_marker = L.marker( [markers[i].latitude, markers[i].longitude], {icon: @marker_start_icons[j]} ).bindPopup(popupString)
                        else if i == markers.length-1
                            # last marker
                            my_marker = L.marker( [markers[i].latitude, markers[i].longitude], {icon: @marker_finish_icons[j]} ).bindPopup(popupString)
                        else
                            # all other markers
                            my_marker = L.marker( [markers[i].latitude, markers[i].longitude], {icon: @marker_icons[j]} ).bindPopup(popupString)

                        if max_lat < markers[i].latitude then max_lat = markers[i].latitude
                        if min_lat > markers[i].latitude then min_lat = markers[i].latitude
                        if max_lon < markers[i].longitude then max_lon = markers[i].longitude
                        if min_lon > markers[i].longitude then min_lon = markers[i].longitude
                        
                        # add marker to map only if cookie 'show_markers' says to or if 1st or last marker
                        if show_markers != '0' or i == 0 or i == markers.length-1
                            my_marker.addTo @mymap
                        
                        # collect all markers location to prepare drawing track, per trackerID
                        my_latlngs[tid][i] = [markers[i].latitude, markers[i].longitude, i]
                        
                        
                        # todo : onmouseover marker, display accuracy radius
                        # if(markers[i].acc > 0){
                        
                        #if(i+1 == markers.length && markers[i].acc > 0){
                        #        var circle = L.circle(my_latlngs[i], {
                        #        opacity: 0.2,
                        #        radius: markers[i].acc
                        #    }).addTo(mymap);
                        #}
                        
                        # array of all markers for display / hide markers + initial auto zoom scale
                        my_marker.epoch = markers[i].epoch   # needed for geocoding/deleting
                        @my_markers[tid][i] = my_marker

                    # var polylines[tid] = L.polyline(my_latlngs[tid]).addTo(mymap);
                    @polylines[tid] = L.hotline(my_latlngs[tid],
                        min: 0
                        max: markers.length
                        palette:
                            0.0: 'green'
                            0.5: 'yellow'
                            1.0: 'red'
                        weight: 4
                        outlineColor: '#000000'
                        outlineWidth: 0.5
                    ).addTo @mymap

            # save default zoom scale
            @setDefaultZoom()
            # auto zoom scale based on all markers location
            @mymap.fitBounds [
                [min_lat, min_lon],
                [max_lat, max_lon]
            ]
            # set map drawn flag
            @map_drawn = true
            return true
        catch err
            console.error 'drawMap: %o', err
            alert err.message
            @map_drawn = false
            return false

    setDefaultZoom: ->
        console.log 'OwnMap::setDefaultZoom()'
        setTimeout =>
            @default_zoom = @mymap.getZoom()
            @default_centre = @mymap.getCenter()
        , 2000

    showMarkers: ->
        console.log 'OwnMap::showMarkers()'
        for own _index, _tid of @trackerIDs
            if window.trackerID == _tid or window.trackerID == 'all'
                for own _index2, _marker of @my_markers[_tid]
                    # add marker to map except first & last (never removed)
                    if _index2 != 0 or _index2 != @my_markers[_tid].length
                        _marker.addTo @mymap
        return true

    hideMarkers: ->
        console.log 'OwnMap::hideMarkers()'
        for own _index, _tid of @trackerIDs
            if window.trackerID == _tid or window.trackerID == 'all'
                for own _index2, _marker of @my_markers[_tid]
                    # remove marker except first & last
                    if _index2 > 0 and _index2 < @my_markers[_tid].length-1
                        _marker.remove()
        return true

    resetZoom: ->
        console.log 'OwnMap::resetZoom()'
        @mymap.setView @default_centre, @default_zoom

    toggleLiveView: ->
        console.log 'OwnMap::toggleLiveView()'
        @live_view = !@live_view
        console.log 'Live view is now: %o', @live_view

        if @live_view
            @live_view_timer = setTimeout =>
                @fetchMarkers()
            , 3000
        else
            clearTimeout @live_view_timer
        return @live_view

    geodecodeMarker: (tid, i) ->
        console.log 'OwnMap::geodecodeMarker(%o, %o)', tid, i
        # ajax call to remove marker from backend
        $.ajax 
            url: 'rpc.php'
            data:
                'epoch': @my_markers[tid][i].epoch
                'action': 'geoDecode'
            type: 'get'
            dataType: 'json'
            success: (data, status) =>
                if data.status?
                    console.log 'geodecodeMarker: Status=%o, Data=%o', status, data
                    
                    # update marker data
                    $("#loc_#{tid}_#{i}").html "<a href='javascript:showBoundingBox(#{tid}, #{i});' title='Show location bounding box'>#{data.location}</a>"
                else
                    console.error 'geodecodeMarker: Status=%o, Data=%o', status, data
            error: (xhr, desc, err) ->
                console.error 'geodecodeMarker: XHR=%o, Error=%o, Details=%o', xhr, err, desc

    deleteMarker: (tid, i) ->
        console.log 'OwnMap::deleteMarker(%o, %o)', tid, i

        # ajax call to remove marker from backend
        $.ajax
            url: 'rpc.php'
            data:
                'epoch': @my_markers[tid][i].epoch
                'action': 'deleteMarker'
            type: 'get'
            dataType: 'json'
            success: (data, status) =>
                if data.status
                    @fetchMarkers()
                else
                    console.error 'deleteMarker: Status=%o Data=%o', status, data
            error: (xhr, desc, err) ->
                console.error 'deleteMarker: XHR=%o, Error=%o, Details=%o', xhr, err, desc
