-- HimotheeCore Stage 1E - non-destructive ps-housing schema.
-- Based on the upstream QBOX properties schema, intentionally without the
-- upstream DROP TABLE so txAdmin redeploys can never erase player housing.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `properties` (
    `property_id` int(11) NOT NULL AUTO_INCREMENT,
    `owner_citizenid` varchar(50) NULL,
    `street` varchar(100) NULL,
    `region` varchar(100) NULL,
    `description` longtext NULL,
    `has_access` json NULL DEFAULT (JSON_ARRAY()),
    `extra_imgs` json NULL DEFAULT (JSON_ARRAY()),
    `furnitures` json NULL DEFAULT (JSON_ARRAY()),
    `for_sale` boolean NOT NULL DEFAULT 1,
    `price` int(11) NOT NULL DEFAULT 0,
    `shell` varchar(50) NOT NULL,
    `apartment` varchar(50) NULL DEFAULT NULL,
    `door_data` json NULL DEFAULT NULL,
    `garage_data` json NULL DEFAULT NULL,
    `zone_data` json NULL DEFAULT NULL,
    PRIMARY KEY (`property_id`),
    CONSTRAINT `FK_owner_citizenid` FOREIGN KEY (`owner_citizenid`) REFERENCES `players` (`citizenid`) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT `UQ_owner_apartment` UNIQUE (`owner_citizenid`, `apartment`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
