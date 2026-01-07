-- ============================================================================
-- Property Service Schema V1
-- Purpose: Manage hotel/motel metadata for global booking platform
-- Design: DDD Aggregate Root pattern with version control and audit trail
--
-- Design Decisions:
-- 1. No Foreign Keys: App-level integrity for flexibility and performance
-- 2. No ENUMs: VARCHAR for easy type additions without ALTER TABLE
-- 3. JSON type: Native MySQL JSON for validation and query performance
-- 4. POINT + SPATIAL INDEX: Optimized for location-based radius search
-- 5. CHECK constraints: Data quality enforcement (MySQL 8.0+)
-- ============================================================================

-- ============================================================================
-- Core Property Table (Aggregate Root)
-- ============================================================================
CREATE TABLE property (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',

    -- Version Control (Optimistic Lock + Change Tracking)
    version INT NOT NULL DEFAULT 1 COMMENT 'Version for optimistic locking and history tracking',

    -- Category & Status (VARCHAR for flexibility)
    category VARCHAR(20) NOT NULL COMMENT 'Property category: HOTEL | MOTEL | RESORT | HOSTEL | GUESTHOUSE | APARTMENT | VILLA',
    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE'
        COMMENT 'Property status: ACTIVE | PREPARING | TEMPORARILY_CLOSED | PERMANENTLY_CLOSED',

    -- Basic Information (default language, typically English)
    name VARCHAR(200) NOT NULL COMMENT 'Property name (default language)',
    description TEXT NULL COMMENT 'Property description (default language)',

    -- Location Information (integrated into property service)
    country VARCHAR(50) NOT NULL COMMENT 'Country (e.g., South Korea, Japan)',
    state_province VARCHAR(100) NULL COMMENT 'State/Province (e.g., Gyeonggi-do)',
    city VARCHAR(100) NOT NULL COMMENT 'City name',
    district VARCHAR(100) NULL COMMENT 'District/Borough (e.g., Gangnam-gu)',
    neighborhood VARCHAR(100) NULL COMMENT 'Neighborhood (e.g., Yeoksam-dong)',
    address VARCHAR(255) NOT NULL COMMENT 'Street address',
    postal_code VARCHAR(20) NULL COMMENT 'Postal/ZIP code',

    -- Geographic Coordinates (for spatial search)
    latitude DECIMAL(9, 6) NULL COMMENT 'Latitude for mapping',
    longitude DECIMAL(9, 6) NULL COMMENT 'Longitude for mapping',
    location POINT NULL COMMENT 'Geographic point for spatial index (SRID 4326)',

    -- Timezone (for global service)
    timezone VARCHAR(50) NULL COMMENT 'IANA timezone (e.g., Asia/Seoul, America/New_York, Europe/London)',

    -- Contact Information
    phone VARCHAR(20) NULL COMMENT 'Contact phone number (consider E.164 format)',
    email VARCHAR(100) NULL COMMENT 'Contact email',
    website VARCHAR(255) NULL COMMENT 'Official website URL',

    -- Rating & Check-in/out
    star_rating DECIMAL(2, 1) NULL COMMENT 'Star rating (0.0 to 5.0, supports half stars)',
    check_in_time TIME NULL COMMENT 'Standard check-in time (in hotel local timezone)',
    check_out_time TIME NULL COMMENT 'Standard check-out time (in hotel local timezone)',

    -- Policies & Features
    cancellation_policy TEXT NULL COMMENT 'Cancellation policy details (default language)',
    child_policy TEXT NULL COMMENT 'Child accommodation policy (age limits, extra charges, etc.)',
    taxes_fees TEXT NULL COMMENT 'Additional taxes and fees information',
    parking_available BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Parking facility available',
    pet_allowed BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Pets allowed',
    languages_spoken JSON NULL COMMENT 'Languages spoken by staff (e.g., ["en", "ko", "ja"])',

    -- Audit Fields
    created_by BIGINT NULL COMMENT 'User ID who created this property',
    updated_by BIGINT NULL COMMENT 'User ID who last updated this property',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated timestamp',

    PRIMARY KEY (id),

    -- Indexes for search optimization (read-heavy workload)
    KEY idx_property_city_category_status (city, category, status),
    KEY idx_property_country_city (country, city),
    SPATIAL KEY idx_property_location (location),
    KEY idx_property_version (id, version),

    -- CHECK constraints for data quality (MySQL 8.0+)
    CONSTRAINT chk_property_star_rating CHECK (star_rating IS NULL OR (star_rating >= 0.0 AND star_rating <= 5.0)),
    CONSTRAINT chk_property_latitude CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90)),
    CONSTRAINT chk_property_longitude CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Core property metadata table (Aggregate Root)';

-- ============================================================================
-- Property Translations (i18n support for global service)
-- ============================================================================
CREATE TABLE property_translation (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    property_id BIGINT NOT NULL COMMENT 'References property.id (app-level FK)',
    language_code VARCHAR(10) NOT NULL COMMENT 'Language code (ISO 639-1, e.g., en, ko, ja, zh)',
    name VARCHAR(200) NOT NULL COMMENT 'Translated property name',
    description TEXT NULL COMMENT 'Translated property description',
    address VARCHAR(255) NULL COMMENT 'Localized address representation',
    cancellation_policy TEXT NULL COMMENT 'Translated cancellation policy',
    child_policy TEXT NULL COMMENT 'Translated child policy',
    taxes_fees TEXT NULL COMMENT 'Translated taxes and fees information',

    -- Audit Fields
    created_by BIGINT NULL COMMENT 'User ID who created this translation',
    updated_by BIGINT NULL COMMENT 'User ID who last updated this translation',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated timestamp',

    PRIMARY KEY (id),
    UNIQUE KEY uk_property_translation_lang (property_id, language_code),
    KEY idx_property_translation_property (property_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Multi-language translations for properties';

-- ============================================================================
-- Property History (Audit trail & versioning for booking references)
-- Uses JSON for schema flexibility as property columns may change over time
-- ============================================================================
CREATE TABLE property_history (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    property_id BIGINT NOT NULL COMMENT 'References property.id (app-level FK)',
    version INT NOT NULL COMMENT 'Snapshot version number',

    -- Key fields for querying/debugging (extracted from JSON for performance)
    status VARCHAR(30) NOT NULL
        COMMENT 'Status at this version: ACTIVE | PREPARING | TEMPORARILY_CLOSED | PERMANENTLY_CLOSED',

    -- Change Tracking
    change_type VARCHAR(20) NOT NULL
        COMMENT 'Type of change: CREATED | METADATA | IMAGE | AMENITY | CONTACT | POLICY | TRANSLATION | STATUS',
    changed_by BIGINT NULL COMMENT 'User ID who made the change',
    change_reason VARCHAR(255) NULL COMMENT 'Reason for change',
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When this version was created',

    -- Flexible Data Storage (future-proof against schema changes)
    data JSON NOT NULL COMMENT 'Full snapshot of property data including images and amenities',
    diff JSON NULL COMMENT 'Changes from previous version (for efficient audit)',

    PRIMARY KEY (id),
    UNIQUE KEY uk_property_history_version (property_id, version),
    KEY idx_property_history_property (property_id),
    KEY idx_property_history_status (status),
    KEY idx_property_history_changed_by (changed_by),
    KEY idx_property_history_change_type (change_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Version history for properties (audit & booking reference)';

-- ============================================================================
-- Amenities Catalog (Reusable across properties)
-- ============================================================================
CREATE TABLE amenity (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',

    -- Version Control
    version INT NOT NULL DEFAULT 1 COMMENT 'Version for optimistic locking',

    -- Amenity Information
    name VARCHAR(120) NOT NULL COMMENT 'Amenity name (default language)',
    category VARCHAR(120) NULL COMMENT 'Amenity category (e.g., Room, Facility, Service)',
    icon VARCHAR(50) NULL COMMENT 'Icon identifier for UI',

    -- Audit Fields
    created_by BIGINT NULL COMMENT 'User ID who created this amenity',
    updated_by BIGINT NULL COMMENT 'User ID who last updated this amenity',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated timestamp',

    PRIMARY KEY (id),
    UNIQUE KEY uk_amenity_name (name),
    KEY idx_amenity_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Reusable amenity catalog';

-- ============================================================================
-- Amenity Translations (i18n support)
-- ============================================================================
CREATE TABLE amenity_translation (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    amenity_id BIGINT NOT NULL COMMENT 'References amenity.id (app-level FK)',
    language_code VARCHAR(10) NOT NULL COMMENT 'Language code (ISO 639-1)',
    name VARCHAR(120) NOT NULL COMMENT 'Translated amenity name',

    -- Audit Fields
    created_by BIGINT NULL COMMENT 'User ID who created this translation',
    updated_by BIGINT NULL COMMENT 'User ID who last updated this translation',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated timestamp',

    PRIMARY KEY (id),
    UNIQUE KEY uk_amenity_translation_lang (amenity_id, language_code),
    KEY idx_amenity_translation_amenity (amenity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Multi-language translations for amenities';

-- ============================================================================
-- Amenity History (Audit trail & versioning)
-- ============================================================================
CREATE TABLE amenity_history (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    amenity_id BIGINT NOT NULL COMMENT 'References amenity.id (app-level FK)',
    version INT NOT NULL COMMENT 'Snapshot version',

    -- Change Tracking
    change_type VARCHAR(20) NOT NULL COMMENT 'Type of change: CREATED | METADATA | TRANSLATION',
    changed_by BIGINT NULL COMMENT 'User ID who made the change',
    change_reason VARCHAR(255) NULL COMMENT 'Reason for change',
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When this version was created',

    -- Flexible Data Storage
    data JSON NOT NULL COMMENT 'Full snapshot of amenity data',
    diff JSON NULL COMMENT 'Changes from previous version',

    PRIMARY KEY (id),
    UNIQUE KEY uk_amenity_history_version (amenity_id, version),
    KEY idx_amenity_history_amenity (amenity_id),
    KEY idx_amenity_history_changed_by (changed_by),
    KEY idx_amenity_history_change_type (change_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Version history for amenities';

-- ============================================================================
-- Property-Amenity Mapping (Many-to-Many)
-- ============================================================================
CREATE TABLE property_amenity (
    property_id BIGINT NOT NULL COMMENT 'References property.id (app-level FK)',
    amenity_id BIGINT NOT NULL COMMENT 'References amenity.id (app-level FK)',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',

    PRIMARY KEY (property_id, amenity_id),
    KEY idx_property_amenity_amenity (amenity_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Property-Amenity many-to-many relationship';

-- ============================================================================
-- Property Images (Gallery with ordering)
-- Part of Property Aggregate - changes trigger property version increment
-- ============================================================================
CREATE TABLE property_image (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    property_id BIGINT NOT NULL COMMENT 'References property.id (app-level FK)',
    image_url VARCHAR(500) NOT NULL COMMENT 'Image URL (CDN or storage path)',
    alt_text VARCHAR(200) NULL COMMENT 'Alt text for accessibility',
    sort_order INT NOT NULL DEFAULT 0 COMMENT 'Display order',
    is_primary BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Primary/featured image flag',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',

    PRIMARY KEY (id),
    KEY idx_property_image_property (property_id),
    KEY idx_property_image_sort (property_id, sort_order),

    -- Ensure only one primary image per property (MySQL 8.0.13+)
    UNIQUE KEY uk_property_image_one_primary (property_id, is_primary)
        COMMENT 'Ensures only one primary image per property (is_primary=1)',

    -- CHECK constraint for sort_order
    CONSTRAINT chk_property_image_sort_order CHECK (sort_order >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Property image gallery (part of Property aggregate)';

-- ============================================================================
-- Room Types (Room categories per property - separate Aggregate Root)
-- ============================================================================
CREATE TABLE room_type (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    property_id BIGINT NOT NULL COMMENT 'References property.id (app-level FK)',

    -- Version Control (independent from property version)
    version INT NOT NULL DEFAULT 1 COMMENT 'Version for optimistic locking and history tracking',

    -- Basic Information
    name VARCHAR(150) NOT NULL COMMENT 'Room type name (default language)',
    description TEXT NULL COMMENT 'Room type description (default language)',

    -- Capacity & Beds
    max_occupancy INT NOT NULL COMMENT 'Maximum number of guests',
    base_bed_count INT NULL COMMENT 'Number of beds included',
    bed_type VARCHAR(50) NULL COMMENT 'Bed type (e.g., King, Queen, Twin, Double)',

    -- Room Features
    room_size_sqm DECIMAL(6, 2) NULL COMMENT 'Room size in square meters',
    smoking_allowed BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Smoking allowed in room',
    view_type VARCHAR(50) NULL COMMENT 'Room view (e.g., Ocean, City, Garden, Mountain)',

    -- Base Price (actual pricing in inventory service)
    base_price DECIMAL(12, 2) NULL COMMENT 'Reference base price (actual pricing in inventory service)',

    -- Audit Fields
    created_by BIGINT NULL COMMENT 'User ID who created this room type',
    updated_by BIGINT NULL COMMENT 'User ID who last updated this room type',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated timestamp',

    PRIMARY KEY (id),
    KEY idx_room_type_property (property_id),
    KEY idx_room_type_version (id, version),

    -- CHECK constraints for data quality
    CONSTRAINT chk_room_type_max_occupancy CHECK (max_occupancy > 0),
    CONSTRAINT chk_room_type_base_bed_count CHECK (base_bed_count IS NULL OR base_bed_count >= 0),
    CONSTRAINT chk_room_type_room_size CHECK (room_size_sqm IS NULL OR room_size_sqm > 0),
    CONSTRAINT chk_room_type_base_price CHECK (base_price IS NULL OR base_price >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Room type definitions per property (separate Aggregate Root)';

-- ============================================================================
-- Room Type Translations (i18n support)
-- ============================================================================
CREATE TABLE room_type_translation (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    room_type_id BIGINT NOT NULL COMMENT 'References room_type.id (app-level FK)',
    language_code VARCHAR(10) NOT NULL COMMENT 'Language code (ISO 639-1)',
    name VARCHAR(150) NOT NULL COMMENT 'Translated room type name',
    description TEXT NULL COMMENT 'Translated room type description',

    -- Audit Fields
    created_by BIGINT NULL COMMENT 'User ID who created this translation',
    updated_by BIGINT NULL COMMENT 'User ID who last updated this translation',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Last updated timestamp',

    PRIMARY KEY (id),
    UNIQUE KEY uk_room_type_translation_lang (room_type_id, language_code),
    KEY idx_room_type_translation_room_type (room_type_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Multi-language translations for room types';

-- ============================================================================
-- Room Type History (Audit trail & versioning)
-- Uses JSON for schema flexibility
-- ============================================================================
CREATE TABLE room_type_history (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    room_type_id BIGINT NOT NULL COMMENT 'References room_type.id (app-level FK)',
    version INT NOT NULL COMMENT 'Snapshot version',

    -- Change Tracking
    change_type VARCHAR(20) NOT NULL
        COMMENT 'Type of change: CREATED | METADATA | IMAGE | TRANSLATION | PRICING',
    changed_by BIGINT NULL COMMENT 'User ID who made the change',
    change_reason VARCHAR(255) NULL COMMENT 'Reason for change',
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'When this version was created',

    -- Flexible Data Storage
    data JSON NOT NULL COMMENT 'Full snapshot of room type data including images',
    diff JSON NULL COMMENT 'Changes from previous version',

    PRIMARY KEY (id),
    UNIQUE KEY uk_room_type_history_version (room_type_id, version),
    KEY idx_room_type_history_room_type (room_type_id),
    KEY idx_room_type_history_changed_by (changed_by),
    KEY idx_room_type_history_change_type (change_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Version history for room types';

-- ============================================================================
-- Room Type Images (Gallery with ordering)
-- Part of RoomType Aggregate - changes trigger room_type version increment
-- ============================================================================
CREATE TABLE room_type_image (
    id BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Primary key',
    room_type_id BIGINT NOT NULL COMMENT 'References room_type.id (app-level FK)',
    image_url VARCHAR(500) NOT NULL COMMENT 'Image URL (CDN or storage path)',
    alt_text VARCHAR(200) NULL COMMENT 'Alt text for accessibility',
    sort_order INT NOT NULL DEFAULT 0 COMMENT 'Display order',
    is_primary BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Primary/featured image flag',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Created timestamp',

    PRIMARY KEY (id),
    KEY idx_room_type_image_room_type (room_type_id),
    KEY idx_room_type_image_sort (room_type_id, sort_order),

    -- Ensure only one primary image per room type
    UNIQUE KEY uk_room_type_image_one_primary (room_type_id, is_primary)
        COMMENT 'Ensures only one primary image per room type (is_primary=1)',

    -- CHECK constraint for sort_order
    CONSTRAINT chk_room_type_image_sort_order CHECK (sort_order >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Room type image gallery (part of RoomType aggregate)';
