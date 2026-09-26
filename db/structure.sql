CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "subjects" ("id" varchar NOT NULL PRIMARY KEY, "kind" varchar NOT NULL, "title" varchar NOT NULL, "creator" varchar, "external_ids" text, "lat" float, "lng" float, "created_at" datetime(6) NOT NULL);
CREATE INDEX "index_subjects_on_kind" ON "subjects" ("kind") /*application='Lifelog'*/;
CREATE INDEX "index_subjects_on_lat_and_lng" ON "subjects" ("lat", "lng") /*application='Lifelog'*/;
CREATE TABLE IF NOT EXISTS "events" ("id" varchar NOT NULL PRIMARY KEY, "subject_id" varchar NOT NULL, "type" varchar NOT NULL, "occurred_on" varchar, "rating" integer, "note" text, "caused_by" varchar, "created_at" datetime(6) NOT NULL, "source_url" varchar /*application='Lifelog'*/, CONSTRAINT "fk_rails_5feeb690e9"
FOREIGN KEY ("caused_by")
  REFERENCES "events" ("id")
, CONSTRAINT "fk_rails_635245fc67"
FOREIGN KEY ("subject_id")
  REFERENCES "subjects" ("id")
);
CREATE INDEX "index_events_on_subject_id" ON "events" ("subject_id") /*application='Lifelog'*/;
CREATE INDEX "index_events_on_subject_id_and_occurred_on" ON "events" ("subject_id", "occurred_on") /*application='Lifelog'*/;
CREATE INDEX "index_events_on_occurred_on" ON "events" ("occurred_on") /*application='Lifelog'*/;
CREATE VIEW current_state AS
SELECT s.*, e.type AS status, e.occurred_on AS as_of
FROM subjects s
JOIN events e ON e.id = (
  SELECT id FROM events WHERE subject_id = s.id
  ORDER BY occurred_on DESC, created_at DESC, id DESC LIMIT 1
)
 /*application='Lifelog'*/
/* current_state(id,kind,title,creator,external_ids,lat,lng,created_at,status,as_of) */;
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='Lifelog'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" varchar NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='Lifelog'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='Lifelog'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='Lifelog'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20260926000001'),
('20260925032621'),
('20260925000002'),
('20260925000001'),
('20260809000002'),
('20260809000001');

