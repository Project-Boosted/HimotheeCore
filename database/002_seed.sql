-- HimotheeCore v0.1.0 - default seed data

INSERT INTO `himo_jobs` (`name`, `label`, `type`, `default_duty`, `off_duty_pay`, `is_active`)
VALUES ('unemployed', 'Unemployed', 'civilian', 0, 0, 1)
ON DUPLICATE KEY UPDATE
    `label` = VALUES(`label`),
    `type` = VALUES(`type`),
    `is_active` = 1;

INSERT INTO `himo_job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `is_boss`, `permissions`)
VALUES ('unemployed', 0, 'unemployed', 'Unemployed', 0, 0, JSON_OBJECT())
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `label` = VALUES(`label`),
    `salary` = VALUES(`salary`);
