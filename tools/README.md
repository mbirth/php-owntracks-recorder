Google Location History Import
==============================

This allows you to import your Google Location History (incl. old Google Latitude) data into the
database.

1. Go to [Google Takeout](https://takeout.google.com/).
2. Disable all options by clicking on "SELECT NONE".
3. Find the entry "Location History" and enable it. Make sure the format is set to "JSON".
4. Go to the bottom and click "NEXT". Follow the steps to the end.
5. Wait until you get the completion notification and download the file.
6. Unpack the file and find the `Location History.json`.
7. Put the `Location History.json` in this directory.
8. Modify the `import_google_history.php` and set your desired tracker id in line 5.
9. Run:
   ```
   php import_google_history.php
   ```

Notes
-----

* `LatitudeE7` and `LongitudeE7` have to be divided by 1e7 to get the float value
* `velocity` is in metres per second (multiply by 3.6 to get km/h)
