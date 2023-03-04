-- MySQL dump 10.13  Distrib 8.0.32, for Linux (x86_64)
--
-- Host: webinfo.iutmontp.univ-montp2.fr    Database: rletud
-- ------------------------------------------------------
-- Server version	5.5.5-10.5.15-MariaDB-0+deb11u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `publications`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publications` (
  `idPublication` int(11) NOT NULL AUTO_INCREMENT,
  `message` text DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `idAuteur` int(11) DEFAULT NULL,
  PRIMARY KEY (`idPublication`),
  KEY `publications_FK` (`idAuteur`),
  CONSTRAINT `publications_FK` FOREIGN KEY (`idAuteur`) REFERENCES `utilisateurs` (`idUtilisateur`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `publications`
--

LOCK TABLES `publications` WRITE;
/*!40000 ALTER TABLE `publications` DISABLE KEYS */;
INSERT INTO `publications` VALUES (1,'Un exemple de publication','2023-01-30 14:37:50',1),(2,'<script>alert(\"message\")</script>','2023-02-25 07:23:09',2);
/*!40000 ALTER TABLE `publications` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `utilisateurs`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `utilisateurs` (
  `idUtilisateur` int(11) NOT NULL AUTO_INCREMENT,
  `login` varchar(20) DEFAULT NULL,
  `password` text DEFAULT NULL,
  `adresseMail` text DEFAULT NULL,
  `profilePictureName` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`idUtilisateur`),
  UNIQUE KEY `utilisateurs_UN` (`login`),
  UNIQUE KEY `utilisateurs_UN2` (`adresseMail`) USING HASH
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `utilisateurs`
--

LOCK TABLES `utilisateurs` WRITE;
/*!40000 ALTER TABLE `utilisateurs` DISABLE KEYS */;
INSERT INTO `utilisateurs` VALUES (1,'lebreton','$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i','lebreton@yopmail.com','anonyme.jpg'),(2,'<h1>Login</h1>','$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i','login@yopmail.com','anonyme.jpg');
/*!40000 ALTER TABLE `utilisateurs` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2023-02-27 18:20:57
