<?php

namespace OwntracksRecorder;

class Gpx
{
    private $dom;
    private $root;
    private $meta;
    private $trk;
    private $trkseg;

    public function __construct()
    {
        $this->dom = new \DOMDocument('1.0', 'utf-8');
        $this->dom->formatOutput = true;
        $gpx = $this->dom->createElement('gpx');
        $gpx->setAttribute('creator', 'php-owntracks-recorder');
        $gpx->setAttribute('version', '1.1');
        $gpx->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns', 'http://www.topografix.com/GPX/1/1');
        $gpx->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        $gpx->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:ns2', 'http://www.garmin.com/xmlschemas/GpxExtensions/v3');
        $gpx->setAttributeNS('http://www.w3.org/2000/xmlns/', 'xmlns:ns3', 'http://www.garmin.com/xmlschemas/TrackPointExtension/v1');
        $gpx->setAttribute('xsi:schemaLocation', 'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/11.xsd');
        $this->root = $gpx;
        $this->dom->appendChild($this->root);
    }

    private function addMeta($domNode)
    {
        if (is_null($this->meta)) {
            $this->meta = $this->dom->createElement('metadata');
            $this->meta->appendChild($this->dom->createElement('time', date('c')));
            $this->root->appendChild($this->meta);
        }
        $this->meta->appendChild($domNode);
    }

    public function addLink($url, $title)
    {
        $link = $this->dom->createElement('link');
        $link->setAttribute('href', $url);
        $link->appendChild($this->dom->createElement('text', $title));
        $this->addMeta($link);
    }

    public function addTrack($title, $type)
    {
        $this->trk = $this->dom->createElement('trk');
        $this->trk->appendChild($this->dom->createElement('name', $title));
        $this->trk->appendChild($this->dom->createElement('type', $type));
        $this->root->appendChild($this->trk);
    }

    public function addPoint(\DOMNode $domNode)
    {
        if (is_null($this->trk)) {
            $this->addTrack('Unknown', 'other');
        }
        if (is_null($this->trkseg)) {
            $this->trkseg = $this->dom->createElement('trkseg');
            $this->trk->appendChild($this->trkseg);
        }
        $trkpti = $this->dom->importNode($domNode, true);
        $this->trkseg->appendChild($trkpti);
    }

    public function getXml()
    {
        return $this->dom->saveXML();
    }
}
