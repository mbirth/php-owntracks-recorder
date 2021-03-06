class window.OwnMap
    constructor: (markermgr) ->
        console.log 'OwnMap::constructor(%o)', markermgr

        @markermgr = markermgr
        @markermgr.startstop_only = Cookies.get('show_markers') is '0'
        selected_tid = Cookies.get 'trackerID'
        if selected_tid? and selected_tid isnt ''
            console.log 'Setting marker filter to: %o', selected_tid
            @markermgr.setFilter [selected_tid]

        @map_drawn = false
        @live_view = false
        @live_view_timer = false

        apikey_tf = '?apikey=' + '00000000000000000000000000000000'

        # Taken from: https://wiki.openstreetmap.org/wiki/Tile_servers 
        layers =
            'OpenStreetMap': L.tileLayer 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            'OSM B&W': L.tileLayer 'http://{s}.tiles.wmflabs.org/bw-mapnik/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            'OSM No Labels': L.tileLayer 'http://{s}.tiles.wmflabs.org/osm-no-labels/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            'OSM/DE': L.tileLayer 'https://{s}.tile.openstreetmap.de/tiles/osmde/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                attribution: '© <a href="https://www.openstreetmap.de/faq.html#lizenz">OpenStreetMap</a>'
            'OSM/FR': L.tileLayer 'http://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
            'Carto Dark': L.tileLayer 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: 'abcd'
                attribution: 'Map tiles by <a href="https://carto.com/">Carto</a>, under CC BY 3.0. Data by OpenStreetMap, under ODbL.'
            'Carto Light': L.tileLayer 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}{r}.png',
                subdomains: 'abcd'
                attribution: 'Map tiles by <a href="https://carto.com/">Carto</a>, under CC BY 3.0. Data by OpenStreetMap, under ODbL.'
            'ESRI Satellite': L.tileLayer 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                detectRetina: true
                attribution: 'Tiles © Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
            'ESRI Streets': L.tileLayer 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                detectRetina: true
                attribution: 'Tiles © Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
            'Hike&amp;Bike': L.tileLayer 'http://{s}.tiles.wmflabs.org/hikebike/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
            'Humanitarian Map': L.tileLayer 'http://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: 'ab'
                detectRetina: true
                attribution: '<a href="https://wiki.openstreetmap.org/wiki/Humanitarian_map_style">Map tile info</a>'
            'MapSurfer': L.tileLayer 'https://korona.geog.uni-heidelberg.de/tiles/roads/x={x}&y={y}&z={z}',
                detectRetina: true
                attribution: '<a href="http://korona.geog.uni-heidelberg.de/contact.html">GIScience Heidelberg</a>'
            'OpenTopoMap': L.tileLayer 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                subdomains: 'abc'
                detectRetina: true
                maxZoom: 17
                attribution: 'Map data: © <a href="https://openstreetmap.org/copyright">OpenStreetMap</a>-Mitwirkende, SRTM | Map tiles: © <a href="http://opentopomap.org/">OpenTopoMap</a> (<a href="https://creativecommons.org/licenses/by-sa/3.0/">CC-BY-SA</a>)'
            'Stamen Toner': L.tileLayer 'http://{s}.tile.stamen.com/toner/{z}/{x}/{y}{r}.png',
                subdomains: 'abcd'
                attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org">OpenStreetMap</a>, under <a href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>.'
            'Stamen Watercolor': L.tileLayer 'http://{s}.tile.stamen.com/watercolor/{z}/{x}/{y}.jpg',
                subdomains: 'abcd'
                detectRetina: true
                attribution: 'Map tiles by <a href="http://stamen.com">Stamen Design</a>, under <a href="http://creativecommons.org/licenses/by/3.0">CC BY 3.0</a>. Data by <a href="http://openstreetmap.org">OpenStreetMap</a>, under <a href="http://creativecommons.org/licenses/by-sa/3.0">CC BY SA</a>.'
            'Thunderforest OpenCycleMap': L.tileLayer 'http://tile.thunderforest.com/cycle/{z}/{x}/{y}{r}.png' + apikey_tf,
                attribution: 'Map tiles by <a href="https://wiki.openstreetmap.org/wiki/OpenCycleMap">OpenCycleMap</a>'
            'Thunderforest Landscape': L.tileLayer 'http://tile.thunderforest.com/landscape/{z}/{x}/{y}{r}.png' + apikey_tf
            'Thunderforest Mobile Atlas': L.tileLayer 'http://tile.thunderforest.com/mobile-atlas/{z}/{x}/{y}{r}.png' + apikey_tf
            'Thunderforest Neighbourhood': L.tileLayer 'http://tile.thunderforest.com/neighbourhood/{z}/{x}/{y}{r}.png' + apikey_tf
            'Thunderforest Outdoors': L.tileLayer 'http://tile.thunderforest.com/outdoors/{z}/{x}/{y}{r}.png' + apikey_tf
            'Thunderforest Pioneer': L.tileLayer 'http://tile.thunderforest.com/pioneer/{z}/{x}/{y}{r}.png' + apikey_tf
            'Thunderforest Spinal': L.tileLayer 'http://tile.thunderforest.com/spinal-map/{z}/{x}/{y}{r}.png' + apikey_tf
            'Thunderforest Transport': L.tileLayer 'http://tile.thunderforest.com/transport/{z}/{x}/{y}{r}.png' + apikey_tf
            'Thunderforest Transport Dark': L.tileLayer 'http://tile.thunderforest.com/transport-dark/{z}/{x}/{y}{r}.png' + apikey_tf
            'TopPlusOpen': L.tileLayer 'http://sgx.geodatenzentrum.de/wmts_topplus_web_open/tile/1.0.0/web/default/WEBMERCATOR/{z}/{y}/{x}.png',
                detectRetina: true
                attribution: '© <a href="http://www.bkg.bund.de/">Bundesamt für Kartographie und Geodäsie</a> 2018, <a href="http://sg.geodatenzentrum.de/web_public/Datenquellen_TopPlus_Open.pdf">Datenquellen</a>'
            'Wikimedia': L.tileLayer 'https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}{r}.png',
                attribution: 'Map tiles by <a href="https://foundation.wikimedia.org/wiki/Maps_Terms_of_Use">Wikimedia Foundation</a>'

        overlays =
            'Hillshades': L.tileLayer 'http://{s}.tiles.wmflabs.org/hillshading/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c']
                detectRetina: true
            'OpenSeaMap': L.tileLayer 'http://tiles.openseamap.org/seamark/{z}/{x}/{y}.png',
                detectRetina: true
            'waymarkedtrails Cycling': L.tileLayer 'https://tile.waymarkedtrails.org/cycling/{z}/{x}/{y}.png',
                detectRetina: true
                attribution: 'Map tiles by <a href="https://wiki.openstreetmap.org/wiki/User:Lonvia">Sarah Hoffmann</a>'
            'waymarkedtrails Hiking': L.tileLayer 'https://tile.waymarkedtrails.org/hiking/{z}/{x}/{y}.png',
                detectRetina: true
                attribution: 'Map tiles by <a href="https://wiki.openstreetmap.org/wiki/User:Lonvia">Sarah Hoffmann</a>'
            'waymarkedtrails MTB': L.tileLayer 'https://tile.waymarkedtrails.org/mtb/{z}/{x}/{y}.png',
                detectRetina: true
                attribution: 'Map tiles by <a href="https://wiki.openstreetmap.org/wiki/User:Lonvia">Sarah Hoffmann</a>'
            'waymarkedtrails Skating': L.tileLayer 'https://tile.waymarkedtrails.org/skating/{z}/{x}/{y}.png',
                detectRetina: true
                attribution: 'Map tiles by <a href="https://wiki.openstreetmap.org/wiki/User:Lonvia">Sarah Hoffmann</a>'

        @mymap = L.map 'mapid',
            center: [52.52, 13.44]
            zoom: 11
            layers: [layers['OpenStreetMap']]

        L.control.layers(layers, overlays).addTo @mymap

        L.easyButton 'fa-map', (btn, map) =>
            @resetZoom()
        , 'Reset Zoom'
        .addTo @mymap

        btn_showhide = L.easyButton
            states: [{
                stateName: 'show-markers'
                icon: 'fa-map-marker-alt'
                title: 'Show Markers'
                onClick: (btn, map) =>
                    @showMarkers()
                    btn.state 'hide-markers'
                }, {
                stateName: 'hide-markers'
                icon: 'fa-map-marker-alt'
                title: 'Hide Markers'
                onClick: (btn, map) =>
                    @hideMarkers()
                    btn.state 'show-markers'
            }]
        if not @markermgr.startstop_only
            btn_showhide.state 'hide-markers'
        btn_showhide.addTo @mymap

        L.easyButton '<strong>gpx</strong>', (btn, map) =>
            @exportGpx()
        , 'Export GPX'
        .addTo @mymap

        @buttonPrev = L.easyButton
            states: [
                onClick: (btn, map) =>
                    window.goPrevious()
                title: 'Previous day'
                icon: 'fa-arrow-circle-left'
            ]
        @buttonToday = L.easyButton
            states: [
                onClick: (btn, map) =>
                    window.gotoDate()
                title: 'Today'
                icon: 'fa-hand-point-down'
            ]
        @buttonNext = L.easyButton
            states: [
                onClick: (btn, map) =>
                    window.goNext()
                title: 'Next day'
                icon: 'fa-arrow-circle-right'
            ]

        L.easyBar [@buttonPrev, @buttonToday, @buttonNext],
            position: 'bottomleft'
        .addTo @mymap

        @fetchMarkers()

    setLayerOpacity: (opacity) ->
        # https://gis.stackexchange.com/questions/122219/get-all-tilelayers-from-l-map-object-in-leaflet
        @mymap.eachLayer (layer) =>
            if layer instanceof L.TileLayer
                layer.options.opacity = opacity
                layer.redraw()

    fetchMarkers: ->
        console.log 'OwnMap::fetchMarkers()'
        @markermgr.fetchMarkers window.dateFrom, window.dateTo, window.accuracy
            .done (data) =>
                window.updateTrackerIDs()
                if @drawMap()
                    $('#mapid').css 'filter', 'blur(0px)'

    drawMap: (rezoom = true) ->
        console.log 'OwnMap::drawMap()'
        if @map_drawn
            @markermgr.removeMarkersFrom @mymap
            @markermgr.removeLinesFrom @mymap
            @map_drawn = false

        @markermgr.addMarkersTo @mymap
        @markermgr.addLinesTo @mymap

        if rezoom
            @resetZoom()

        @map_drawn = true

    setMarkerFilter: (tid) ->
        console.log 'OwnMap::setMarkerFilter(%o)', tid
        Cookies.set 'trackerID', tid
        if tid isnt ''
            @markermgr.setFilter [tid]
        else
            @markermgr.setFilter()
        @drawMap()

    showMarkers: ->
        console.log 'OwnMap::showMarkers()'
        @markermgr.startstop_only = false
        Cookies.set 'show_markers', 1, { expires: 365 }
        @drawMap false

    hideMarkers: ->
        console.log 'OwnMap::hideMarkers()'
        @markermgr.startstop_only = true
        Cookies.set 'show_markers', 0, { expires: 365 }
        @drawMap false

    resetZoom: ->
        console.log 'OwnMap::resetZoom()'
        # auto zoom scale based on all markers location
        @mymap.fitBounds @markermgr.getMarkerBounds()

    exportGpx: ->
        console.log 'OwnMap::exportGpx()'
        @markermgr.exportGpx window.dateFrom, window.dateTo, window.accuracy

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
