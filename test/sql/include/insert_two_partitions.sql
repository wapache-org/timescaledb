\ir create_single_db.sql

\c single

CREATE TABLE PUBLIC."two_Partitions" (
  "timeCustom" BIGINT NOT NULL,
  device_id TEXT NOT NULL,
  series_0 DOUBLE PRECISION NULL,
  series_1 DOUBLE PRECISION NULL,
  series_2 DOUBLE PRECISION NULL,
  series_bool BOOLEAN NULL
);
CREATE INDEX ON PUBLIC."two_Partitions" (device_id, "timeCustom" DESC NULLS LAST) WHERE device_id IS NOT NULL;
CREATE INDEX ON PUBLIC."two_Partitions" ("timeCustom" DESC NULLS LAST, series_0) WHERE series_0 IS NOT NULL;
CREATE INDEX ON PUBLIC."two_Partitions" ("timeCustom" DESC NULLS LAST, series_1)  WHERE series_1 IS NOT NULL;
CREATE INDEX ON PUBLIC."two_Partitions" ("timeCustom" DESC NULLS LAST, series_2) WHERE series_2 IS NOT NULL;
CREATE INDEX ON PUBLIC."two_Partitions" ("timeCustom" DESC NULLS LAST, series_bool) WHERE series_bool IS NOT NULL;
CREATE INDEX ON PUBLIC."two_Partitions" ("timeCustom" DESC NULLS LAST, device_id);

SELECT * FROM create_hypertable('"public"."two_Partitions"'::regclass, 'timeCustom'::name, 'device_id'::name, associated_schema_name=>'_timescaledb_internal'::text, number_partitions => 2);

BEGIN;
\COPY public."two_Partitions" FROM 'data/ds1_dev1_1.tsv' NULL AS '';
COMMIT;

SELECT _timescaledb_meta_api.close_chunk_end_immediate(c.id)
FROM get_open_partition_for_key((SELECT id FROM _timescaledb_catalog.hypertable WHERE table_name = 'two_Partitions'), 'dev1') part
INNER JOIN _timescaledb_catalog.chunk c ON (c.partition_id = part.id);

INSERT INTO public."two_Partitions"("timeCustom", device_id, series_0, series_1) VALUES
(1257987600000000000, 'dev1', 1.5, 1),
(1257987600000000000, 'dev1', 1.5, 2),
(1257894000000000000, 'dev20', 1.5, 1),
(1257894002000000000, 'dev1', 2.5, 3);

INSERT INTO "two_Partitions"("timeCustom", device_id, series_0, series_1) VALUES
(1257894000000000000, 'dev20', 1.5, 2);
