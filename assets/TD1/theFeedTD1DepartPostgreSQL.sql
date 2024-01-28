--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';

CREATE SEQUENCE utilisateurs_id_seq START WITH 3 INCREMENT BY 1;
CREATE SEQUENCE publications_id_seq START WITH 3 INCREMENT BY 1;

CREATE TABLE utilisateurs (
    idUtilisateur INT NOT NULL DEFAULT NEXTVAL('utilisateurs_id_seq'),
    login character varying(20),
    mdpHache text,
    email text,
    nomPhotoDeProfil character varying(64)
);

CREATE TABLE publications (
    idPublication INT NOT NULL DEFAULT NEXTVAL('publications_id_seq'),
    message text,
    date timestamp without time zone,
    idauteur integer
);

INSERT INTO utilisateurs VALUES (1, 'lebreton', '$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i', 'lebreton@yopmail.com', 'anonyme.jpg');
INSERT INTO utilisateurs VALUES (2, '<h1>Login</h1>', '$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i', 'login@yopmail.com', 'anonyme.jpg');

INSERT INTO publications VALUES (1, 'Un exemple de publication', '2023-01-30 14:37:50', 1);
INSERT INTO publications VALUES (2, '<script>alert("message")</script>', '2023-02-25 07:23:09', 2);

ALTER TABLE ONLY publications
    ADD CONSTRAINT publications_pk PRIMARY KEY ("idPublication");

ALTER TABLE ONLY utilisateurs
    ADD CONSTRAINT utilisateurs_pk PRIMARY KEY ("idUtilisateur");

ALTER TABLE ONLY publications
    ADD CONSTRAINT publications_fk FOREIGN KEY ("idAuteur") REFERENCES utilisateurs("idUtilisateur") ON UPDATE CASCADE ON DELETE CASCADE;
    
    
    
--
-- SCRIPT DROP AU CAS OU
--
    
-- DROP TABLE publications;
-- DROP TABLE utilisateurs;
-- DROP SEQUENCE utilisateurs_id_seq;
-- DROP SEQUENCE publications_id_seq;


--
-- Dans le TD il faudra (dans les classes PublicationsRepository & UtilisateursRepository) modifier les "$data['content']"
-- et mettre TOUS ce qui est contenu dans les 'content' en MINUSCULE !!!!!!!!!!
-- 
-- Credits pour la correction : Cazaux Loris
