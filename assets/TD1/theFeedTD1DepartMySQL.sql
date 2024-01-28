SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `thefeed`
--

-- --------------------------------------------------------

--
-- Structure de la table `publications`
--

CREATE TABLE `publications` (
`idPublication` int NOT NULL,
`message` text,
`date` datetime DEFAULT NULL,
`idAuteur` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

--
-- Déchargement des données de la table `publications`
--

INSERT INTO `publications` (`idPublication`, `message`, `date`, `idAuteur`) VALUES
(1, 'Un exemple de publication', '2023-01-30 14:37:50', 1),
(2, '<script>alert(\"message\")</script>', '2023-02-25 07:23:09', 2);

-- --------------------------------------------------------

--
-- Structure de la table `utilisateurs`
--

CREATE TABLE `utilisateurs` (
`idUtilisateur` int NOT NULL,
`login` varchar(20) DEFAULT NULL,
`mdpHache` text,
`email` varchar(256) DEFAULT NULL,
`nomPhotoDeProfil` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Déchargement des données de la table `utilisateurs`
--

INSERT INTO `utilisateurs` (`idUtilisateur`, `login`, `mdpChiffre`, `email`, `nomPhotoDeProfil`) VALUES
(1, 'lebreton', '$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i', 'lebreton@yopmail.com', 'anonyme.jpg'),
(2, '<h1>Login</h1>', '$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i', 'login@yopmail.com', 'anonyme.jpg');

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `publications`
--
ALTER TABLE `publications`
ADD PRIMARY KEY (`idPublication`),
ADD KEY `publications_FK` (`idAuteur`);

--
-- Index pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
ADD PRIMARY KEY (`idUtilisateur`),
ADD UNIQUE KEY `utilisateurs_UN` (`login`),
ADD UNIQUE KEY `utilisateurs_UN2` (`email`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `publications`
--
ALTER TABLE `publications`
MODIFY `idPublication` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT pour la table `utilisateurs`
--
ALTER TABLE `utilisateurs`
MODIFY `idUtilisateur` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `publications`
--
ALTER TABLE `publications`
ADD CONSTRAINT `publications_FK` FOREIGN KEY (`idAuteur`) REFERENCES `utilisateurs` (`idUtilisateur`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;