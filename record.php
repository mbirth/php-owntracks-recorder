<?php

function _log($msg)
{
    $msg = date('Y-m-d H:i:s') . ' - ' . $_SERVER['REMOTE_ADDR'] . ' - ' . $msg . PHP_EOL;
    file_put_contents('./log/record_log.txt', $msg, FILE_APPEND);
}

//http://owntracks.org/booklet/tech/http/
# Obtain the JSON payload from an OwnTracks app POSTed via HTTP
# and insert into database table.

header('Content-type: application/json');
require_once('./config.inc.php');

$payload = file_get_contents('php://input');
_log('Payload = ' . $payload);
$data = @json_decode($payload, true);

$response_msg = null;
if ($data['_type'] == 'location' || $_REQUEST['debug']) {
    if ($_config['sql_type'] == 'mysql') {
        require_once('lib/db/MySql.php');
        $sql = new MySql($_config['sql_db'], $_config['sql_host'], $_config['sql_user'], $_config['sql_pass'], $_config['sql_prefix']);
    } elseif ($_config['sql_type'] == 'sqlite') {
        require_once('lib/db/SQLite.php');
        $sql = new SQLite($_config['sql_db']);
    } else {
        die('Invalid database type: ' . $_config['sql_type']);
    }

    $accuracy = null;
    $altitude = null;
    $battery_level = null;
    $heading = null;
    $description = null;
    $event = null;
    $latitude = null;
    $longitude = null;
    $radius = null;
    $trig = null;
    $tracker_id = null;
    $epoch = null;
    $vertical_accuracy = null;
    $velocity = null;
    $pressure = null;
    $connection = null;

    //http://owntracks.org/booklet/tech/json/
    if (array_key_exists('acc', $data)) $accuracy = intval($data['acc']);
    if (array_key_exists('alt', $data)) $altitude = intval($data['alt']);
    if (array_key_exists('batt', $data)) $battery_level = intval($data['batt']);
    if (array_key_exists('cog', $data)) $heading = intval($data['cog']);
    if (array_key_exists('desc', $data)) $description = strval($data['desc']);
    if (array_key_exists('event', $data)) $event = strval($data['event']);
    if (array_key_exists('lat', $data)) $latitude = floatval($data['lat']);
    if (array_key_exists('lon', $data)) $longitude = floatval($data['lon']);
    if (array_key_exists('rad', $data)) $radius = intval($data['rad']);
    if (array_key_exists('t', $data)) $trig = strval($data['t']);
    if (array_key_exists('tid', $data)) $tracker_id = strval($data['tid']);
    if (array_key_exists('tst', $data)) $epoch = intval($data['tst']);
    if (array_key_exists('vac', $data)) $vertical_accuracy = intval($data['vac']);
    if (array_key_exists('vel', $data)) $velocity = intval($data['vel']);
    if (array_key_exists('p', $data)) $pressure = floatval($data['p']);
    if (array_key_exists('conn', $data)) $connection = strval($data['conn']);
    
    //record only if same data found at same epoch / tracker_id
    if (!$sql->isEpochExisting($tracker_id, $epoch)) {

        $result = $sql->addLocation(
            $accuracy,
            $altitude,
            $battery_level,
            $heading,
            $description,
            $event,
            $latitude,
            $longitude,
            $radius,
            $trig,
            $tracker_id,
            $epoch,
            $vertical_accuracy,
            $velocity,
            $pressure,
            $connection
        );
            
        if ($result) {
            http_response_code(200);
            _log('Insert OK');
        } else {
            http_response_code(500);
            $response_msg = 'Can\'t write to database';
            _log('Insert KO - Can\'t write to database.');
        }
    } else {
        _log('Duplicate location found for epoc ' . $epoch . ' / tid ' . $tracker_id . ' - no insert');
        $response_msg = 'Duplicate location found for epoch. Ignoring.';
    }
} else {
    http_response_code(204);
    _log('OK type is not location: ' . $data['_type']);
}

$response = array();

// Build list of buddies' last locations
$buddies = $sql->getAllLatestMarkers();
foreach ($buddies as $buddy) {
    $loc = array(
        '_type' => 'location',
        'acc' => $buddy['accuracy'],
        'alt' => $buddy['altitude'],
        'batt' => $buddy['battery_level'],
        'cog' => $buddy['heading'],
        'lat' => $buddy['latitude'],
        'lon' => $buddy['longitude'],
        'rad' => $buddy['radius'],
        't' => $buddy['trig'],
        'tid' => strval($buddy['tracker_id']),
        'tst' => $buddy['epoch'],
        'vac' => $buddy['vertical_accuracy'],
        'vel' => $buddy['velocity'],
        'p' => $buddy['pressure'],
        'conn' => $buddy['connection'],
    );
    $response[] = $loc;
}

if (!is_null($response_msg)) {
    // Add status message to return object (to be shown in app)
    $response[] = array(
        '_type' => 'cmd',
        'action' => 'action',
        'content' => $response_msg,
    );
}

print json_encode($response);
