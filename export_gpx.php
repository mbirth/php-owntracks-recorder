<?php
//http://owntracks.org/booklet/tech/http/
# Obtain the JSON payload from an OwnTracks app POSTed via HTTP
# and insert into database table.

require_once 'config.inc.php';
require_once 'vendor/autoload.php';

use \OwntracksRecorder\Database\MySql;
use \OwntracksRecorder\Database\SQLite;
use \OwntracksRecorder\RecordType\Location;
use \OwntracksRecorder\Gpx;
use \OwntracksRecorder\Rpc;

$response = array();

if ($_config['sql_type'] == 'mysql') {
    /** @var MySql $sql */
    $sql = new MySql($_config['sql_db'], $_config['sql_host'], $_config['sql_user'], $_config['sql_pass'], $_config['sql_prefix']);
} elseif ($_config['sql_type'] == 'sqlite') {
    /** @var SQLite $sql */
    $sql = new SQLite($_config['sql_db']);
} else {
    die('Invalid database type: ' . $_config['sql_type']);
}

$rpc = new Rpc($sql);
$markers = $rpc->getMarkers();


$gpx = new Gpx();
$gpx->addLink('github.com', 'php-owntracks-recorder');
$gpx->addTrack('Exported Track', 'other');

foreach ($markers['markers'] as $tid => $markerList) {
    foreach ($markerList as $marker) {
        $lo = new Location();
        $lo->fillFromDbArray($marker);

        $trkpt = $lo->getGpxDom();

        $gpx->addPoint($trkpt->documentElement);
    }
}

header('Content-type: application/gpx+xml');
header('Content-Disposition: attachment; filename=export.gpx');

echo $gpx->getXml();
