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
