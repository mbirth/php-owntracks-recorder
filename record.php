<?php

//http://owntracks.org/booklet/tech/http/

require_once 'config.inc.php';
require_once 'vendor/autoload.php';

use \OwntracksRecorder\Database\MySql;
use \OwntracksRecorder\Database\SQLite;
use \OwntracksRecorder\RecordType\Location;

function _log($msg)
{
    $msg = date('Y-m-d H:i:s') . ' - ' . $_SERVER['REMOTE_ADDR'] . ' - ' . $msg . PHP_EOL;
    file_put_contents('./log/record_log.txt', $msg, FILE_APPEND);
}

$payload = file_get_contents('php://input');
_log('Payload = ' . $payload);
$data = @json_decode($payload, true);

if ($_config['sql_type'] == 'mysql') {
    $sql = new MySql($_config['sql_db'], $_config['sql_host'], $_config['sql_user'], $_config['sql_pass'], $_config['sql_prefix']);
} elseif ($_config['sql_type'] == 'sqlite') {
    $sql = new SQLite($_config['sql_db']);
} else {
    die('Invalid database type: ' . $_config['sql_type']);
}

header('Content-type: application/json');

$response_msg = null;
if ($data['_type'] == 'location' || in_array('debug', $_REQUEST)) {

    $loc = new Location();
    $loc->fillFromArray($data);

    // record only if same data found at same epoch / tracker_id
    if (!$sql->isEpochExisting($loc->tracker_id, $loc->epoch)) {
        $result = $sql->addRecord($loc);

        if ($result) {
            http_response_code(200);
            _log('Insert OK');
        } else {
            http_response_code(500);
            $response_msg = 'Can\'t write to database';
            _log('ERROR during Insert: Can\'t write to database.');
        }
    } else {
        _log('Duplicate location found for epoc ' . $loc->epoch . ' / tid ' . $loc->tracker_id . ' - no insert');
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
