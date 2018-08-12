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
}