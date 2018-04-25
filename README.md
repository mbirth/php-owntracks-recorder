owntracks-php-client
====================

A simple and responsive self-hosted solution to record and map [Owntracks](https://owntracks.org/) [http payloads](http://owntracks.org/booklet/tech/http/).

Screenshots
-----------

### Location records mapping
![Desktop view](docs/screenshot1.png?raw=true)

### Responsible interface & controls
![Responsive view](docs/screenshot2.png?raw=true)


Features
--------

* Owntracks HTTP payloads recoding into database
* Interface to map location records
* Responsive : accessible on mobile and tablet!
* Calendar to select location records period


Installation
------------

### Requirements
- PHP 5.6 or above
- MySQL or equivalent (MariaDB, …) **or** PHP's SQLite3 PDO driver
- self hosted / dedicated server / mutualized hosting

That's it !

### Installation instructions
#### PHP Client
1. Download the source code and copy the content of the directory to your prefered location
2. Edit the `config.inc.sample.php` file to setup access to your database and rename to `config.inc.php` :
```php
	$_config['sql_type']          // database type 'mysql' (MySQL/MariaDB) or 'sqlite'
	$_config['sql_host']          // sql server hostname (only needed for 'mysql')
	$_config['sql_user']          // sql server username (only needed for 'mysql')
	$_config['sql_pass']          // sql server username password (only needed for 'mysql')
	$_config['sql_db']            // database name or SQLite filename
	$_config['sql_prefix']        // table prefix (only needed for 'mysql')
	
	$_config['default_accuracy']  // default maxymum accuracy for location record to be displayed on the map
	
	$_config['enable_geo_reverse'] // set to TRUE to enable geo decoding of location records
	$_config['geo_reverse_lookup_url'] // geodecoding api url, will be appended with lat= & lon= attributes 
```
3. Create datatable using schema_mysql.sql or schema_sqlite.sql (in the 'sql' directory)
4. Make sure you have installed [bower](https://bower.io/) (via [npm](https://nodejs.org/)):
```
sudo -H npm install -g bower
```

   If you don't have access to the root user, you can install it locally:
```
npm install -g --prefix=$HOME bower
export PATH=$HOME/bin:$PATH
```
5. Get [Composer](https://getcomposer.org/download/) and install dependencies (this will call `bower` automatically):
```
./composer.phar install
```

#### Owntracks app
Follow [Owntracks Booklet](http://owntracks.org/booklet/features/settings/) to setup your Owntracks app :

1. Setup your Owntracks app :
  1. Mode : HTTP
  2. URL : http://your_host/your_dir/record.php


Usage
-----

### First time access
Access map of today's recorded locations at : http://your_host/your_dir/

### Navigate through your recorded locations
* Use the "Previous" and "Next" buttons
* Manually change the From / To dates (next to the "Previous" button)

### Adjust map settings
* Use the "Config" button to :
  * Display or hide the individual markers (first and last markers for the period will always be displayed)
  * Change maximum accuracy for displayed location records


Contributing
------------

So far my team is small - just 1 person, but I'm willing to work with you!

I'd really like for you to bring a few more people along to join in.


License
-------

This project is published under the [GNU General Public License v3.0](https://choosealicense.com/licenses/gpl-3.0/)
