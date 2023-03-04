--
-- PostgreSQL database dump
--

-- Dumped from database version 14.4 (Debian 14.4-1.pgdg110+1)
-- Dumped by pg_dump version 14.6 (Ubuntu 14.6-0ubuntu0.22.10.1)

-- Started on 2023-03-04 18:45:06 CET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 581 (class 1259 OID 42403)
-- Name: publications; Type: TABLE; Schema: rletud; Owner: rletud
--

CREATE TABLE rletud.publications (
    idpublication integer NOT NULL,
    message text,
    date timestamp without time zone,
    idauteur integer
);


ALTER TABLE rletud.publications OWNER TO rletud;

--
-- TOC entry 582 (class 1259 OID 42408)
-- Name: utilisateurs; Type: TABLE; Schema: rletud; Owner: rletud
--

CREATE TABLE rletud.utilisateurs (
    idutilisateur integer NOT NULL,
    login character varying(20),
    password text,
    adressemail text,
    profilepicturename character varying(64)
);


ALTER TABLE rletud.utilisateurs OWNER TO rletud;

--
-- TOC entry 5072 (class 0 OID 42403)
-- Dependencies: 581
-- Data for Name: publications; Type: TABLE DATA; Schema: rletud; Owner: rletud
--

COPY rletud.publications (idpublication, message, date, idauteur) FROM stdin;
1	Un exemple de publication	2023-01-30 14:37:50	1
2	<script>alert("message")</script>	2023-02-25 07:23:09	2
\.


--
-- TOC entry 5073 (class 0 OID 42408)
-- Dependencies: 582
-- Data for Name: utilisateurs; Type: TABLE DATA; Schema: rletud; Owner: rletud
--

COPY rletud.utilisateurs (idutilisateur, login, password, adressemail, profilepicturename) FROM stdin;
1	lebreton	$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i	lebreton@yopmail.com	anonyme.jpg
2	<h1>Login</h1>	$2y$10$RkCmlLZIeJn757hgpiH.2eYXFDc7DeBz6ZFowKmJPxR/IuuI5qO9i	login@yopmail.com	anonyme.jpg
\.


-- Completed on 2023-03-04 18:45:09 CET

--
-- PostgreSQL database dump complete
--

