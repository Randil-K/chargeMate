-- ============================================================================
-- ChargeMate — PostgreSQL + PostGIS Database Schema
-- Matches the Flutter Domain Entities & Spring Boot REST DTO contracts
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 1. USERS TABLE (Module 1: Authentication & Profile)
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) NOT NULL UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    first_name      VARCHAR(100) NOT NULL,
    last_name       VARCHAR(100) NOT NULL,
    phone           VARCHAR(30),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. VEHICLES TABLE (Module 3: Vehicle Management & Compatibility)
CREATE TABLE vehicles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    spec_id         VARCHAR(64),
    manufacturer    VARCHAR(100) NOT NULL,
    model           VARCHAR(100) NOT NULL,
    model_year      INT NOT NULL,
    nickname        VARCHAR(100),
    battery_kwh     NUMERIC(6, 2) NOT NULL,
    range_km        INT NOT NULL,
    max_ac_kw       NUMERIC(6, 2) NOT NULL,
    max_dc_kw       NUMERIC(6, 2) NOT NULL,
    is_primary      BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE vehicle_connectors (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_id      UUID NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    connector_type  VARCHAR(32) NOT NULL, -- CCS2, CHAdeMO, Type 2, Type 1, GB/T
    max_kw          NUMERIC(6, 2) NOT NULL
);

-- 3. CHARGING STATIONS & POINTS (Module 2: EV Charging Station Finder)
CREATE TABLE charging_stations (
    id              VARCHAR(64) PRIMARY KEY,
    name            VARCHAR(200) NOT NULL,
    address         TEXT NOT NULL,
    city            VARCHAR(100) NOT NULL,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    location        GEOGRAPHY(Point, 4326) GENERATED ALWAYS AS (
                        ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
                    ) STORED,
    operator_name   VARCHAR(120) NOT NULL,
    network         VARCHAR(100) NOT NULL,
    opening_hours   VARCHAR(120) NOT NULL,
    contact_number  VARCHAR(40) NOT NULL,
    status          VARCHAR(32) NOT NULL DEFAULT 'OPERATIONAL',
    last_verified   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    rating          NUMERIC(3, 2) NOT NULL DEFAULT 0.0,
    review_count    INT NOT NULL DEFAULT 0,
    amenities       TEXT[] NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_stations_location ON charging_stations USING GIST (location);
CREATE INDEX idx_stations_city ON charging_stations (city);

CREATE TABLE charging_points (
    id              VARCHAR(64) PRIMARY KEY,
    station_id      VARCHAR(64) NOT NULL REFERENCES charging_stations(id) ON DELETE CASCADE,
    connector_type  VARCHAR(32) NOT NULL, -- CCS2, CHAdeMO, Type 2, Type 1, GB/T
    charging_type   VARCHAR(8) NOT NULL,  -- AC or DC
    power_kw        NUMERIC(6, 2) NOT NULL,
    status          VARCHAR(32) NOT NULL DEFAULT 'AVAILABLE',
    price_per_kwh   NUMERIC(8, 2)         -- LKR
);

-- 4. USER FAVOURITE STATIONS
CREATE TABLE user_favourite_stations (
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    station_id      VARCHAR(64) NOT NULL REFERENCES charging_stations(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, station_id)
);

-- 5. NEARBY PLACES (Module 4: Charge & Explore)
CREATE TABLE nearby_places (
    id                  VARCHAR(64) PRIMARY KEY,
    station_id          VARCHAR(64) NOT NULL REFERENCES charging_stations(id) ON DELETE CASCADE,
    name                VARCHAR(200) NOT NULL,
    category            VARCHAR(40) NOT NULL, -- FOOD_BEVERAGE, SHOPPING, ENTERTAINMENT, TOURISM
    sub_category        VARCHAR(100) NOT NULL,
    address             TEXT NOT NULL,
    latitude            DOUBLE PRECISION NOT NULL,
    longitude           DOUBLE PRECISION NOT NULL,
    distance_meters     INT NOT NULL,
    walking_minutes     INT NOT NULL,
    avg_visit_minutes   INT NOT NULL,
    opening_hours       VARCHAR(120) NOT NULL,
    is_open_now         BOOLEAN NOT NULL DEFAULT TRUE,
    rating              NUMERIC(3, 2) NOT NULL DEFAULT 4.5,
    review_count        INT NOT NULL DEFAULT 0,
    price_level         VARCHAR(40) NOT NULL,
    phone               VARCHAR(40) NOT NULL,
    description         TEXT NOT NULL,
    tags                TEXT[] NOT NULL DEFAULT '{}'
);

CREATE INDEX idx_nearby_places_station ON nearby_places (station_id, category);

-- 6. STATION REVIEWS & COMMUNITY REPORTS (Module 5)
CREATE TABLE station_reviews (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    station_id      VARCHAR(64) NOT NULL REFERENCES charging_stations(id) ON DELETE CASCADE,
    user_id         UUID REFERENCES users(id) ON DELETE SET NULL,
    user_name       VARCHAR(150) NOT NULL,
    user_initials   VARCHAR(8) NOT NULL,
    vehicle_name    VARCHAR(120),
    rating          INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT NOT NULL,
    reported_status VARCHAR(32),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reviews_station ON station_reviews (station_id, created_at DESC);
