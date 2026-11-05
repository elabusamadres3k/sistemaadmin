-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Versión del servidor:         26.10.0 - MySQL Community Server - GPL
-- SO del servidor:              Win64
-- HeidiSQL Versión:             12.22.0.7382
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Volcando estructura de base de datos para felipe6_local
CREATE DATABASE IF NOT EXISTS `felipe6_local` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `felipe6_local`;

-- Volcando estructura para tabla felipe6_local.chat_messages
CREATE TABLE IF NOT EXISTS `chat_messages` (
  `message_id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `chat_id` char(36) NOT NULL,
  `text` text,
  `image_url` varchar(2048) DEFAULT NULL,
  `video_url` varchar(2048) DEFAULT NULL,
  `timestamp` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`message_id`),
  KEY `idx_messages_chat_time` (`chat_id`,`timestamp`),
  KEY `fk_messages_user` (`user_id`),
  CONSTRAINT `fk_messages_chat` FOREIGN KEY (`chat_id`) REFERENCES `chats` (`chat_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_messages_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `chk_message_has_content` CHECK (((`text` is not null) or (`image_url` is not null) or (`video_url` is not null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.chat_messages: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.chat_participants
CREATE TABLE IF NOT EXISTS `chat_participants` (
  `chat_id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `joined_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`chat_id`,`user_id`),
  KEY `idx_chat_participants_user` (`user_id`,`chat_id`),
  CONSTRAINT `fk_chat_participants_chat` FOREIGN KEY (`chat_id`) REFERENCES `chats` (`chat_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_chat_participants_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.chat_participants: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.chats
CREATE TABLE IF NOT EXISTS `chats` (
  `chat_id` char(36) NOT NULL,
  `user_a_id` char(36) DEFAULT NULL,
  `user_b_id` char(36) DEFAULT NULL,
  `group_chat_id` char(36) DEFAULT NULL,
  `last_message` text,
  `last_message_time` datetime(3) DEFAULT NULL,
  `last_message_sent_by` char(36) DEFAULT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`chat_id`),
  KEY `idx_chats_user_a` (`user_a_id`),
  KEY `idx_chats_user_b` (`user_b_id`),
  KEY `fk_chats_last_sender` (`last_message_sent_by`),
  CONSTRAINT `fk_chats_last_sender` FOREIGN KEY (`last_message_sent_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_chats_user_a` FOREIGN KEY (`user_a_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_chats_user_b` FOREIGN KEY (`user_b_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `chk_chats_type` CHECK ((((`group_chat_id` is not null) and (`user_a_id` is null) and (`user_b_id` is null)) or ((`group_chat_id` is null) and (`user_a_id` is not null) and (`user_b_id` is not null) and (`user_a_id` <> `user_b_id`))))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.chats: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.dogs
CREATE TABLE IF NOT EXISTS `dogs` (
  `dog_id` char(36) NOT NULL,
  `user_association_id` char(36) NOT NULL,
  `dog_photo_url` varchar(2048) DEFAULT NULL,
  `dog_name` varchar(100) NOT NULL,
  `dog_type` varchar(100) DEFAULT NULL,
  `dog_age` smallint unsigned DEFAULT NULL,
  `dog_bio` text,
  PRIMARY KEY (`dog_id`),
  KEY `idx_dogs_user` (`user_association_id`),
  CONSTRAINT `fk_dogs_user` FOREIGN KEY (`user_association_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.dogs: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.friends
CREATE TABLE IF NOT EXISTS `friends` (
  `follower_id` char(36) NOT NULL,
  `followee_id` char(36) NOT NULL,
  `created_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`follower_id`,`followee_id`),
  KEY `idx_friends_followee` (`followee_id`,`follower_id`),
  CONSTRAINT `fk_friends_followee` FOREIGN KEY (`followee_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_friends_follower` FOREIGN KEY (`follower_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `chk_friends_not_self` CHECK ((`follower_id` <> `followee_id`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.friends: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.post_comments
CREATE TABLE IF NOT EXISTS `post_comments` (
  `comment_id` char(36) NOT NULL,
  `time_posted` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `comment` text NOT NULL,
  `user_id` char(36) NOT NULL,
  `post_id` char(36) NOT NULL,
  `content_status` enum('published','hidden','removed') NOT NULL DEFAULT 'published',
  PRIMARY KEY (`comment_id`),
  KEY `idx_post_comments_post` (`post_id`,`time_posted`),
  KEY `fk_post_comments_user` (`user_id`),
  CONSTRAINT `fk_post_comments_post` FOREIGN KEY (`post_id`) REFERENCES `user_posts` (`post_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_post_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.post_comments: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.roles
CREATE TABLE IF NOT EXISTS `roles` (
  `role_id` tinyint unsigned NOT NULL AUTO_INCREMENT,
  `role_name` varchar(30) NOT NULL,
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uq_roles_name` (`role_name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.roles: ~2 rows (aproximadamente)
REPLACE INTO `roles` (`role_id`, `role_name`) VALUES
	(1, 'user'),
	(2, 'admin');

-- Volcando estructura para tabla felipe6_local.story_comments
CREATE TABLE IF NOT EXISTS `story_comments` (
  `story_comment_id` char(36) NOT NULL,
  `story_association_id` char(36) NOT NULL,
  `comment_user_id` char(36) NOT NULL,
  `comment` text NOT NULL,
  `time_posted` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`story_comment_id`),
  KEY `idx_story_comments_story` (`story_association_id`,`time_posted`),
  KEY `fk_story_comments_user` (`comment_user_id`),
  CONSTRAINT `fk_story_comments_story` FOREIGN KEY (`story_association_id`) REFERENCES `user_stories` (`story_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_story_comments_user` FOREIGN KEY (`comment_user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.story_comments: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.user_posts
CREATE TABLE IF NOT EXISTS `user_posts` (
  `post_id` char(36) NOT NULL,
  `post_photo_url` varchar(2048) DEFAULT NULL,
  `post_title` varchar(200) DEFAULT NULL,
  `post_description` text,
  `post_user_id` char(36) NOT NULL,
  `post_owner_id` char(36) DEFAULT NULL,
  `time_posted` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `num_comments` int unsigned NOT NULL DEFAULT '0',
  `dog_profile_id` char(36) DEFAULT NULL,
  `content_status` enum('published','hidden','removed') NOT NULL DEFAULT 'published',
  PRIMARY KEY (`post_id`),
  KEY `idx_posts_feed` (`content_status`,`time_posted`),
  KEY `idx_posts_user` (`post_user_id`,`time_posted`),
  KEY `fk_posts_owner` (`post_owner_id`),
  KEY `fk_posts_dog` (`dog_profile_id`),
  CONSTRAINT `fk_posts_dog` FOREIGN KEY (`dog_profile_id`) REFERENCES `dogs` (`dog_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_posts_owner` FOREIGN KEY (`post_owner_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  CONSTRAINT `fk_posts_user` FOREIGN KEY (`post_user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.user_posts: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.user_stories
CREATE TABLE IF NOT EXISTS `user_stories` (
  `story_id` char(36) NOT NULL,
  `user_id` char(36) NOT NULL,
  `story_video_url` varchar(2048) DEFAULT NULL,
  `story_photo_url` varchar(2048) DEFAULT NULL,
  `story_description` text,
  `story_posted_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `num_comments` int unsigned NOT NULL DEFAULT '0',
  `expires_at` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`story_id`),
  KEY `idx_stories_feed` (`story_posted_at`),
  KEY `idx_stories_user` (`user_id`,`story_posted_at`),
  CONSTRAINT `fk_stories_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.user_stories: ~0 rows (aproximadamente)

-- Volcando estructura para tabla felipe6_local.users
CREATE TABLE IF NOT EXISTS `users` (
  `user_id` char(36) NOT NULL,
  `display_name` varchar(150) NOT NULL,
  `email` varchar(254) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `photo_url` varchar(2048) DEFAULT NULL,
  `phone_number` varchar(30) DEFAULT NULL,
  `username` varchar(50) NOT NULL,
  `bio` text,
  `short_description` varchar(255) DEFAULT NULL,
  `last_active_time` datetime(3) DEFAULT NULL,
  `role_id` tinyint unsigned NOT NULL DEFAULT '1',
  `title` varchar(120) DEFAULT NULL,
  `account_status` enum('active','suspended') NOT NULL DEFAULT 'active',
  `created_time` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uq_users_email` (`email`),
  UNIQUE KEY `uq_users_username` (`username`),
  KEY `idx_users_role_status` (`role_id`,`account_status`),
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando datos para la tabla felipe6_local.users: ~0 rows (aproximadamente)

-- Autorización por módulos y vistas.
-- `users` y `roles` son los catálogos existentes equivalentes a `usuario` y `rol`.
-- Los tipos de las FK se conservan compatibles con users.user_id (CHAR(36))
-- y roles.role_id (TINYINT UNSIGNED).

-- Volcando estructura para tabla felipe6_local.modulo
CREATE TABLE IF NOT EXISTS `modulo` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre_modulo` varchar(60) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `icono` varchar(50) DEFAULT NULL,
  `orden` int DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_modulo_nombre` (`nombre_modulo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando estructura para tabla felipe6_local.vistas
CREATE TABLE IF NOT EXISTS `vistas` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre_vista` varchar(80) NOT NULL,
  `ruta_acceso` varchar(120) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vistas_ruta` (`ruta_acceso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Volcando estructura para tabla felipe6_local.permisos
CREATE TABLE IF NOT EXISTS `permisos` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nombre_permiso` varchar(50) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_permisos_nombre` (`nombre_permiso`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- `r_usuario_rol` relaciona las cuentas actuales con los roles existentes.
CREATE TABLE IF NOT EXISTS `r_usuario_rol` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` char(36) NOT NULL,
  `rol_id` tinyint unsigned NOT NULL,
  `fecha_asignacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_r_usuario_rol_usuario_rol` (`usuario_id`,`rol_id`),
  KEY `idx_r_usuario_rol_rol` (`rol_id`),
  CONSTRAINT `fk_r_usuario_rol_users` FOREIGN KEY (`usuario_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_r_usuario_rol_roles` FOREIGN KEY (`rol_id`) REFERENCES `roles` (`role_id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `r_modulo_rol` (
  `id` int NOT NULL AUTO_INCREMENT,
  `rol_id` tinyint unsigned NOT NULL,
  `modulo_id` int NOT NULL,
  `habilitado` boolean DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_r_modulo_rol_rol_modulo` (`rol_id`,`modulo_id`),
  KEY `idx_r_modulo_rol_modulo` (`modulo_id`),
  CONSTRAINT `fk_r_modulo_rol_roles` FOREIGN KEY (`rol_id`) REFERENCES `roles` (`role_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_r_modulo_rol_modulo` FOREIGN KEY (`modulo_id`) REFERENCES `modulo` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `vistas_permiso` (
  `id` int NOT NULL AUTO_INCREMENT,
  `r_modulo_rol_id` int NOT NULL,
  `vista_id` int NOT NULL,
  `permiso_id` int NOT NULL,
  `permitido` boolean DEFAULT TRUE,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vistas_permiso_asignacion` (`r_modulo_rol_id`,`vista_id`,`permiso_id`),
  KEY `idx_vistas_permiso_vista` (`vista_id`),
  KEY `idx_vistas_permiso_permiso` (`permiso_id`),
  CONSTRAINT `fk_vistas_permiso_r_modulo_rol` FOREIGN KEY (`r_modulo_rol_id`) REFERENCES `r_modulo_rol` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_vistas_permiso_vistas` FOREIGN KEY (`vista_id`) REFERENCES `vistas` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_vistas_permiso_permisos` FOREIGN KEY (`permiso_id`) REFERENCES `permisos` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `auditoria_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `usuario_id` char(36) DEFAULT NULL,
  `accion` varchar(100) NOT NULL,
  `tabla_afectada` varchar(50) NOT NULL,
  `registro_id` int DEFAULT NULL,
  `fecha_hora` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_auditoria_usuario_fecha` (`usuario_id`,`fecha_hora`),
  CONSTRAINT `fk_auditoria_logs_users` FOREIGN KEY (`usuario_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
