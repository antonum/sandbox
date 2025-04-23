\pset pager off
\timing on
\! clear

DROP TABLE IF EXISTS sensor_data CASCADE;

CREATE TABLE sensor_data (
    timestamp TIMESTAMP WITH TIME ZONE,
    sensor_id INTEGER NOT NULL,
    reading1 NUMERIC,
    reading2 NUMERIC
);

-- Convert sensor_data table to TimescaleDB hypertable
SELECT create_hypertable('sensor_data', 'timestamp', chunk_time_interval => INTERVAL '1 minute');

-- Insert some sample data with missing readings
INSERT INTO sensor_data (timestamp, sensor_id, reading1, reading2) VALUES
('2025-04-23 10:00:00+00', 1, 25.5, NULL),
('2025-04-23 10:05:00+00', 1, 24.1, 101),
('2025-04-23 10:10:00+00', 1, NULL, NULL),
('2025-04-23 10:15:00+00', 1, 26.8, 110),
--('2025-04-23 10:20:00+00', 1, NULL, 115),
('2025-04-23 10:25:00+00', 1, 27.3, NULL),
('2025-04-23 10:00:00+00', 2, 12.0, 223),
('2025-04-23 10:05:00+00', 2, NULL, 224),
('2025-04-23 10:10:00+00', 2, 12.5, 220),
('2025-04-23 10:15:00+00', 2, 12.2, NULL),
('2025-04-23 10:20:00+00', 2, NULL, 221),
('2025-04-23 10:25:00+00', 2, 13.1, 225);

select * from sensor_data order by sensor_id, timestamp;

-- LOCF (Last Observation Carried Forward) with gap filling on hypertable
SELECT time_bucket_gapfill('5 minutes', timestamp) AS bucket,
    locf(max(reading1), treat_null_as_missing => true) as reading1,
    locf(max(reading2), treat_null_as_missing => true) as reading2,
    sensor_id
    FROM sensor_data
    WHERE timestamp > '2025-04-23 09:50:00+00'::timestamptz
        AND timestamp < '2025-04-23 10:59:00-00'::timestamptz
    GROUP BY sensor_id, bucket
    ORDER BY sensor_id, bucket desc;

-- create continuous aggregate view
CREATE MATERIALIZED VIEW sensor_data_agg
WITH (timescaledb.continuous) AS
SELECT time_bucket('5 minutes', timestamp) AS bucket,
    sensor_id,
    max(reading1) as reading1,
    max(reading2) as reading2
    FROM sensor_data
    GROUP BY sensor_id, bucket;

-- refresh the materialized view
-- CALL refresh_continuous_aggregate('sensor_data_agg', '2025-04-23 09:50:00+00'::timestamptz, '2025-04-23 10:59:00-00'::timestamptz);

SELECT * FROM sensor_data_agg;

-- query the materialized view with gap filling and LOCF applied at query time
SELECT time_bucket_gapfill('5 minutes', bucket) AS bucket_gapfill,
    locf(max(reading1), treat_null_as_missing => true) as reading1,
    locf(max(reading2), treat_null_as_missing => true) as reading2,
    sensor_id
FROM sensor_data_agg
WHERE bucket > '2025-04-23 09:50:00+00'::timestamptz
    AND bucket < '2025-04-23 10:59:00-00'::timestamptz
GROUP BY bucket_gapfill, sensor_id
ORDER BY sensor_id, bucket_gapfill desc;