CREATE TABLE `locations` (
  `lid` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `dt` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `accuracy` int(11) DEFAULT NULL,
  `altitude` int(11) DEFAULT NULL,
  `battery_level` int(11) DEFAULT NULL,
  `heading` int(11) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `event` varchar(255) DEFAULT NULL,
  `latitude` decimal(9,6) DEFAULT NULL,
  `longitude` decimal(9,6) DEFAULT NULL,
  `radius` int(11) DEFAULT NULL,
  `trig` varchar(1) DEFAULT NULL,
  `tracker_id` char(2) DEFAULT NULL,
  `epoch` int(11) DEFAULT NULL,
  `vertical_accuracy` int(11) DEFAULT NULL,
  `velocity` int(11) DEFAULT NULL,
  `pressure` decimal(9,6) DEFAULT NULL,
  `connection` varchar(1) DEFAULT NULL,
  `topic` varchar(255) DEFAULT NULL,
  `place_id` int(11) DEFAULT NULL,
  `osm_id` int(11) DEFAULT NULL,
  `display_name` text
) DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;

CREATE INDEX `idx_getmarkers` ON `locations` (`epoch` DESC, `accuracy`, `altitude`);

CREATE INDEX `idx_epochexisting` ON `locations` (`tracker_id`, `epoch` DESC);
