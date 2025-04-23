-- The following SQL is to be executed in DuckDB
-- verify that parquet file is readable
select * from "gold_vs_bitcoin.parquet";

-- Install/Load PostgreSQL extension
INSTALL postgres;
LOAD postgres;

-- Connect to the PostgreSQL database (adjust credentials)
ATTACH 'postgresql://postgres:password@localhost:5432/postgres' AS pg_db (TYPE postgres);

-- make sure you can query timescaledb
SELECT extname, extversion FROM pg_db.pg_catalog.pg_extension;

CREATE TABLE IF NOT EXISTS pg_db.gold_vs_bitcoin (
    time TIMESTAMP,
    gold NUMERIC,
    bitcoin NUMERIC
);
-- convert table to timescaledb hypertable
CALL postgres_execute('pg_db', "SELECT create_hypertable('gold_vs_bitcoin', 'time')");

-- insert data from parquet file into timescaledb
-- For best performance make sure data is ordered by time latest to newest
INSERT INTO pg_db.gold_vs_bitcoin
SELECT * FROM read_parquet('gold_vs_bitcoin.parquet') 
ORDER BY time;

select * from pg_db.gold_vs_bitcoin;

