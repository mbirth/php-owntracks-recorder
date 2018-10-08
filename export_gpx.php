<?php
//http://owntracks.org/booklet/tech/http/
# Obtain the JSON payload from an OwnTracks app POSTed via HTTP
# and insert into database table.

require_once 'config.inc.php';
require_once 'vendor/autoload.php';

use \OwntracksRecorder\Database\MySql;
use \OwntracksRecorder\Database\SQLite;
use \OwntracksRecorder\RecordType\Location;
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


#header("Content-type: application/javascript");

$dom = new \DOMDocument('1.0', 'utf-8');
$dom->formatOutput = true;
$gpx = $dom->createElement('gpx');
$gpx->setAttribute('creator', 'php-owntracks-recorder');
$gpx->setAttribute('version', '1.1');
$gpx->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns', 'http://www.topografix.com/GPX/1/1');
$gpx->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
$gpx->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:ns2', 'http://www.garmin.com/xmlschemas/GpxExtensions/v3');
$gpx->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:ns3', 'http://www.garmin.com/xmlschemas/TrackPointExtension/v1');
$gpx->setAttribute('xsi:schemaLocation', 'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/11.xsd');

# METADATA
$meta = $dom->createElement('metadata');
$link = $dom->createElement('link');
$link->setAttribute('href', 'github.com');
$link->appendChild($dom->createElement('text', 'php-owntracks-recorder'));
$meta->appendChild($link);
$meta->appendChild($dom->createElement('time', date('c')));
$gpx->appendChild($meta);

# TRACK INFO
$trk = $dom->createElement('trk');
$trk->appendChild($dom->createElement('name', 'Exported Track'));
$trk->appendChild($dom->createElement('type', 'other'));

# TRACK SEGMENT
$trkseg = $dom->createElement('trkseg');

foreach ($markers['markers'] as $tid => $markerList) {
    foreach ($markerList as $marker) {
        $lo = new Location();
        $lo->fillFromDbArray($marker);

        $trkpt = $lo->getGpxDom();

        $trkpti = $dom->importNode($trkpt->documentElement, true);
        $trkseg->appendChild($trkpti);
    }
}

$trk->appendChild($trkseg);
$gpx->appendChild($trk);
$dom->appendChild($gpx);

echo $dom->saveXML();
