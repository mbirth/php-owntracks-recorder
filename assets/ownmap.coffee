class window.OwnMap
    constructor: (markermgr) ->
        console.log 'OwnMap::constructor(%o)', markermgr

        @markermgr = markermgr
        @map_drawn = false
        @default_zoom = 15
        @default_centre = [0, 0]

        @live_view = false
        @live_view_timer = false

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
                window.updateTrackerIDs()
                if @drawMap()
                    $('#mapid').css 'filter', 'blur(0px)'

    drawMap: ->
        console.log 'OwnMap::drawMap()'
        if @map_drawn
            @markermgr.removeMarkersFrom @mymap
            @markermgr.removeLinesFrom @mymap
            @map_drawn = false

        @markermgr.addMarkersTo @mymap
        @markermgr.addLinesTo @mymap

        # save default zoom scale
        @setDefaultZoom()
        # auto zoom scale based on all markers location
        @mymap.fitBounds @markermgr.getMarkerBounds()
        @map_drawn = true

    setDefaultZoom: ->
        console.log 'OwnMap::setDefaultZoom()'
        setTimeout =>
            @default_zoom = @mymap.getZoom()
            @default_centre = @mymap.getCenter()
        , 2000

    showMarkers: ->
        console.log 'OwnMap::showMarkers()'
        # TODO: Use MarkerMgr (needs to be implemented there first)

    hideMarkers: ->
        console.log 'OwnMap::hideMarkers()'
        # TODO: Use MarkerMgr (needs to be implemented there first)

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

    geodecodeMarker: (lid) ->
        console.log 'OwnMap::geodecodeMarker(%o)', lid
        # ajax call to remove marker from backend
        $.ajax 
            url: 'rpc.php'
            data:
                'lid': lid
                'action': 'geoDecode'
            type: 'get'
            dataType: 'json'
            success: (data, status) =>
                if data.status?
                    console.log 'geodecodeMarker: Status=%o, Data=%o', status, data
                    
                    # update marker data
                    $("#loc_#{lid}").html "<a href='javascript:showBoundingBox(#{lid});' title='Show location bounding box'>#{data.location}</a>"
                else
                    console.error 'geodecodeMarker: Status=%o, Data=%o', status, data
            error: (xhr, desc, err) ->
                console.error 'geodecodeMarker: XHR=%o, Error=%o, Details=%o', xhr, err, desc

    deleteMarker: (lid) ->
        console.log 'OwnMap::deleteMarker(%o)', lid

        # ajax call to remove marker from backend
        $.ajax
            url: 'rpc.php'
            data:
                'lid': lid
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
