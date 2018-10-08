#!/usr/bin/env php
<?php

$INPUT_FILE = 'Location History.json';   // file to import (Google Takeout)
$TRACKER_ID = 'mb';   // tracker id to upload the data to

require_once '../config.inc.php';
require_once '../vendor/autoload.php';

use \pcrov\JsonReader\JsonReader;
use \pcrov\JsonReader\InputStream\Stream;
use \OwntracksRecorder\Database\MySql;
use \OwntracksRecorder\Database\SQLite;
use \OwntracksRecorder\RecordType\Location;

$fs = filesize($INPUT_FILE);
$fp = fopen($INPUT_FILE, 'rb');
if ($fp === false) {
    throw new IOException(\sprintf("Failed to open URI: %s", $uri));
}

if ($_config['sql_type'] == 'mysql') {
    $sql = new MySql($_config['sql_db'], $_config['sql_host'], $_config['sql_user'], $_config['sql_pass'], $_config['sql_prefix']);
} elseif ($_config['sql_type'] == 'sqlite') {
    $sql = new SQLite('../' . $_config['sql_db']);
} else {
    die('Invalid database type: ' . $_config['sql_type']);
}

$reader = new JsonReader();
$reader->stream($fp);

$reader->read('locations');   // find main structure
$depth = $reader->depth();    // remember depth (only go deeper)

$reader->read();   // goto first element

$ANSI_SCP = chr(0x1b) . '[s';
$ANSI_RCP = chr(0x1b) . '[u';
$ANSI_EL  = chr(0x1b) . '[K';

echo 'Importing ' . $INPUT_FILE . ': ' . $ANSI_SCP;
$time_start = microtime(true);

$sql->beginTransaction();

$i = 0;
do {
    $data = $reader->value();

    #print_r($data);

    $loc = new Location();
    $loc->connection = 'i';   // i = imported
    $loc->tracker_id = $TRACKER_ID;

    if (array_key_exists('accuracy', $data)) $loc->accuracy = intval($data['accuracy']);
    if (array_key_exists('altitude', $data)) $loc->altitude = intval($data['altitude']);
    if (array_key_exists('heading', $data)) $loc->heading = intval($data['heading']);
    $loc->latitude = floatval($data['latitudeE7']) / 1e7;
    $loc->longitude = floatval($data['longitudeE7']) / 1e7;
    $loc->epoch = (int)floor(intval($data['timestampMs']) / 1000);
    if (array_key_exists('verticalAccuracy', $data)) $loc->vertical_accuracy = intval($data['verticalAccuracy']);
    if (array_key_exists('velocity', $data)) $loc->velocity = intval(floatval($data['velocity'])*3.6);   // metres per second to km/h

    $sql->addRecord($loc);

    $i++;
    if ($i%2000 == 0) {
        $sql->commitTransaction();
        $sql->beginTransaction();
        $pos = ftell($fp);
        $frac = $pos/$fs;
        $perc = $pos*100/$fs;
        $time_now = microtime(true);
        $time_spent = $time_now - $time_start;
        $time_total = $time_spent / $frac;
        $time_left = $time_total - $time_spent;
        $time_unit = 'seconds';
        if ($time_left > 90) {
            $time_left /= 60;
            $time_unit = 'minutes';
        }
        echo $ANSI_RCP . $ANSI_EL . sprintf('%6.2f%% - %.0f %s left', $perc, $time_left, $time_unit);
    }
} while ($reader->next() && $reader->depth() > $depth);
$sql->commitTransaction();
echo $ANSI_RCP . $ANSI_EL . 'Done.' . PHP_EOL;

$reader->close();
