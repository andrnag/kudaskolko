-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               5.1.40-community - MySQL Community Server (GPL)
-- Server OS:                    Win32
-- HeidiSQL version:             7.0.0.4053
-- Date/time:                    2012-12-28 00:09:36
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!40014 SET FOREIGN_KEY_CHECKS=0 */;

-- Dumping database structure for kudaskolko
CREATE DATABASE IF NOT EXISTS `kudaskolko` /*!40100 DEFAULT CHARACTER SET utf8 */;
USE `kudaskolko`;


-- Dumping structure for table kudaskolko.accounts
CREATE TABLE IF NOT EXISTS `accounts` (
  `account_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `name` varchar(50) DEFAULT NULL,
  `paytype` tinyint(3) unsigned DEFAULT NULL,
  `is_visible` tinyint(3) unsigned NOT NULL DEFAULT '1',
  PRIMARY KEY (`account_id`),
  KEY `Index 2` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.accounts_entries
CREATE TABLE IF NOT EXISTS `accounts_entries` (
  `account_id` smallint(6) NOT NULL,
  `operday` int(10) NOT NULL,
  `begin_sum` double DEFAULT NULL,
  `end_sum` double DEFAULT NULL,
  KEY `Index 1` (`account_id`),
  KEY `Index 2` (`operday`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.acl
CREATE TABLE IF NOT EXISTS `acl` (
  `object_id` int(10) unsigned NOT NULL DEFAULT '0',
  `auser_id` int(10) unsigned NOT NULL DEFAULT '0',
  `rights` int(10) unsigned NOT NULL DEFAULT '0',
  UNIQUE KEY `auser_id` (`auser_id`,`object_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.aevent_log
CREATE TABLE IF NOT EXISTS `aevent_log` (
  `aevent_log_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `auser_id` int(10) unsigned NOT NULL DEFAULT '0',
  `event_type` mediumint(9) NOT NULL DEFAULT '256',
  `stat` mediumint(9) NOT NULL,
  `dt` datetime NOT NULL,
  `content` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`aevent_log_id`),
  KEY `ix_aevent_log_0` (`auser_id`,`dt`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.asession
CREATE TABLE IF NOT EXISTS `asession` (
  `asession_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `auser_id` int(10) unsigned NOT NULL DEFAULT '0',
  `sid` varchar(64) NOT NULL,
  `auid` varchar(64) NOT NULL,
  `dt_access` datetime NOT NULL,
  `dt_logon` datetime DEFAULT NULL,
  `dt_logout` datetime DEFAULT NULL,
  PRIMARY KEY (`asession_id`),
  KEY `ix_asession_0` (`auser_id`),
  KEY `ix_asession_1` (`auid`,`dt_access`),
  KEY `ix_asession_2` (`dt_access`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.auser
CREATE TABLE IF NOT EXISTS `auser` (
  `auser_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `auser_type_id` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `rights` int(10) unsigned NOT NULL DEFAULT '0',
  `name` varchar(127) NOT NULL,
  `description` text,
  `email` varchar(63) NOT NULL,
  `passwd` varchar(63) NOT NULL,
  `new_passwd` varchar(63) DEFAULT NULL,
  `dt_register` datetime NOT NULL,
  `dt_logon` datetime DEFAULT NULL,
  `dt_logout` datetime DEFAULT NULL,
  `is_published` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `is_default` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `connections_limit` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `event_type` mediumint(8) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`auser_id`),
  UNIQUE KEY `auser_type_id` (`auser_type_id`,`name`),
  KEY `ix_auser_0` (`auser_type_id`,`is_published`,`dt_logon`),
  KEY `ix_auser_1` (`dt_register`),
  KEY `ix_auser_2` (`auser_type_id`,`name`,`passwd`),
  KEY `ix_auser_3` (`auser_type_id`,`email`,`name`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.auser_to_auser
CREATE TABLE IF NOT EXISTS `auser_to_auser` (
  `auser_id` int(10) unsigned NOT NULL DEFAULT '0',
  `parent_id` int(10) unsigned NOT NULL DEFAULT '0',
  `rights` int(10) unsigned NOT NULL DEFAULT '0',
  UNIQUE KEY `ix_auser_to_auser_0` (`auser_id`,`parent_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.groups
CREATE TABLE IF NOT EXISTS `groups` (
  `gid` smallint(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `group_type` tinyint(3) unsigned DEFAULT NULL,
  PRIMARY KEY (`gid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.items
CREATE TABLE IF NOT EXISTS `items` (
  `iid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `pid` int(10) unsigned NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `level` smallint(6) NOT NULL,
  `unit_id` smallint(5) unsigned DEFAULT NULL,
  `quantity_factor` double unsigned NOT NULL DEFAULT '1',
  `barcode` varchar(20) DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `type` tinyint(3) unsigned DEFAULT NULL,
  `alias_id` int(10) unsigned DEFAULT NULL,
  `user_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`iid`),
  UNIQUE KEY `Index 5` (`barcode`,`name`),
  KEY `Index 2` (`pid`),
  KEY `Index 3` (`name`),
  KEY `Index 4` (`level`),
  KEY `Index 6` (`type`),
  KEY `user_id` (`user_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.items_in_groups
CREATE TABLE IF NOT EXISTS `items_in_groups` (
  `gid` smallint(10) unsigned NOT NULL,
  `iid` int(10) unsigned NOT NULL,
  UNIQUE KEY `Index 1` (`gid`,`iid`),
  KEY `Index 2` (`iid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.nesting_data
CREATE TABLE IF NOT EXISTS `nesting_data` (
  `iid` int(10) unsigned NOT NULL,
  `pid` int(10) unsigned NOT NULL,
  `level` tinyint(3) unsigned NOT NULL,
  `user_id` smallint(5) unsigned NOT NULL,
  `type` tinyint(3) unsigned NOT NULL,
  KEY `Index 3` (`level`),
  KEY `Index 1` (`iid`,`pid`),
  KEY `Index 2` (`pid`),
  KEY `user_id` (`user_id`),
  KEY `type` (`type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.operdays
CREATE TABLE IF NOT EXISTS `operdays` (
  `operday` int(10) NOT NULL,
  PRIMARY KEY (`operday`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.transactions
CREATE TABLE IF NOT EXISTS `transactions` (
  `tid` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'transaction id',
  `operday` int(10) unsigned NOT NULL,
  `account_id_from` smallint(5) unsigned NOT NULL,
  `account_id_to` smallint(5) unsigned NOT NULL,
  `iid` int(10) unsigned NOT NULL,
  `alias_id` int(10) unsigned NOT NULL DEFAULT '0',
  `tdate` datetime NOT NULL,
  `dateadded` datetime NOT NULL,
  `ctid` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'container transaction id',
  `is_displayed` tinyint(3) unsigned NOT NULL DEFAULT '1',
  `amount` double NOT NULL,
  `discount` double NOT NULL,
  `quantity` double unsigned NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `type` tinyint(3) unsigned DEFAULT NULL,
  `user_id` smallint(5) unsigned NOT NULL,
  PRIMARY KEY (`tid`),
  KEY `Index 2` (`operday`),
  KEY `Index 3` (`account_id_from`),
  KEY `Index 4` (`iid`),
  KEY `Index 5` (`tdate`),
  KEY `Index 6` (`type`),
  KEY `Index 7` (`user_id`),
  KEY `Index 8` (`account_id_to`),
  KEY `Index 9` (`ctid`),
  KEY `Index 10` (`is_displayed`),
  KEY `Index 11` (`amount`),
  KEY `Index 12` (`alias_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.transactions_in_groups
CREATE TABLE IF NOT EXISTS `transactions_in_groups` (
  `gid` int(10) unsigned NOT NULL,
  `tid` int(10) unsigned NOT NULL,
  UNIQUE KEY `Index 1` (`gid`,`tid`),
  KEY `Index 2` (`tid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 ROW_FORMAT=FIXED;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.transaction_types
CREATE TABLE IF NOT EXISTS `transaction_types` (
  `type` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL,
  KEY `Index 1` (`type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.units
CREATE TABLE IF NOT EXISTS `units` (
  `unit_id` smallint(3) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `description` varchar(50) DEFAULT NULL,
  `factor` float unsigned NOT NULL DEFAULT '1',
  `base_unit_id` smallint(5) unsigned NOT NULL DEFAULT '0',
  KEY `Index 1` (`unit_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- Data exporting was unselected.


-- Dumping structure for table kudaskolko.users
CREATE TABLE IF NOT EXISTS `users` (
  `user_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `email` varchar(50) NOT NULL,
  `password` varchar(100) DEFAULT NULL,
  `fullname` varchar(50) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='konstantin.konstantinopolskiy@mail.google.com';

-- Data exporting was unselected.
/*!40014 SET FOREIGN_KEY_CHECKS=1 */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
