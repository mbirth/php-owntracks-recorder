<?php

namespace OwntracksRecorder\RecordType;

class AbstractRecordType implements \Iterator
{
    protected $type;
    protected $table;
    protected $fields = array();
    protected $data = array();

    public function __construct()
    {
        // init empty record
        foreach ($this->fields as $key => $extkey) {
            $this->data[$key] = null;
        }
    }

    public function __isset($key)
    {
        return !is_null($this->data[$key]);
    }

    public function __get($key)
    {
        return $this->data[$key];
    }

    public function rewind()
    {
        reset($this->data);
    }

    public function current()
    {
        return current($this->data);
    }

    public function key()
    {
        return key($this->data);
    }

    public function next()
    {
        return next($this->data);
    }

    public function valid()
    {
        return $this->current() !== false;
    }

    public function getTableName()
    {
        return $this->table;
    }

    public function fillFromArray($arr)
    {
        foreach ($this->fields as $key => $extinfo) {
            if (is_null($extinfo)) {
                continue;
            }
            if (array_key_exists($extinfo[0], $arr)) {
                $val = $arr[$extinfo[0]];
                settype($val, $extinfo[1]);   // convert to needed type
                $this->data[$key] = $val;
            }
        }
    }
}
