<?php
    
//RENAME TO config.inc.php

setlocale(LC_TIME, 'en_GB');

// MySQL / MariaDB
$_config['sql_type'] = 'mysql';
$_config['sql_host'] = '';
$_config['sql_user'] = '';
$_config['sql_pass'] = '';
$_config['sql_db'] = '';
$_config['sql_prefix'] = '';

// SQLite
//$_config['sql_type'] = 'sqlite';
//$_config['sql_db'] = 'owntracks.db3';

$_config['default_accuracy'] = 1000;   //metres
$_config['default_trackerID'] = 'all';

$_config['geo_reverse_lookup_url'] = 'http://193.63.75.109/reverse?format=json&zoom=18&accept-language=en&addressdetails=0&email=sjobs@apple.com&';
$_config['geo_reverse_boundingbox_url'] = 'http://nominatim.openstreetmap.org/reverse?format=json&osm_type=W&osm_id=';
