<?php

namespace OwntracksRecorder;

use \OwntracksRecorder\Database\AbstractDatabase;

class Rpc
{
    private $sql;

    public function __construct(AbstractDatabase $sql)
    {
        $this->sql = $sql;
    }

    public function call($action)
    {
        if (method_exists($this, $action)) {
            return call_user_func(array($this, $action));
        }

        http_response_code(404);
        return array(
            'status' => false,
            'error' => 'No action to perform.',
        );
    }

    public function getMarkers()
    {
        global $_config;

        if (!array_key_exists('dateFrom', $_GET)) {
            $_GET['dateFrom'] = date('Y-m-d') . 'T00:00:00';
        }

        if (!array_key_exists('dateTo', $_GET)) {
            $_GET['dateTo'] = date('Y-m-d') . 'T23:59:59';
        }

        if (array_key_exists('accuracy', $_GET) && $_GET['accuracy'] > 0) {
            $accuracy = intval($_GET['accuracy']);
        } else {
            $accuracy = $_config['default_accuracy'];
        }

        $time_from = strtotime($_GET['dateFrom']);
        $time_to = strtotime($_GET['dateTo']);

        $markers = $this->sql->getMarkers($time_from, $time_to, $accuracy);

        if ($markers === false) {
            http_response_code(500);
            return array(
                'status' => false,
                'error' => 'Database query error',
            );
        }

        return array(
            'status' => true,
            'markers' => $markers,
        );
    }

    public function deleteMarker()
    {
        if (!array_key_exists('lid', $_REQUEST)) {
            http_response_code(204);
            return array(
                'status' => false,
                'error' => 'No location_id provided for marker removal',
            );
        }
        $result = $this->sql->deleteMarker($_REQUEST['lid']);
        if ($result === false) {
            http_response_code(500);
            return array(
                'status' => false,
                'error' => 'Unable to delete marker from database.',
            );
        }
        return array(
            'status' => true,
            'msg' => 'Marker deleted from database',
        );
    }

    public function geoDecode()
    {
        global $_config;

        if (!array_key_exists('lid', $_REQUEST)) {
            http_response_code(204);
            return array(
                'status' => false,
                'error' => 'No location_id provided for marker removal',
            );
        }
        // GET MARKER'S LAT & LONG DATA
        $marker = $this->sql->getMarkerLatLon($_REQUEST['lid']);

        if ($marker === false) {
            http_response_code(500);
            return array(
                'status' => false,
                'error' => 'Unable to get marker from database.',
            );
        }

        $latitude = $marker['latitude'];
        $longitude = $marker['longitude'];

        // GEO DECODE LAT & LONG
        $geo_decode_url = $_config['geo_reverse_lookup_url'] . 'lat=' . $latitude . '&lon=' . $longitude;
        $geo_decode_json = file_get_contents($geo_decode_url);
        $geo_decode = @json_decode($geo_decode_json, true);

        $place_id = intval($geo_decode['place_id']);
        $osm_id = intval($geo_decode['osm_id']);
        $location = strval($geo_decode['display_name']);

        if ($location == '') {
            $location = @json_encode($geo_decode);
        }

        // UPDATE MARKER WITH GEODECODED LOCATION
        $result = $this->sql->updateLocationData((int)$_REQUEST['lid'], (float)$latitude, (float)$longitude, $location, $place_id, $osm_id);

        if ($result === false) {
            http_response_code(500);
            return array(
                'status' => false,
                'error' => 'Unable to update marker in database.',
            );
        }
        return array(
            'status' => true,
            'msg' => 'Marker\'s location fetched and saved to database',
            'location' => $location,
        );
    }
}
