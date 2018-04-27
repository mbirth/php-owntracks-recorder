PRAGMA journal_mode=WAL;

CREATE TABLE "locations" (
  "dt" INTEGER NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "accuracy" INTEGER,
  "altitude" INTEGER,
  "battery_level" INTEGER,
  "heading" INTEGER,
  "description" TEXT,
  "event" TEXT,
  "latitude" REAL NOT NULL,
  "longitude" REAL NOT NULL,
  "radius" INTEGER,
  "trig" INTEGER,
  "tracker_id" TEXT NOT NULL,
  "epoch" INTEGER NOT NULL,
  "vertical_accuracy" INTEGER,
  "velocity" INTEGER,
  "pressure" REAL,
  "connection" TEXT,
  "place_id" INTEGER,
  "osm_id" INTEGER,
  "display_name" TEXT
);

CREATE INDEX "idx_getmarkers" ON "locations" (
  "epoch" DESC,
  "accuracy",
  "altitude"
);

CREATE INDEX "idx_epochexisting" ON "locations" (
  "tracker_id",
  "epoch" DESC
);
