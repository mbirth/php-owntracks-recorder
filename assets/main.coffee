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

    span = objTo.getTime() - objFrom.getTime()   # milliseconds

    console.log 'Current range: %o - %o (%o)', _dateFrom, _dateTo, span

    objPrevTo = new Date objFrom.getTime()
    objPrevTo.setDate objPrevTo.getDate() - 1   # get day before current "dateFrom"
    objPrevFrom = new Date objPrevTo.getTime() - span   # calculate span

    window.datePrevFrom = objPrevFrom.toISOString()[...10]
    window.datePrevTo   = objPrevTo.toISOString()[...10]

    console.log 'PREV button will go to: %o - %o', window.datePrevFrom, window.datePrevTo

    objNextFrom = new Date objTo.getTime()
    objNextFrom.setDate objNextFrom.getDate() + 1   # get day after current "dateTo"
    objNextTo   = new Date objNextFrom.getTime() + span   # calculate span

    window.dateNextFrom = objNextFrom.toISOString()[...10]
    window.dateNextTo   = objNextTo.toISOString()[...10]

    console.log 'NEXT button will go to: %o - %o', window.dateNextFrom, window.dateNextTo

    # disable Next button if we'd end up in the future
    if objNextFrom > new Date()
        $('#nextButton').addClass 'disabled'
    else
        $('#nextButton').removeClass 'disabled'
    
    # disable today button if dateFrom isn't today
    if _dateFrom is new Date().toISOString()[...10]
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
    window.mymap.getMarkers()
    return false

window.gotoAccuracy = ->
    console.log 'gotoAccuracy'
    
    _accuracy = parseInt $('#accuracy').val()

    if _accuracy != window.accuracy
        Cookies.set 'accuracy', _accuracy
        console.log 'Accuracy cookie = %o', Cookies.get 'accuracy'
        
        window.accuracy = _accuracy
        window.mymap.getMarkers()
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
        return gotoDate $('#dateFrom').val(), $('#dateTo').val()

    # accuracy event handlers
    $('#accuracy').change -> gotoAccuracy()
    $('#accuracySubmit').click -> gotoAccuracy()

    $('#trackerID_selector').change -> changeTrackerID()

    $('#configCollapse').on 'show.bs.collapse', (e) ->
        $('#configButton').removeClass('btn-default').addClass('btn-primary').addClass('active')
    $('#configCollapse').on 'hide.bs.collapse', (e) ->
        $('#configButton').addClass('btn-default').removeClass('btn-primary').removeClass('active')

    # setup history popupstate event handler
    window.onpopstate = window.handlePopState

window.showHideMarkers = ->
    console.log 'showHideMarkers'
    # $('#show_markers').change(function() {
    if $('#show_markers').hasClass 'btn-default'
        window.mymap.showMarkers()
        Cookies.set 'show_markers', 1, { expires: 365 }
        window.show_markers = 1
        $('#show_markers').removeClass('btn-default').addClass('btn-primary').addClass('active')
        return true
    else
        window.mymap.hideMarkers()
        Cookies.set 'show_markers', 0, { expires: 365 }
        window.show_markers = 0
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

window.geodecodeMarker = (tid, i) ->
    console.log 'geodecodeMarker: %o, %o', tid, i
    window.mymap.geodecodeMarker tid, i

window.deleteMarker = (tid, i) ->
    console.log 'deleteMarker: %o, %o', tid, i
    if confirm "Do you really want to delete this marker for #{tid}?"
        console.log 'deleteMarker: Confirmation given'
        window.mymap.deleteMarker tid, i

window.showBoundingBox = (tid, i) ->
    console.log 'showBoundingBox: %o, %o', tid, i
    console.warn 'NOT YET IMPLEMENTED'
