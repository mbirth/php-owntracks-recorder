window.handlePopState = (event) ->
    console.log 'handlePopState: %o', event
    if event.state
        return gotoDate event.state.dateFrom, event.state.dateTo, false

window.goPrevious = ->
    window.gotoDate window.datePrevFrom, window.datePrevTo

window.goNext = ->
    window.gotoDate window.dateNextFrom, window.dateNextTo

getDateAsLocalISO = (_date) ->
    console.log 'getDateAsLocalISO(%o)', _date
    dateobj = new Date _date
    tzoffset = dateobj.getTimezoneOffset() * 60000
    isoString = new Date(dateobj - tzoffset).toISOString()
    return isoString[...-1]   # strip the "Z" (UTC indicator)

getToday = ->
    today = new Date
    today.setHours 0
    today.setMinutes 0
    today.setSeconds 0
    today = new Date today.getTime() - today.getTimezoneOffset() * 60000
    return today

window.updateDateNav = (_dateFrom, _dateTo) ->
    console.log 'updateDateNav: %o, %o', _dateFrom, _dateTo

    _dateFrom ?= window.dateFrom
    _dateTo ?= window.dateTo

    # Prepare for calculations
    objFrom = new Date _dateFrom
    objTo   = new Date _dateTo
    today   = getToday()

    span = objTo.getTime() - objFrom.getTime()   # milliseconds

    #console.log 'Current range: %o - %o (%o)', _dateFrom, _dateTo, span
    #console.log 'Objects: %o - %o', objFrom, objTo

    objPrevTo = new Date objFrom.getTime() - 1000       # 1 second before current window
    objPrevFrom = new Date objPrevTo.getTime() - span   # calculate span

    window.datePrevFrom = objPrevFrom.toISOString()
    window.datePrevTo   = objPrevTo.toISOString()

    #console.log 'PREV button will go to: %o - %o', window.datePrevFrom, window.datePrevTo

    objNextFrom = new Date objTo.getTime() + 1000         # 1 second after current window
    objNextTo   = new Date objNextFrom.getTime() + span   # calculate span

    window.dateNextFrom = objNextFrom.toISOString()
    window.dateNextTo   = objNextTo.toISOString()

    #console.log 'NEXT button will go to: %o - %o', window.dateNextFrom, window.dateNextTo

    # disable Next button if we'd end up in the future
    if objNextFrom > today
        console.log 'Disabling NEXT button because %o is in the future. (Today is %o)', objNextFrom, today
        $('#nextButton').addClass 'disabled'
        window.mymap?.buttonNext.disable()
    else
        $('#nextButton').removeClass 'disabled'
        window.mymap?.buttonNext.enable()

    # disable today button if dateFrom isn't today
    if _dateFrom is today.toISOString()[...10]
        $('#todayButton').addClass 'disabled'
        $('#livemap_on').removeClass 'disabled'
        window.mymap?.buttonToday.disable()
    else
        $('#todayButton').removeClass 'disabled'
        $('#livemap_on').addClass 'disabled'
        window.mymap?.buttonToday.enable()

window.gotoDate = (_dateFrom, _dateTo, pushState) ->
    console.log 'gotoDate: %o, %o, %o', _dateFrom, _dateTo, pushState

    today = getToday().toISOString()[...10]
    _dateFrom = _dateFrom ? (today + "T00:00:00")
    _dateTo = _dateTo ? (today + "T23:59:59")
    pushState = pushState ? true

    if _dateTo.length < 12
        console.log "DateTo %o has no time, assuming 23:59:59", _dateTo
        _dateTo += "T23:59:59"

    window.dateFrom = new Date(_dateFrom).toISOString()
    window.dateTo = new Date(_dateTo).toISOString()

    $('#dateFrom').val ((getDateAsLocalISO window.dateFrom)[...10])
    $('#dateTo').val ((getDateAsLocalISO window.dateTo)[...10])

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
    tid = $('#trackerID_selector').val()
    window.mymap.setMarkerFilter tid
    return false

window.initUI = ->
    console.log 'BEGIN: initUI'

    _GET = new URLSearchParams window.location.search

    today = getDateAsLocalISO(new Date())

    # sanitise date input
    getDateFrom = today[...11]
    try
        if _GET.has 'dateFrom'
            getDateFrom = _GET.get 'dateFrom'
    catch
        getDateFrom = today[...11]
    if getDateFrom.length < 12
        getDateFrom += "00:00:00"
    console.log 'getDateFrom: %o', getDateFrom
    window.dateFrom = new Date(getDateFrom).toISOString()

    getDateTo = today[...11]
    try
        if _GET.has 'dateTo'
            getDateTo = _GET.get 'dateTo'
    catch
        getDateTo = today[...11]
    if getDateTo.length < 12
        getDateTo += "23:59:59"
    window.dateTo = new Date(getDateTo).toISOString()

    #console.log "dateFrom now: %o", window.dateFrom
    #console.log "dateTo now: %o", window.dateTo

    $('#dateFrom').val ((getDateAsLocalISO window.dateFrom)[...10])
    $('#dateTo').val ((getDateAsLocalISO window.dateTo)[...10])

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

    # setup history popupstate event handler
    window.onpopstate = window.handlePopState

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
    $("#trackerID_selector option[value!='']").each ->
        $(this).remove()
    trackerIds = window.mymap.markermgr.getTrackerIds()
    console.log 'Got these tracker ids: %o', trackerIds
    for value in trackerIds
        $('#trackerID_selector').append $ '<option>',
            value: value
            text: value
    $("#trackerID_selector").val window.trackerID    # TODO: find better way
