<?php
//http://owntracks.org/booklet/tech/http/
# Obtain the JSON payload from an OwnTracks app POSTed via HTTP
# and insert into database table.

require_once 'config.inc.php';
require_once 'vendor/autoload.php';

use \OwntracksRecorder\Database\MySql;
use \OwntracksRecorder\Database\SQLite;
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

if (array_key_exists('action', $_REQUEST)) {
    $response = $rpc->call($_REQUEST['action']);
} else {
    http_response_code(404);
    $response['error'] = "Invalid request type or no action";
    $response['status'] = false;
}

header("Content-type: application/javascript");
echo json_encode($response);
