CREATE TABLE IF NOT EXISTS metric_samples (
    id BIGSERIAL,
    metric_name TEXT NOT NULL,
    tags JSONB DEFAULT '{}'::JSONB,
    metric_value DOUBLE PRECISION NOT NULL,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, recorded_at)
)
PARTITION BY RANGE (recorded_at);

CREATE OR REPLACE FUNCTION create_metric_partition(p_year INT)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    start_ts TIMESTAMPTZ := MAKE_TIMESTAMP(p_year, 1, 1, 0, 0, 0)::TIMESTAMPTZ;
    end_ts   TIMESTAMPTZ := MAKE_TIMESTAMP(p_year + 1, 1, 1, 0, 0, 0)::TIMESTAMPTZ;
BEGIN
    EXECUTE FORMAT(
        'CREATE TABLE IF NOT EXISTS metric_samples_%s PARTITION OF metric_samples FOR VALUES FROM (%L) TO (%L);',
        p_year,
        start_ts,
        end_ts
    );
END;$$;

-- pre-create partitions for the upcoming five calendar years
SELECT create_metric_partition(EXTRACT(YEAR FROM NOW())::INT + gs."offset")
FROM generate_series(0, 4) AS gs("offset");

CREATE OR REPLACE FUNCTION ensure_partition()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    PERFORM create_metric_partition(EXTRACT(YEAR FROM NEW.recorded_at)::INT);
    RETURN NEW;
END;$$;

CREATE TRIGGER ensure_metric_partition
    BEFORE INSERT ON metric_samples
    FOR EACH ROW EXECUTE FUNCTION ensure_partition();
