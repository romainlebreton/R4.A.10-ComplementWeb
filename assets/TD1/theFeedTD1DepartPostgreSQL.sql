--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';

CREATE TABLE utilisateurs (
    idutilisateur integer NOT NULL,
    login character varying(20),
    password text,
    adressemail text,
    profilepicturename character varying(64)
);

CREATE TABLE publications (
    idpublication integer NOT NULL,
    message text,
    date timestamp without time zone,
    idauteur integer
);

INSERT INTO utilisateurs VALUES (1, 'lebreton', '$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i', 'lebreton@yopmail.com', 'anonyme.jpg');
INSERT INTO utilisateurs VALUES (2, '<h1>Login</h1>', '$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i', 'login@yopmail.com', 'anonyme.jpg');

INSERT INTO publications VALUES (1, 'Un exemple de publication', '2023-01-30 14:37:50', 1);
INSERT INTO publications VALUES (2, '<script>alert("message")</script>', '2023-02-25 07:23:09', 2);

ALTER TABLE ONLY publications
    ADD CONSTRAINT publications_pk PRIMARY KEY (idpublication);

ALTER TABLE ONLY utilisateurs
    ADD CONSTRAINT utilisateurs_pk PRIMARY KEY (idutilisateur);

ALTER TABLE ONLY publications
    ADD CONSTRAINT publications_fk FOREIGN KEY (idauteur) REFERENCES rletud.utilisateurs(idutilisateur) ON UPDATE CASCADE ON DELETE CASCADE;
