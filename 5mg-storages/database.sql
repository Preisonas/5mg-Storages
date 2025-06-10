CREATE TABLE IF NOT EXISTS `5mg_storages` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `owner` varchar(60) DEFAULT NULL,
    `stash_id` varchar(100) DEFAULT NULL,
    `label` varchar(50) DEFAULT 'Storage Unit',
    `capacity` int(11) DEFAULT 10,
    `weight` int(11) DEFAULT 10,
    `level` int(11) DEFAULT 1,
    `icon` varchar(50) DEFAULT 'fas fa-box',
    `shared_access` longtext DEFAULT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
