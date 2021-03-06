<?php

require_once 'config.inc.php';
require_once 'vendor/autoload.php';

if (isset($_GET['accuracy']) && $_GET['accuracy'] != '' && intval($_GET['accuracy']) > 0) {
    $accuracy = intval($_GET['accuracy']);
} elseif (isset($_COOKIE['accuracy']) && $_COOKIE['accuracy'] != '' && intval($_COOKIE['accuracy']) > 0) {
    $accuracy = intval($_COOKIE['accuracy']);
} else {
    $accuracy = $_config['default_accuracy'];
}

if (isset($_GET['trackerID']) && $_GET['trackerID'] != '' && strlen($_GET['trackerID']) == 2) {
    $trackerID = $_GET['trackerID'];
} elseif (isset($_COOKIE['trackerID']) && $_COOKIE['trackerID'] != '' && strlen($_COOKIE['trackerID']) == 2) {
    $trackerID = $_COOKIE['trackerID'];
} else {
    $trackerID = $_config['default_trackerID'];
}

$mustache = new \Mustache_Engine(array(
    'loader' => new \Mustache_Loader_FilesystemLoader('templates/'),
    'partials_loader' => new \Mustache_Loader_FilesystemLoader('templates/partials/'),
    'charset' => 'utf-8',
    'logger' => new \Mustache_Logger_StreamLogger('php://stderr'),
));

$vars = array(
    'accuracy' => $accuracy,
    'tracker_id' => $trackerID,
);

$tpl = $mustache->loadTemplate('index');
echo $tpl->render($vars);
