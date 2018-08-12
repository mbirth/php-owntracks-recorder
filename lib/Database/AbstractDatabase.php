<?php

namespace OwntracksRecorder\Database;

use \OwntracksRecorder\RecordType\AbstractRecordType;

class AbstractDatabase
{
    protected $db;
    protected $prefix;

    protected function execute(string $sql, array $params = array()): bool
    {
        // Run query without result
    }

    protected function query(string $sql, array $params = array()): array
    {
        // Run query and fetch results
    }

    public function beginTransaction()
    {
        // Start transaction
    }

    public function commitTransaction()
    {
        // Commit transaction
    }

    public function isEpochExisting(string $trackerId, int $epoch): bool
    {
        $sql = 'SELECT epoch FROM ' . $this->prefix . 'locations WHERE tracker_id = ? AND epoch = ?';
        $result = $this->query($sql, array($trackerId, $epoch));
        return (count($result) > 0);
    }

    public function addRecord(AbstractRecordType $obj)
    {
        $tablename = $obj->getTableName();
        $fieldnames = array();
        $placeholders = array();
        $values = array();
        foreach ($obj as $key => $value) {
            if (is_null($value)) {
                continue;
            }
            $fieldnames[] = $key;
            $placeholders[] = '?';
            $values[] = $value;
        }

        $sql = 'INSERT INTO ' . $this->prefix . $tablename . ' (' . implode(', ', $fieldnames) . ') VALUES (' . implode(', ', $placeholders) . ');';
        $result = $this->execute($sql, $values);
        return $result;
    }

    public function addLocation(
        int $accuracy = null,
        int $altitude = null,
        int $battery_level = null,
        int $heading = null,
        string $description = null,
        string $event = null,
        float $latitude,
        float $longitude,
        int $radius = null,
        string $trig = null,
        string $tracker_id = null,
        int $epoch,
        int $vertical_accuracy = null,
        int $velocity = null,
        float $pressure = null,
        string $connection = null,
        string $topic = null,
        int $place_id = null,
        int $osm_id = null
    ): bool {
        $sql = 'INSERT INTO ' . $this->prefix . 'locations (accuracy, altitude, battery_level, heading, description, event, latitude, longitude, radius, trig, tracker_id, epoch, vertical_accuracy, velocity, pressure, connection, topic, place_id, osm_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)';
        $params = array($accuracy, $altitude, $battery_level, $heading, $description, $event, $latitude, $longitude, $radius, $trig, $tracker_id, $epoch, $vertical_accuracy, $velocity, $pressure, $connection, $topic, $place_id, $osm_id);
        $result = $this->execute($sql, $params);
        return $result;
    }
 
    public function getMarkers(int $time_from, int $time_to, int $min_accuracy = 1000): array
    {
        $sql = 'SELECT * FROM ' . $this->prefix . 'locations WHERE epoch >= ? AND epoch <= ? AND accuracy < ? AND altitude >=0 ORDER BY tracker_id, epoch ASC';
        $result = $this->query($sql, array($time_from, $time_to, $min_accuracy));

        $markers = array();
        foreach ($result as $pr) {
            $markers[$pr['tracker_id']][] = $pr;
        }

        return $markers;
    }

    public function getMarkerLatLon(int $location_id)
    {
        $sql = 'SELECT latitude, longitude FROM ' . $this->prefix . 'locations WHERE lid = ?';
        $result = $this->query($sql, array($location_id));
        return $result[0];
    }

    public function deleteMarker(int $location_id)
    {
        $sql = 'DELETE FROM ' . $this->prefix . 'locations WHERE lid = ?';
        $result = $this->execute($sql, array($location_id));
        return $result;
    }

    public function updateLocationData(int $location_id, float $latitude, float $longitude, string $location_name, int $place_id, int $osm_id)
    {
        $sql = 'UPDATE ' . $this->prefix . 'locations SET display_name = ?, place_id = ?, osm_id = ? WHERE lid = ?';
        $params = array($location_name, $place_id, $osm_id, $location_id);
        $result = $this->execute($sql, $params);
        return $result;
    }

    public function getAllLatestMarkers(int $max_age = 86400)
    {
        $min_epoch = time() - $max_age;
        $sql = 'SELECT * from locations l1 INNER JOIN (SELECT tracker_id, MAX(epoch) AS epoch FROM locations GROUP BY tracker_id) l2 ON l1.tracker_id=l2.tracker_id AND l1.epoch=l2.epoch WHERE l1.epoch >= ?';
        $result = $this->query($sql, array($min_epoch));
        return $result;
    }
}
