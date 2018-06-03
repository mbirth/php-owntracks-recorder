window.handlePopState = (event) ->
    console.log 'handlePopState: %o', event
    if event.state
        return gotoDate event.state.dateFrom, event.state.dateTo, false

window.goPrevious = ->
    window.gotoDate window.datePrevFrom, window.datePrevTo

window.goNext = ->
    window.gotoDate window.dateNextFrom, window.dateNextTo

window.updateDateNav = (_dateFrom, _dateTo) ->
    console.log 'updateDateNav: %o, %o', _dateFrom, _dateTo

    _dateFrom ?= window.dateFrom
    _dateTo ?= window.dateTo

    # Prepare for calculations
    objFrom = new Date _dateFrom
    objTo   = new Date _dateTo
    today   = new Date
    today.setHours 0
    today.setMinutes 0
    today.setSeconds 0
    today   = new Date today.getTime() - today.getTimezoneOffset() * 60000

    span = objTo.getTime() - objFrom.getTime()   # milliseconds

    #console.log 'Current range: %o - %o (%o)', _dateFrom, _dateTo, span
    #console.log 'Objects: %o - %o', objFrom, objTo

    objPrevTo = new Date objFrom.getTime()
    objPrevTo.setUTCDate objPrevTo.getUTCDate() - 1   # get day before current "dateFrom"
    objPrevFrom = new Date objPrevTo.getTime() - span   # calculate span

    window.datePrevFrom = objPrevFrom.toISOString()[...10]
    window.datePrevTo   = objPrevTo.toISOString()[...10]

    #console.log 'PREV button will go to: %o - %o', window.datePrevFrom, window.datePrevTo

    objNextFrom = new Date objTo.getTime()
    objNextFrom.setUTCDate objNextFrom.getUTCDate() + 1   # get day after current "dateTo"
    objNextTo   = new Date objNextFrom.getTime() + span   # calculate span

    window.dateNextFrom = objNextFrom.toISOString()[...10]
    window.dateNextTo   = objNextTo.toISOString()[...10]

    #console.log 'NEXT button will go to: %o - %o', window.dateNextFrom, window.dateNextTo

    # disable Next button if we'd end up in the future
    if objNextFrom > today
        console.log 'Disabling NEXT button because %o is in the future. (Today is %o)', objNextFrom, today
        $('#nextButton').addClass 'disabled'
    else
        $('#nextButton').removeClass 'disabled'

    # disable today button if dateFrom isn't today
    if _dateFrom is today.toISOString()[...10]
        $('#todayButton').addClass 'disabled'
        $('#livemap_on').removeClass 'disabled'
    else
        $('#todayButton').removeClass 'disabled'
        $('#livemap_on').addClass 'disabled'

window.gotoDate = (_dateFrom, _dateTo, pushState) ->
    console.log 'gotoDate: %o, %o, %o', _dateFrom, _dateTo, pushState

    today = new Date().toISOString()[...10]
    _dateFrom = _dateFrom ? today
    _dateTo = _dateTo ? today
    pushState = pushState ? true

    window.dateFrom = _dateFrom
    window.dateTo = _dateTo
    
    $('#dateFrom').val window.dateFrom
    $('#dateTo').val window.dateTo

    # push selected dates in window.history stack
    if pushState
        data =
            dateFrom: window.dateFrom
            dateTo: window.dateTo
        url = "#{window.location.pathname}?dateFrom=#{data.dateFrom}&dateTo=#{data.dateTo}"
        console.log 'Pushing state: %o with data: %o', url, data
        window.history.pushState data, '', url

    updateDateNav()
    window.mymap.fetchMarkers()
    return false

window.gotoAccuracy = ->
    console.log 'gotoAccuracy'
    
    _accuracy = parseInt $('#accuracy').val()

    if _accuracy != window.accuracy
        Cookies.set 'accuracy', _accuracy
        console.log 'Accuracy cookie = %o', Cookies.get 'accuracy'
        
        window.accuracy = _accuracy
        window.mymap.fetchMarkers()
    else
        $('#configCollapse').collapse 'hide'
    return false

window.changeTrackerID = ->
    console.log 'changeTrackerID'
    
    _trackerID = $('#trackerID_selector').val()
    
    if _trackerID != window.trackerID
        Cookies.set 'trackerID', _trackerID
        console.log 'changeTrackerID: trackerID cookie = %o', Cookies.get 'trackerID'
        
        window.trackerID = _trackerID
        window.mymap.drawMap()
    else
        $('#configCollapse').collapse 'hide'
    return false

window.initUI = ->
    console.log 'BEGIN: initUI'

    _GET = new URLSearchParams window.location.search

    today = new Date().toISOString()[...10]

    # sanitise date input
    try
        window.dateFrom = if _GET.has 'dateFrom' then new Date(_GET.get 'dateFrom').toISOString()[...10] else today
    catch err
        window.dateFrom = today

    try
        window.dateTo = if _GET.has 'dateTo' then new Date(_GET.get 'dateTo').toISOString()[...10] else today
    catch err
        window.dateTo = today

    $('#dateFrom').val window.dateFrom
    $('#dateTo').val window.dateTo

    # date params event handlers
    updateDateNav()

    $('.input-daterange').on 'change', (e) ->
        if $(e.target).is $('#dateFrom')
            if $('#dateFrom').val() > $('#dateTo').val()
                $('#dateTo').val $('#dateFrom').val()
        else if $(e.target).is $('#dateTo')
            if $('#dateTo').val() < $('#dateFrom').val()
                $('#dateFrom').val $('#dateTo').val()
        return gotoDate $('#dateFrom').val(), $('#dateTo').val()

    # accuracy event handlers
    $('#accuracy').change -> gotoAccuracy()
    $('#accuracySubmit').click -> gotoAccuracy()

    $('#trackerID_selector').change -> changeTrackerID()

    $('#configCollapse').on 'show.bs.collapse', (e) ->
        $('#configButton').removeClass('btn-default').addClass('btn-primary').addClass('active')
    $('#configCollapse').on 'hide.bs.collapse', (e) ->
        $('#configButton').addClass('btn-default').removeClass('btn-primary').removeClass('active')

    # set button state
    show_markers = Cookies.get 'show_markers'
    console.log 'show_markers cookie value is: %o', show_markers
    if show_markers is '1'
        $('#show_markers').removeClass('btn-default').addClass('btn-primary').addClass('active')

    # setup history popupstate event handler
    window.onpopstate = window.handlePopState

window.showHideMarkers = ->
    console.log 'showHideMarkers'
    # $('#show_markers').change(function() {
    if $('#show_markers').hasClass 'btn-default'
        window.mymap.showMarkers()
        $('#show_markers').removeClass('btn-default').addClass('btn-primary').addClass('active')
        return true
    else
        window.mymap.hideMarkers()
        $('#show_markers').removeClass('btn-primary').removeClass('active').addClass('btn-default')
        return true

window.resetZoom = ->
    console.log 'resetZoom'
    window.mymap.resetZoom()
    return false

window.setLiveMap = ->
    console.log 'setLiveMap'
    if window.mymap.toggleLiveView()
        $('#livemap_on').removeClass('btn-default').addClass('btn-primary').addClass 'active'
    else
        $('#livemap_on').addClass('btn-default').removeClass('btn-primary').removeClass 'active'

window.geodecodeMarker = (lid) ->
    console.log 'geodecodeMarker: %o', lid
    window.mymap.geodecodeMarker lid

window.deleteMarker = (lid) ->
    console.log 'deleteMarker: %o', lid
    if confirm "Do you really want to delete this marker?"
        console.log 'deleteMarker: Confirmation given'
        window.mymap.deleteMarker lid

window.showBoundingBox = (lid) ->
    console.log 'showBoundingBox: %o', lid
    console.warn 'NOT YET IMPLEMENTED'

window.updateTrackerIDs = ->
    console.log 'updateTrackerIDs()'
    $("#trackerID_selector option[value!='all']").each ->
        $(this).remove()
    trackerIds = window.mymap.markermgr.getTrackerIds()
    console.log 'Got these tracker ids: %o', trackerIds
    for value in trackerIds
        $('#trackerID_selector').append $ '<option>',
            value: value
            text: value
    $("#trackerID_selector").val window.trackerID    # TODO: find better way
