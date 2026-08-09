CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "subjects" ("id" varchar NOT NULL PRIMARY KEY, "kind" varchar NOT NULL, "title" varchar NOT NULL, "creator" varchar, "external_ids" text, "lat" float, "lng" float, "created_at" datetime(6) NOT NULL);
CREATE INDEX "index_subjects_on_kind" ON "subjects" ("kind") /*application='Lifelog'*/;
CREATE INDEX "index_subjects_on_lat_and_lng" ON "subjects" ("lat", "lng") /*application='Lifelog'*/;
CREATE TABLE IF NOT EXISTS "events" ("id" varchar NOT NULL PRIMARY KEY, "subject_id" varchar NOT NULL, "type" varchar NOT NULL, "occurred_on" date NOT NULL, "rating" integer, "note" text, "caused_by" varchar, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_635245fc67"
FOREIGN KEY ("subject_id")
  REFERENCES "subjects" ("id")
, CONSTRAINT "fk_rails_5feeb690e9"
FOREIGN KEY ("caused_by")
  REFERENCES "events" ("id")
);
CREATE INDEX "index_events_on_subject_id" ON "events" ("subject_id") /*application='Lifelog'*/;
CREATE INDEX "index_events_on_subject_id_and_occurred_on" ON "events" ("subject_id", "occurred_on") /*application='Lifelog'*/;
CREATE INDEX "index_events_on_occurred_on" ON "events" ("occurred_on") /*application='Lifelog'*/;
CREATE VIEW current_state AS
SELECT s.*, e.type AS status, e.occurred_on AS as_of
FROM subjects s
JOIN events e ON e.id = (
  SELECT id FROM events WHERE subject_id = s.id
  ORDER BY occurred_on DESC, id DESC LIMIT 1
)
 /*application='Lifelog'*/
/* current_state(id,kind,title,creator,external_ids,lat,lng,created_at,status,as_of) */;
INSERT INTO "schema_migrations" (version) VALUES
('20260809000002'),
('20260809000001');

