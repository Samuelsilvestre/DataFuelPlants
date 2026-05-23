

---=====================---
---=== Metricas 2026 ===---
WITH metrics_2026 AS (
    SELECT
        f.id_fuel,
        f.category,
        f.type,
        SUM(p.volume_liters) AS volume_2026,
        ROUND(
            SUM(p.volume_liters) /
            SUM(SUM(p.volume_liters)) OVER() * 100.0, 2
        ) AS PCT
    FROM fuel AS f
    LEFT JOIN production AS p ON p.id_fuel = f.id_fuel 
    WHERE EXTRACT(YEAR FROM p.production_date) = 2026
    GROUP BY f.id_fuel, f.category, f.type
)
SELECT * FROM metrics_2026
ORDER BY PCT DESC;



---=============================---
---=== Metricas 2027 ===---
WITH metrics_2027 AS (
    SELECT 
        f.id_fuel,
        f.category,
        f.type,
        SUM(p.volume_liters)  AS volume_2027,
        ROUND(
            SUM(p.volume_liters) / 
            SUM(SUM(p.volume_liters)) OVER() * 100.0, 2
        ) AS PCT
    FROM fuel AS f
    LEFT JOIN production AS p ON f.id_fuel = p.id_fuel    
    WHERE EXTRACT(YEAR FROM p.production_date) = 2027
    GROUP BY f.id_fuel, f.category, f.type
)
SELECT * FROM metrics_2027
ORDER BY PCT DESC;


---==========================================---
---Metrica de crescimento ---
WITH metrics_growf AS (
    SELECT
        f.id_fuel,
        f.category,
        f.type,
        TO_CHAR(p.production_date, 'YYYY-MM') AS month,
        SUM(p.volume_liters) AS volume
    FROM fuel AS f
    LEFT JOIN production AS p ON f.id_fuel = p.id_fuel
    -- Correção 1: Ajustado para 1, 2, 3, 4 para incluir o 'mount'
    GROUP BY 1, 2, 3, 4
)
SELECT
    category, type, month, volume,
    ROUND(
        ((volume - LAG(volume) OVER(PARTITION BY category, type ORDER BY month)) /
        LAG(volume) OVER(PARTITION BY category, type ORDER BY month)) * 100, 2
    ) AS growf_month
FROM metrics_growf
ORDER BY 2, 3, 4;