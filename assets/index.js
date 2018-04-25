var map_drawn = false;
var show_markers;
var tid_markers; // markers collected from json
var my_marker;
var my_markers = [];
var my_latlngs = [];
var polylines = [];
var default_zoom;
var default_center;
var live_view = false;
var live_view_timer;

var marker_start_icons = [];
var marker_finish_icons = [];
var marker_icons = [];

function updateDateNav(_dateFrom, _dateTo){
    console.log("updateDateNav : INIT");
    
    if(typeof _dateFrom == "undefined") { _dateFrom = window.dateFrom; }
    if(typeof _dateTo == "undefined") { _dateTo = window.dateTo; }

    var diff = _dateTo.diff(_dateFrom, 'days');
    //if(dateTo.isSame(dateFrom)){ diff = diff+1; }
    
    var datePrevTo = moment(_dateFrom).subtract(1, 'days');;
    var datePrevFrom = moment(datePrevTo).subtract(diff, 'days');
    
    var dateNextFrom = moment(_dateTo).add(1, 'days');
    var dateNextTo = moment(dateNextFrom).add(diff, 'days');
    
    //disable Next button
    if(dateNextFrom.isAfter(moment())){
        $('#nextButton').addClass('disabled');
    }else{
        $('#nextButton').removeClass('disabled');
    }
    
    //disable today button
    if(dateNextFrom.isSame(moment())){
        $('#todayButton').addClass('disabled');
        $('#livemap_on').removeClass('disabled');
    }else{
        $('#todayButton').removeClass('disabled');
        $('#livemap_on').addClass('disabled');
    }
}

function gotoDate(_dateFrom, _dateTo, pushState){
    console.log("gotoDate : INIT");

    var _dateFrom = (typeof _dateFrom !== 'undefined') ? moment(_dateFrom) : moment();
    var _dateTo = (typeof _dateTo !== 'undefined') ? moment(_dateTo) : moment();
    var pushState = (typeof pushState !== 'undefined') ? pushState : true;

    window.dateFrom = _dateFrom;
    window.dateTo = _dateTo;
    
    $('#dateFrom').val(moment(window.dateFrom).format('YYYY-MM-DD'));
    $('#dateTo').val(moment(window.dateTo).format('YYYY-MM-DD'));

    //push selected dates in window.history stack
    if (pushState) {
        var data = {
            dateFrom: moment(window.dateFrom).format('YYYY-MM-DD'),
            dateTo: moment(window.dateTo).format('YYYY-MM-DD')
        };
        var url = window.location.pathname + '?dateFrom=' + data.dateFrom + '&dateTo=' + data.dateTo;
        console.log('Pushing state: %o with data: %o', url, data);
        window.history.pushState(data, '', url); 
    }
    updateDateNav();
    mapMarkers();
    return false;
}

function gotoAccuracy()
{
    console.log("gotoAccuracy : INIT");
    
    var _accuracy = parseInt($('#accuracy').val());

    if (_accuracy != window.accuracy) {
        
        Cookies.set('accuracy', _accuracy);
        console.log("Accuracy cookie = " + Cookies.get('accuracy'));
        
        //location.href='./?dateFrom='+moment(dateFrom).format('YYYY-MM-DD') + '&dateTo=' + moment(dateTo).format('YYYY-MM-DD') + '&accuracy=' + _accuracy + '&trackerID=' + trackerID;
        window.accuracy = _accuracy;
        mapMarkers();
    } else {
        $('#configCollapse').collapse('hide');
    }
    return false;
}

function changeTrackerID()
{
    console.log("changeTrackerID : INIT");
    
    var _trackerID = $('#trackerID_selector').val();
    
    if (_trackerID != window.trackerID) {
        Cookies.set('trackerID', _trackerID);
        console.log("changeTrackerID : INFO trackerID cookie = " + Cookies.get('trackerID'));
        
        window.trackerID = _trackerID;
        drawMap();
    } else {
        $('#configCollapse').collapse('hide');
    }
    return false;
}

function handlePopState(event)
{
    console.log("handlePopState : INIT");
    console.log(event);
    if (event.state) {
        return gotoDate(event.state.dateFrom, event.state.dateTo, false);
    }
}

function initUI() {
    console.log("initUI : INIT");

    var _GET = new URLSearchParams(window.location.search);

    window.dateFrom = moment();
    window.dateTo = moment();
    if (_GET.has('dateFrom')) {
        window.dateFrom = moment(_GET.get('dateFrom'));
    }
    if (_GET.has('dateTo')) {
        window.dateTo = moment(_GET.get('dateTo'));
    }
    $('#dateFrom').val(window.dateFrom.format('YYYY-MM-DD'));
    $('#dateTo').val(window.dateTo.format('YYYY-MM-DD'));

    //date params event handlers
    updateDateNav();

    $('.input-daterange').datepicker({
        format: 'yyyy-mm-dd',
        language: window.datepicker_language,
        endDate: '0d',
    });

    $('.input-daterange').datepicker().on('hide', function(e) {
        return gotoDate($('#dateFrom').val(), $('#dateTo').val());
    });

    //accuracy event handlers
    $('#accuracy').change(function(){
        gotoAccuracy();
    });
    $('#accuracySubmit').click(function(){
        gotoAccuracy();
    });

    $('#trackerID_selector').change(function(){
        changeTrackerID();
    });

    $('#configCollapse').on('show.bs.collapse', function (e) {
        $('#configButton').removeClass( "btn-default" ).addClass( "btn-primary" ).addClass( "active" );
    })
    $('#configCollapse').on('hide.bs.collapse', function (e) {
        $('#configButton').addClass( "btn-default" ).removeClass( "btn-primary" ).removeClass( "active" );
    })

    //setup history popupstate event handler
    window.onpopstate = handlePopState;
}

function initMap()
{
    console.log("initMap : INIT");

    window.trackerIDs = [];

    show_markers = Cookies.get('show_markers');
    console.log("initMap : INFO show_markers = " + show_markers);

    var colours = ['blue', 'red', 'orange', 'green', 'purple', 'cadetblue', 'darkred', 'darkgreen', 'darkpurple'];
    for (var i=0; i<=colours.length; i++) {
        var fg = colours[i];
        var bg1 = (fg=='green')?'darkgreen':'green';
        var bg2 = (fg=='red')?'darkgred':'red';
        marker_start_icons[i] = L.AwesomeMarkers.icon({icon: 'play', markerColor: fg, iconColor: bg1 });
        marker_finish_icons[i] = L.AwesomeMarkers.icon({icon: 'stop', markerColor: fg, iconColor: bg2 });
        marker_icons[i] = L.AwesomeMarkers.icon({icon: 'user', markerColor: fg });
    }

    //set checkbox
    if (show_markers == '1') {
        //hideMarkers();
        //$('#show_markers').prop('checked',false);
        $('#show_markers').removeClass( "btn-default" ).addClass( "btn-primary" ).addClass( "active" );
    }

    window.mymap = L.map('mapid').setView([52.52, 13.44], 11);

    L.tileLayer( 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
        subdomains: ['a','b','c']
    }).addTo(window.mymap);
    mapMarkers();
}

function setDefaultZoom()
{
    console.log("setDefaultZoom : INIT");
    setTimeout(function() {
        default_zoom = window.mymap.getZoom();
        default_center = window.mymap.getCenter();
    }, 2000);
}

function mapMarkers()
{
    console.log("mapMarkers : INIT");
    getMarkers();
}

function getMarkers()
{
    console.log("getMarkers : INIT");
    var params = {
        'action': 'getMarkers',
        'dateFrom': window.dateFrom.format('YYYY-MM-DD'),
        'dateTo': window.dateTo.format('YYYY-MM-DD'),
        'accuracy': window.accuracy
        //'trackerID' : trackerID,
        //'epoc': time(),
    };
    console.log('Params: %o', params);
    //ajax call to get list of markers
    $.ajax({
        url: 'rpc.php',
        data: params,
        type: 'GET',
        dataType: 'json',
        beforeSend: function(xhr)
        {
            $('#mapid').css('filter', 'blur(5px)');
        },
        success: function(data, status)
        {
            console.log('Answer: %o', data);
            if (data.status) {
                jsonMarkers = data.markers;
                updateTrackerIDs(jsonMarkers);
                if (drawMap(jsonMarkers)) { $('#mapid').css('filter', 'blur(0px)'); }
            } else {
                console.log("getMarkers : ERROR Status : " + status);
                console.log("getMarkers : ERROR Data : ");
                console.log(data);
            }
        },
        error: function(xhr, desc, err) {
            console.log(xhr);
            console.log("getMarkers : ERROR Details: " + desc + "\nError:" + err);
        }
    });
}

function updateTrackerIDs(_tid_markers)
{
    console.log("updateTrackerIDs : INIT");
    try {
        $("#trackerID_selector option[value!='" + window.default_trackerID + "']").each(function() {
            $(this).remove();
        });
        if (typeof _tid_markers != "undefined" && _tid_markers != null) {
            window.trackerIDs = Object.keys(_tid_markers); 
            $.each(window.trackerIDs, function( index, value ) {
                $('#trackerID_selector').append($('<option>', {
                    value: value,
                    text: value
                }));
            });
            $("#trackerID_selector").val(window.trackerID);
        } else {
            console.log("updateTrackerIDs : INFO no trackerID found in markers json");
            return ;
        }
    } catch(err) {
        console.log("updateTrackerIDs : ERROR " + err.message);
        alert(err.message);
    }
}

/**
* Draws a set of location tracks per tid in _tid_markers array
* @param {Array} _tid_markers 
*/
function drawMap(_tid_markers)
{
    console.log("drawMap : INIT - %o", _tid_markers);
    try {
        if (typeof _tid_markers == "undefined" && typeof tid_markers != "undefined" && tid_markers != null) {
            _tid_markers = tid_markers;
            console.log("drawMap : INFO null param given but global markers available !");
        } else if (typeof _tid_markers != "undefined" && _tid_markers != null) {
            tid_markers = _tid_markers;
            console.log("drawMap : INFO non null param given !");
        } else {
            console.log("drawMap : ERROR null param given and global markers not available !");
            alert('No location markers collected for selected dates and accuracy !');
            return;
        }
        
        console.log("drawMap : INFO tid_markers = ");
        console.log(tid_markers);

        //vars for map bounding
        max_lat = -1000;
        min_lat = 1000;
        max_lon = -1000;
        min_lon = 1000;

        if (map_drawn) { eraseMap(); }

        nb_markers=0; // global markers counter
        trackerIDs = Object.keys(_tid_markers);

        tid_markers = []; // markers collected from json
        my_markers = [];
        my_latlngs = [];
        polylines = [];

        if (trackerIDs.length > 0) {
            for ( j=0; j < trackerIDs.length; ++j ) {
                tid = trackerIDs[j];
                markers = _tid_markers[tid];
                my_latlngs[tid] = [];
                my_markers[tid] = [];

                if (window.trackerID == window.default_trackerID || window.trackerID == tid) {
                    var trackerIDString = '<br/>TrackerID : ' + tid;
                    if (markers.length > 0) {
                        for ( i=0; i < markers.length; ++i ) {
                            nb_markers = nb_markers+1;
                            dateString = markers[i].dt;
                            if (markers[i].epoch != 0) {
                                var newDate = new Date();
                                newDate.setTime(markers[i].epoch * 1000);
                                dateString = newDate.toLocaleString();
                            }
                            
                            var accuracyString = '<br/>Accuracy : ' + markers[i].accuracy + ' m';
                            var headingString = "";
                            var velocityString = "";
                            var locationString = "";
                            if (markers[i].heading != null) headingString = '<br/>Heading : ' + markers[i].heading + ' °';
                            if (markers[i].velocity != null) velocityString = '<br/>Velocity : ' + markers[i].velocity + ' km/h';
                            if (markers[i].display_name != null) {
                                locationString = "<br/>Location : <a href='javascript:showBoundingBox("+ i +");' title='Show location bounding box' >" + markers[i].display_name + '</a>';
                            } else {
                                locationString = "<br/>Location : <span id='loc_"+ i +"'><a href='javascript:geodecodeMarker("+ i +");' title='Get location (geodecode)'>Get location</a></span>";
                            }
                            
                            removeString = "<br/><br/><a href=\"javascript:deleteMarker('"+ tid +"', "+ i +");\">Delete marker</a>";
                            
                            //prepare popup HTML code for marker
                            popupString = dateString + trackerIDString + accuracyString + headingString + velocityString + locationString + removeString;
                                
                            //create leaflet market object with custom icon based on tid index in array
                            //first marker
                            if (i == 0) {
                                my_marker = L.marker( [markers[i].latitude, markers[i].longitude], {icon: marker_start_icons[j]} ).bindPopup(popupString);
                            //last marker
                            } else if (i == markers.length-1) {
                                my_marker = L.marker( [markers[i].latitude, markers[i].longitude], {icon: marker_finish_icons[j]} ).bindPopup(popupString);
                            //all other markers
                            } else {
                                my_marker = L.marker( [markers[i].latitude, markers[i].longitude], {icon: marker_icons[j]} ).bindPopup(popupString);
                            }

                            if (max_lat < markers[i].latitude) { max_lat = markers[i].latitude; }
                            if (min_lat > markers[i].latitude) { min_lat = markers[i].latitude; }
                            if (max_lon < markers[i].longitude) { max_lon = markers[i].longitude; }
                            if (min_lon > markers[i].longitude) { min_lon = markers[i].longitude; }
                            
                            //add marker to map only if cookie 'show_markers' says to or if 1st or last marker
                            if (show_markers != '0' || i == 0 || i == markers.length-1) {
                                my_marker.addTo(window.mymap);
                            }
                            /*
                            //default show popup for last marker of track
                            if(i == markers.length-1){
                                my_marker.addTo( mymap ).openPopup();;
                            }
                            */

                            //collect all markers location to prepare drawing track, per trackerID
                            my_latlngs[tid][i] = [markers[i].latitude, markers[i].longitude, i];
                            
                            
                            //todo : onmouseover marker, display accuracy radius
                            //if(markers[i].acc > 0){
                            /*
                            if(i+1 == markers.length && markers[i].acc > 0){
                                    var circle = L.circle(my_latlngs[i], {
                                    opacity: 0.2,
                                    radius: markers[i].acc
                                }).addTo(mymap);
                            }
                            */

                            //array of all markers for display / hide markers + initial auto zoom scale
                            my_markers[tid][i] = my_marker;
                            
                        }

                        //var polylines[tid] = L.polyline(my_latlngs[tid]).addTo(mymap);
                        polylines[tid] = L.hotline(my_latlngs[tid], {
                            min: 0,
                            max: markers.length,
                            palette: {
                                0.0: 'green',
                                0.5: 'yellow',
                                1.0: 'red'
                            },
                            weight: 4,
                            outlineColor: '#000000',
                            outlineWidth: 0.5
                        }).addTo(window.mymap);
                    } else {
                        console.log("drawMap : ERROR No location data for trackerID '" + window.trackerID + "' found !");
                        alert('No location data for trackerID \'' + window.trackerID + '\' found !');
                    }
                }
            }
        } else {
            console.log("drawMap : ERROR No location data found for any trackerID !");
            alert('No location data found for any trackerID !');
        }
        //save default zoom scale
        setDefaultZoom();
        //auto zoom scale based on all markers location
        window.mymap.fitBounds([
            [min_lat, min_lon],
            [max_lat, max_lon]
        ]);
        //set map drawn flag
        map_drawn = true;
        return true;
    } catch(err) {
        console.log("drawMap : ERROR " + err.message);
        alert( err.message );
        map_drawn = false;
        return false;
    }
}

function eraseMap()
{
    console.log("eraseMap : INIT");
    $.each(trackerIDs, function(_index, _tid) {
        if (_tid in polylines) { polylines[_tid].removeFrom(window.mymap); }
    });
    $.each(trackerIDs, function(_index, _tid) {
        $.each(my_markers[_tid], function(_index2, _marker){
            _marker.remove();
        });
    });
    return true;
}

function setLiveMap()
{
    console.log("setLiveMap : INIT");
    live_view = !live_view;

    if (live_view) {
        live_view_timer = setTimeout(getMarkers(), 3000);
        $('#livemap_on').removeClass( "btn-default" ).addClass( "btn-primary" ).addClass( "active" );
        
    } else {
        clearTimeout(live_view_timer);
        $('#livemap_on').addClass( "btn-default" ).removeClass( "btn-primary" ).removeClass( "active" );
    }
}

function showMarkers()
{
    console.log("showMarkers : INIT");
    $.each(trackerIDs, function(_index, _tid){
        if (window.trackerID == _tid || window.trackerID == window.default_trackerID) {
            $.each(my_markers[_tid], function(_index2, _marker){
                //add marker to map except first & last (never removed)
                if(_index2 != 0 || _index2 !=my_markers[_tid].length){
                    _marker.addTo(window.mymap);
                }
            });
        }
    });
    return true;
}

function hideMarkers()
{
    console.log("hideMarkers : INIT");
    $.each(trackerIDs, function(_index, _tid){
        if (window.trackerID == _tid || window.trackerID == window.default_trackerID) {
            $.each(my_markers[_tid], function(_index2, _marker){
                //remove marker except first & last
                if (_index2 > 0 && _index2 < my_markers[_tid].length-1) {
                    _marker.remove();
                }
            });
        }
    });
    return true;
}

function showHideMarkers()
{
    console.log("showHideMarkers : INIT");
    //$('#show_markers').change(function() {
    if ($('#show_markers').hasClass( "btn-default" )) {
        showMarkers();
        Cookies.set('show_markers', 1, { expires: 365 });
        show_markers = 1;
        $('#show_markers').removeClass( "btn-default" ).addClass( "btn-primary" ).addClass( "active" );
        return true;
    } else {
        hideMarkers();
        Cookies.set('show_markers', 0, { expires: 365 });
        show_markers = 0;
        $('#show_markers').removeClass("btn-primary").removeClass("active").addClass("btn-default");
        return true;
    }
}

function geodecodeMarker(i)
{
    console.log("geodecodeMarker : INIT");

    console.log("geodecodeMarker : INFO Geodecoding marker #" + i);
        
    //ajax call to remove marker from backend
    $.ajax({ 
        url: 'rpc.php',
        data: {
            'epoch': markers[i].epoch,
            'action': 'geoDecode'
        },
        type: 'get',
        dataType: 'json',
        success: function(data, status)
        {
            if (data.status) {
                
                console.log("geodecodeMarker : INFO Status : " + status);
                console.log("geodecodeMarker : INFO Data : " + data);
                
                //update marker data
                $('#loc_'+i).html("<a href='javascript:showBoundingBox("+ i +");' title='Show location bounding box' >" + data.location + "</a>");
            } else {
                console.log("geodecodeMarker : ERROR Status : " + status);
                console.log("geodecodeMarker : ERROR Data : " + data);
            }
        },
        error: function(xhr, desc, err) {
            console.log(xhr);
            console.log("geodecodeMarker : ERROR Details: " + desc + "\nError:" + err);
        }
    });
}

/**
* Adds two numbers
* @param {Number} a 
*/
function deleteMarker(tid, i)
{
    console.log("deleteMarker : INIT tid = "+tid+" i = "+i);

    if (confirm('Do you really want to permanently delete marker ?')) {
        console.log("deleteMarker : INFO Removing marker #" + i);
        
        //ajax call to remove marker from backend
        $.ajax({ 
            url: 'rpc.php',
            data: {
                'epoch': tid_markers[tid][i].epoch,
                'action': 'deleteMarker'
            },
            type: 'get',
            dataType: 'json',
            success: function(data, status) {
                if (data.status) {
                    //removing element from JS array
                    tid_markers[tid].splice(i, 1);
                    
                    //redraw map from scratch
                    eraseMap();
                    drawMap();
                } else {
                    console.log("deleteMarker : ERROR Status : " + status);
                    console.log("deleteMarker : ERROR Data : " + data);
                }
            },
            error: function(xhr, desc, err) {
                console.log(xhr);
                console.log("deleteMarker : ERROR Details: " + desc + "\nError:" + err);
            }
        });
    }
}

function showBoundingBox(i)
{
    console.log("showBoundingBox : INIT i = "+i);
}

function resetZoom()
{
    console.log("resetZoom : INIT");
    window.mymap.setView(default_center, default_zoom);
    return false;
}
