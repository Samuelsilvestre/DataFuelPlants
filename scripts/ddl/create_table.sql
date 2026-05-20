
-- =====================================================
-- SCRIPT DDL - MODELAGEM DO BANCO db_plant (V2.0)
-- Branch: feat-scripts-DDL
-- =====================================================

-- 1. TABELA DE CIDADES (PLANTAS)
CREATE TABLE cities (
    id_city SERIAL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    zone VARCHAR(50) NOT NULL,
    CONSTRAINT pk_cities PRIMARY KEY (id_city),
    CONSTRAINT uq_city_name UNIQUE (city) -- Impede cidades duplicadas
);

-- 2. TABELA DE COMBUSTÍVEIS
CREATE TABLE fuel (
    id_fuel SERIAL,
    type VARCHAR(50) NOT NULL,
    category VARCHAR(20) NOT NULL,
    CONSTRAINT pk_fuel PRIMARY KEY (id_fuel),
    CONSTRAINT uq_fuel_type UNIQUE (type), -- Impede combustíveis duplicados
    CONSTRAINT chk_fuel_category CHECK (category IN ('Biofuel', 'Fossil')) -- Valida a categoria
);

-- 3. TABELA DE MATÉRIAS-PRIMAS (RAW MATERIAL)
CREATE TABLE raw_material (
    id_material SERIAL,
    material VARCHAR(100) NOT NULL,
    id_fuel INT NOT NULL,
    CONSTRAINT pk_raw_material PRIMARY KEY (id_material),
    CONSTRAINT uq_material_name UNIQUE (material),
    CONSTRAINT fk_material_fuel FOREIGN KEY (id_fuel)
        REFERENCES fuel (id_fuel) ON DELETE CASCADE
);

-- 4. NOVA TABELA: INVENTÁRIO DE MATÉRIA-PRIMA (SUPPLY CHAIN INICIAL)
-- Controla quantas toneladas de insumo cada cidade tem em estoque
CREATE TABLE raw_material_inventory (
    id_inventory SERIAL,
    id_city INT NOT NULL,
    id_material INT NOT NULL,
    stock_tons NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    last_update DATE NOT NULL,
    CONSTRAINT pk_inventory PRIMARY KEY (id_inventory),
    CONSTRAINT uq_city_material UNIQUE (id_city, id_material), -- Uma linha por material por cidade
    CONSTRAINT fk_inventory_city FOREIGN KEY (id_city) REFERENCES cities (id_city),
    CONSTRAINT fk_inventory_material FOREIGN KEY (id_material) REFERENCES raw_material (id_material),
    CONSTRAINT chk_stock_positive CHECK (stock_tons >= 0) -- Estoque nunca pode ser negativo
);

-- 5. TABELA DE PRODUÇÃO DIÁRIA
CREATE TABLE production (
    id_production SERIAL,
    id_city INT NOT NULL,
    id_fuel INT NOT NULL,
    volume_liters NUMERIC(12, 2) NOT NULL,
    production_date DATE NOT NULL,
    CONSTRAINT pk_production PRIMARY KEY (id_production),
    CONSTRAINT fk_production_city FOREIGN KEY (id_city) REFERENCES cities (id_city),
    CONSTRAINT fk_production_fuel FOREIGN KEY (id_fuel) REFERENCES fuel (id_fuel),
    CONSTRAINT chk_volume_positive CHECK (volume_liters > 0) -- Volume produzido deve ser maior que zero
);