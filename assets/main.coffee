window.handlePopState = (event) ->
    console.log 'handlePopState: %o', event
    if event.state
        return gotoDate event.state.dateFrom, event.state.dateTo, false

window.updateDateNav = (_dateFrom, _dateTo) ->
    console.log 'updateDateNav: %o, %o', _dateFrom, _dateTo
    
    _dateFrom ?= window.dateFrom
    _dateTo ?= window.dateTo

    diff = _dateTo.diff _dateFrom, 'days'
    # if(dateTo.isSame(dateFrom)){ diff = diff+1; }
    
    datePrevTo = moment(_dateFrom).subtract 1, 'days'
    datePrevFrom = moment(datePrevTo).subtract diff, 'days'
    
    dateNextFrom = moment(_dateTo).add 1, 'days'
    dateNextTo = moment(dateNextFrom).add diff, 'days'
    
    # disable Next button
    if dateNextFrom.isAfter(moment())
        $('#nextButton').addClass 'disabled'
    else
        $('#nextButton').removeClass 'disabled'
    
    # disable today button
    if dateNextFrom.isSame(moment())
        $('#todayButton').addClass 'disabled'
        $('#livemap_on').removeClass 'disabled'
    else
        $('#todayButton').removeClass 'disabled'
        $('#livemap_on').addClass 'disabled'

window.gotoDate = (_dateFrom, _dateTo, pushState) ->
    console.log 'gotoDate: %o, %o, %o', _dateFrom, _dateTo, pushState

    _dateFrom = if _dateFrom? then moment(_dateFrom) else moment()
    _dateTo = if _dateTo? then moment(_dateTo) else moment()
    pushState = pushState ? true

    window.dateFrom = _dateFrom
    window.dateTo = _dateTo
    
    $('#dateFrom').val moment(window.dateFrom).format('YYYY-MM-DD')
    $('#dateTo').val moment(window.dateTo).format('YYYY-MM-DD')

    # push selected dates in window.history stack
    if pushState
        data =
            dateFrom: moment(window.dateFrom).format 'YYYY-MM-DD'
            dateTo: moment(window.dateTo).format 'YYYY-MM-DD'
        url = "#{window.location.pathname}?dateFrom=#{data.dateFrom}&dateTo=#{data.dateTo}"
        console.log 'Pushing state: %o with data: %o', url, data
        window.history.pushState data, '', url

    updateDateNav()
    mapMarkers()
    return false

window.gotoAccuracy = ->
    console.log 'gotoAccuracy'
    
    _accuracy = parseInt $('#accuracy').val()

    if _accuracy != window.accuracy
        Cookies.set 'accuracy', _accuracy
        console.log 'Accuracy cookie = %o', Cookies.get 'accuracy'
        
        # location.href='./?dateFrom='+moment(dateFrom).format('YYYY-MM-DD') + '&dateTo=' + moment(dateTo).format('YYYY-MM-DD') + '&accuracy=' + _accuracy + '&trackerID=' + trackerID;
        window.accuracy = _accuracy
        mapMarkers()
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
        drawMap()
    else
        $('#configCollapse').collapse 'hide'
    return false

window.initUI = ->
    console.log 'BEGIN: initUI'

    _GET = new URLSearchParams window.location.search

    window.dateFrom = if _GET.has 'dateFrom' then moment _GET.get 'dateFrom' else moment()
    window.dateTo = if _GET.has 'dateTo' then moment _GET.get 'dateTo' else moment()
    $('#dateFrom').val window.dateFrom.format 'YYYY-MM-DD'
    $('#dateTo').val window.dateTo.format 'YYYY-MM-DD'

    # date params event handlers
    updateDateNav()

    $('.input-daterange').datepicker
        format: 'yyyy-mm-dd'
        language: window.datepicker_language
        endDate: '0d'

    $('.input-daterange').datepicker().on 'hide', (e) ->
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
