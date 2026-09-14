SELECT
    esquema,
    pg_size_pretty(sum(tamano_bytes)) AS tamano_total
FROM (
    SELECT
        n.nspname AS esquema,
        pg_total_relation_size(c.oid) AS tamano_bytes
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname IN (
        'staging',
        'silver',
        'gold',
        'quarantine',
        'audit'
    )
      AND c.relkind IN ('r', 'm')
) tamanos
GROUP BY esquema
ORDER BY esquema;