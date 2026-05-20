-- =====================================================
-- 1. CADASTRO FIXO DE CIDADES (HUBS ESTRATÉGICOS)
-- =====================================================
INSERT INTO cities (city, country, zone) VALUES
('Rotterdam', 'Netherlands', 'Central Europe'), -- id_city: 1 (Mega Hub)
('Antwerp', 'Belgium', 'Central Europe'),       -- id_city: 2 (Refino Fóssil)
('Hamburg', 'Germany', 'Central Europe'),       -- id_city: 3 (Hub de Aviação / SAF)
('Copenhagen', 'Denmark', 'North Europe'),      -- id_city: 4 (Hub Escandinavo)
('Malmö', 'Sweden', 'North Europe'),            -- id_city: 5 (Polo Ecológico)
('Helsinki', 'Finland', 'North Europe'),        -- id_city: 6 (Tecnologia Bio)
('Gdynia', 'Poland', 'Central Europe'),          -- id_city: 7 (Cinturão Agrícola)
('Le Havre', 'France', 'Central Europe');       -- id_city: 8 (Logística Portuária)

-- =====================================================
-- 2. CADASTRO FIXO DE COMBUSTÍVEIS (PORTFÓLIO COMPLETO)
-- =====================================================
INSERT INTO fuel (type, category) VALUES
('Aviation Kerosene (Jet-A1)', 'Fossil'), -- id_fuel: 1 (Forte da Empresa)
('Bio-kerosene (SAF)', 'Biofuel'),        -- id_fuel: 2 (Forte da Empresa)
('Gasoline', 'Fossil'),                    -- id_fuel: 3
('Biodiesel', 'Biofuel'),                  -- id_fuel: 4
('Ethanol', 'Biofuel');                    -- id_fuel: 5

-- =====================================================
-- 3. CADASTRO FIXO DE MATÉRIAS-PRIMAS (RAW MATERIAL)
-- =====================================================
INSERT INTO raw_material (material, id_fuel) VALUES
('Crude Oil', 1),                -- Petróleo Bruto -> Querosene Fóssil (id_material: 1)
('Used Cooking Oil (UCO)', 2),   -- Óleo Reciclado -> SAF (id_material: 2)
('Animal Fats', 2),              -- Gordura Animal -> SAF (id_material: 3)
('Crude Oil (Gasoline Fraction)', 3), -- Nafta/Petróleo -> Gasolina (id_material: 4)
('Rapeseed Oil', 4),             -- Óleo de Colza -> Biodiesel (id_material: 5)
('Sugar Beet', 5),               -- Beterraba -> Etanol (id_material: 6)
('Wheat', 5);                    -- Trigo -> Etanol (id_material: 7)

-- =====================================================================
-- 4. SIMULAÇÃO HISTÓRICA DE PRODUÇÃO - 3 MESES (Fev/2026 a Maio/2026)
-- Carga Automatizada de Alta Performance (EuroEnergy Mix)
-- =====================================================================
INSERT INTO production (id_city, id_fuel, volume_liters, production_date)
SELECT
    sub.id_city,
    sub.id_fuel,
    -- Corrigido: O cast de tipo ::numeric agora envolve toda a operação matemática antes do ROUND
    ROUND(
        (
            (sub.base_volume * (0.85 + (RANDOM() * 0.25)))
            * (CASE
                WHEN EXTRACT(ISODOW FROM sub.prod_date) IN (6, 7) THEN 0.65
                ELSE 1.0
             END)
        )::numeric
    , 2) AS volume_liters,
    sub.prod_date
FROM (
    SELECT
        days.prod_date::date,
        plant.id_city,
        plant.id_fuel,
        plant.base_volume
    FROM
        GENERATE_SERIES('2026-02-20'::date, '2026-05-20'::date, '1 day'::interval) AS days(prod_date)
    CROSS JOIN (
        VALUES
            (1, 1, 350000.00), -- Rotterdam: Aviation Kerosene (Fóssil - Gigante)
            (1, 2, 110000.00), -- Rotterdam: Bio-kerosene (SAF - Forte da Empresa)
            (1, 3, 200000.00), -- Rotterdam: Gasoline
            (2, 1, 380000.00), -- Antwerp: Aviation Kerosene (Fóssil - Refino de Massa)
            (2, 3, 250000.00), -- Antwerp: Gasoline
            (3, 1, 120000.00), -- Hamburg: Aviation Kerosene
            (3, 2, 95000.00),  -- Hamburg: Bio-kerosene (SAF - Hub Aviação)
            (4, 2, 75000.00),  -- Copenhagen: Bio-kerosene (SAF)
            (4, 4, 80000.00),  -- Copenhagen: Biodiesel
            (5, 4, 90000.00),  -- Malmö: Biodiesel (Polo Ecológico)
            (5, 5, 65000.00),  -- Malmö: Ethanol
            (6, 4, 85000.00),  -- Helsinki: Biodiesel
            (7, 5, 75000.00),  -- Gdynia: Ethanol (Cinturão Agrícola)
            (8, 3, 150000.00), -- Le Havre: Gasoline
            (8, 5, 55000.00)   -- Le Havre: Ethanol
    ) AS plant(id_city, id_fuel, base_volume)
) AS sub
ORDER BY sub.prod_date ASC, sub.id_city ASC;


-- =====================================================================
-- SALTO NO TEMPO - SIMULAÇÃO OPERACIONAL 2026-2027
-- Foco: Virada Tecnológica. Etanol cresce e SAF vira Campeão.
-- Correção: Tipo NUMERIC aplicado no ROUND para PL/pgSQL
-- =====================================================================

DO $$
DECLARE
    last_inserted_date date;
    end_simulation_date date := '2027-12-31';
BEGIN
    -- 1. Descobre automaticamente a última data de produção inserida
    SELECT MAX(production_date) INTO last_inserted_date FROM production;

    -- 2. Informa no console o início da operação
    RAISE NOTICE 'Iniciando simulação incremental de % até %.', (last_inserted_date + INTERVAL '1 day')::date, end_simulation_date;

    -- 3. Insere a produção dia a dia (DML Incremental)
    INSERT INTO production (id_city, id_fuel, volume_liters, production_date)
    SELECT
        sub.id_city,
        sub.id_fuel,
        -- CORREÇÃO AQUI: O cast ::numeric envolve toda a conta matemática antes do ROUND
        ROUND(
            (
                (sub.base_volume_2027 * (0.85 + (RANDOM() * 0.25)))
                * (CASE
                    WHEN EXTRACT(ISODOW FROM sub.prod_date) IN (6, 7) THEN 0.65
                    ELSE 1.0
                 END)
            )::numeric
        , 2) AS volume_liters,
        sub.prod_date
    FROM (
        SELECT
            days.prod_date::date,
            plant.id_city,
            plant.id_fuel,
            plant.base_volume_2027
        FROM
            -- Gera a série da última data + 1 dia até o fim de 2027
            GENERATE_SERIES((last_inserted_date + INTERVAL '1 day')::date, end_simulation_date::date, '1 day'::interval) AS days(prod_date)
        CROSS JOIN (
            -- NOVA CAPACIDADE REALISTA 2027 (Investimentos em Biofúeis)
            VALUES
                (1, 1, 330000.00), -- Rotterdam: Aviation Kerosene
                (1, 2, 220000.00), -- Rotterdam: Bio-kerosene (SAF) -> DOBROU!
                (1, 3, 190000.00), -- Rotterdam: Gasoline
                (2, 1, 370000.00), -- Antwerp: Aviation Kerosene
                (2, 3, 240000.00), -- Antwerp: Gasoline
                (3, 1, 110000.00), -- Hamburg: Aviation Kerosene
                (3, 2, 195000.00), -- Hamburg: Bio-kerosene (SAF) -> DOBROU!
                (4, 2, 85000.00),  -- Copenhagen: Bio-kerosene (SAF)
                (4, 4, 85000.00),  -- Copenhagen: Biodiesel
                (5, 4, 95000.00),  -- Malmö: Biodiesel
                (5, 5, 175000.00), -- Malmö: Ethanol -> TRIPLICOU!
                (6, 4, 90000.00),  -- Helsinki: Biodiesel
                (7, 5, 185000.00), -- Gdynia: Ethanol -> TRIPLICOU!
                (8, 3, 140000.00), -- Le Havre: Gasoline
                (8, 5, 155000.00)  -- Le Havre: Ethanol -> TRIPLICOU!
        ) AS plant(id_city, id_fuel, base_volume_2027)
    ) AS sub;

    RAISE NOTICE 'Simulação de 2026/2027 finalizada com sucesso. EuroEnergy está pronta.';
END $$;