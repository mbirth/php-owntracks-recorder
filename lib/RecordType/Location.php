<?php

namespace OwntracksRecorder\RecordType;

use \OwntracksRecorder\RecordType\AbstractRecordType;

class Location extends AbstractRecordType
{
    protected $table = 'locations';

    // https://owntracks.org/booklet/tech/json/
    protected $type = 'location';

    // Mapping of database fields => JSON field, type
    protected $fields = array(
        'lid'          => null,
        'dt'           => null,
        'accuracy'     => array('acc', 'int'),
        'altitude'     => array('alt', 'int'),
        'battery_level' => array('batt', 'int'),
        'heading'      => array('cog', 'int'),
        'description'  => array('desc', 'string'),
        'event'        => array('event', 'string'),
        'latitude'     => array('lat', 'float'),   // required in JSON
        'longitude'    => array('lon', 'float'),   // required in JSON
        'radius'       => array('rad', 'int'),
        'trig'         => array('t', 'string'),
        'tracker_id'   => array('tid', 'string'),   // required in JSON (http)
        'epoch'        => array('tst', 'int'),   // required in JSON
        'vertical_accuracy' => array('vac', 'int'),
        'velocity'     => array('vel', 'int'),
        'pressure'     => array('p', 'float'),
        'connection'   => array('conn', 'string'),
        'topic'        => array('topic', 'string'),
        'place_id'     => null,
        'osm_id'       => null,
        'display_name' => null,
    );

    public function getGpxDom()
    {
        $dom = new \DOMDocument('1.0', 'utf-8');
        $trkpt = $dom->createElement('trkpt');
        $trkpt->setAttribute('lat', $this->data['latitude']);
        $trkpt->setAttribute('lon', $this->data['longitude']);

        $ext = $dom->createElement('extensions');

        $trkpt->appendChild($dom->createElement('time', date('c', intval($this->data['epoch']))));
        $ext->appendChild($dom->createElement('epoch', $this->data['epoch']));

        $trkpt->appendChild($dom->createElement('ele', $this->data['altitude']));

        # GDOP
        # <1 - ideal
        # 1-2 - excellent
        # 2-5 - good
        # 5-10 - moderate
        # 10-20 - fair (rough estimate of location)
        # >20 - poor (should be discarded)
        $hdop = intval($this->data['accuracy']) / 5;
        $trkpt->appendChild($dom->createElement('hdop', $hdop));
        $ext->appendChild($dom->createElement('acc', $this->data['accuracy']));

        $vdop = intval($this->data['vertical_accuracy']) / 5;
        $trkpt->appendChild($dom->createElement('vdop', $vdop));
        $ext->appendChild($dom->createElement('vacc', $this->data['vertical_accuracy']));

        if (!is_null($this->data['heading'])) {
            $ext->appendChild($dom->createElement('hdg', $this->data['heading']));
        }

        if ($this->data['velocity'] > 0) {
            $ext->appendChild($dom->createElement('spd_mps', intval($this->data['velocity'])));
            $ext->appendChild($dom->createElement('spd_kph', intval($this->data['velocity']) * 3.6));
        }

        $trkpt->appendChild($ext);
        $dom->appendChild($trkpt);
        return $dom;
    }
}
