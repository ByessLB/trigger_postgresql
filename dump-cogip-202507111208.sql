--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Debian 17.2-1.pgdg120+1)
-- Dumped by pg_dump version 17.0

-- Started on 2025-07-11 12:08:42

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 4 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3413 (class 0 OID 0)
-- Dependencies: 4
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 242 (class 1255 OID 16461)
-- Name: add_days(date, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_days(base_date date, dta integer) RETURNS date
    LANGUAGE plpgsql
    AS $$
	DECLARE
		date_to_add INTERVAL;
	BEGIN
		date_to_add := (dta || ' days')::interval;
		RETURN base_date + date_to_add;
	END;
$$;


ALTER FUNCTION public.add_days(base_date date, dta integer) OWNER TO postgres;

--
-- TOC entry 227 (class 1255 OID 16450)
-- Name: best_supplier(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.best_supplier() RETURNS integer
    LANGUAGE plpgsql
    AS $$
	DECLARE
		supp integer;
	BEGIN
		SELECT s.id INTO supp
		FROM supplier s
		JOIN "order" o
		ON o.supplier_id = s.id
		GROUP BY s.id
		ORDER BY s.id
		LIMIT 1;

		RETURN supp;

	END;
$$;


ALTER FUNCTION public.best_supplier() OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 16463)
-- Name: count_items_by_supplier(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.count_items_by_supplier(id_sup integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
	DECLARE
		supplier_exists BOOLEAN;
		count_items INTEGER;
	BEGIN
		supplier_exists := EXISTS(SELECT * FROM supplier s WHERE s.id = id_sup);
		IF supplier_exists = false THEN
			RAISE EXCEPTION 'L''identifiant % n''existe pas', id_sup
				  USING HINT = 'Verifiez l''identifiant du fournisseur';
		ELSE
			SELECT COUNT(*) INTO count_items
			FROM item i
			JOIN sale_offer so ON so.item_id = i.id
			WHERE so.supplier_id = id_sup;

			RETURN count_items;
		END IF;
	END;
$$;


ALTER FUNCTION public.count_items_by_supplier(id_sup integer) OWNER TO postgres;

--
-- TOC entry 228 (class 1255 OID 16449)
-- Name: count_items_to_order(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.count_items_to_order() RETURNS integer
    LANGUAGE plpgsql
    AS $$
	DECLARE
		article integer;
	BEGIN
		SELECT COUNT(*) INTO article
		FROM item
		WHERE stock < stock_alert;

			RAISE NOTICE 'Stock insuffisant : %', article;

		RETURN article;
	END;
$$;


ALTER FUNCTION public.count_items_to_order() OWNER TO postgres;

--
-- TOC entry 225 (class 1255 OID 16447)
-- Name: format_date(date, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.format_date(date date, separator character varying) RETURNS date
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN TO_CHAR(date, 'DD' || separator || 'MM' || separator || 'YYYY');
	END;
$$;


ALTER FUNCTION public.format_date(date date, separator character varying) OWNER TO postgres;

--
-- TOC entry 226 (class 1255 OID 16448)
-- Name: get_item_count(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_item_count() RETURNS integer
    LANGUAGE plpgsql
    AS $$
	DECLARE
		items_count integer;
		time_now time = now();
	BEGIN
		SELECT count(id) INTO items_count
		FROM item;

		RAISE NOTICE '% articles à %', items_count, time_now;

		RETURN items_count;
	END;
$$;


ALTER FUNCTION public.get_item_count() OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 16466)
-- Name: sales_revenue(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.sales_revenue(sup_id integer, year_entered integer) RETURNS double precision
    LANGUAGE plpgsql
    AS $$
	DECLARE
		ca FLOAT;
		supplier_exist BOOLEAN;
	BEGIN
		supplier_exist := EXISTS(SELECT * FROM supplier s WHERE s.id = sup_id);
		IF NOT supplier_exist THEN
			RAISE EXCEPTION 'L''identifiant : % n''existe pas', sup_id
				  USING HINT = 'Vérifiez l''identifiant du fournisseur';
		END IF;

		SELECT 
			SUM(ol.ordered_qunatity * ol.unit_price) INTO ca
		FROM order_line ol
		JOIN "order" o ON ol.order_id = o.id
		WHERE o.supplier_id = sup_id
		AND EXTRACT(YEAR FROM ol.last_delivery_date) = year_entered;

		RETURN ca * 1.2;
	END;
$$;


ALTER FUNCTION public.sales_revenue(sup_id integer, year_entered integer) OWNER TO postgres;

--
-- TOC entry 229 (class 1255 OID 16459)
-- Name: satisfaction_string_case(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.satisfaction_string_case(sat_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
	DECLARE
		appreciation VARCHAR;
	BEGIN
		appreciation := CASE 
			WHEN sat_id IN (1, 2) THEN 'Mauvais'
			WHEN sat_id IN (3, 4) THEN 'Passab!'
			WHEN sat_id IN (5, 6) THEN 'Moyen'
			WHEN sat_id IN (7, 8) THEN 'Bon'
			WHEN sat_id IN (9, 10) THEN 'Excellent'
			ELSE
				'Sans commentaire'
		END;

		RETURN appreciation;

	END;
$$;


ALTER FUNCTION public.satisfaction_string_case(sat_id integer) OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 16451)
-- Name: satisfaction_string_if(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.satisfaction_string_if(sat_id integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
	DECLARE
		appreciation VARCHAR;
	BEGIN
		IF sat_id = 1 OR sat_id = 2 THEN
			appreciation := 'Mauvais';
		ELSIF sat_id = 3 OR sat_id = 4 THEN
			appreciation := 'Passab!';
		ELSIF sat_id = 5 OR sat_id = 6 THEN
			appreciation := 'Moyen';
		ELSIF sat_id = 7 OR sat_id = 8 THEN
			appreciation := 'Bon';
		ELSIF sat_id = 9 OR sat_id = 10 THEN
			appreciation := 'Excellent';
		ELSE
			appreciation := 'Sans commentaire';
		END IF;

		RETURN appreciation;

	END;
$$;


ALTER FUNCTION public.satisfaction_string_if(sat_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 16393)
-- Name: item; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item (
    id integer NOT NULL,
    item_code character(4) NOT NULL,
    name character varying(50) NOT NULL,
    stock_alert integer NOT NULL,
    stock integer NOT NULL,
    yearly_consumption integer NOT NULL,
    unit character varying(15) NOT NULL
);


ALTER TABLE public.item OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16392)
-- Name: item_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_id_seq OWNER TO postgres;

--
-- TOC entry 3414 (class 0 OID 0)
-- Dependencies: 219
-- Name: item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_id_seq OWNED BY public.item.id;


--
-- TOC entry 223 (class 1259 OID 16413)
-- Name: order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."order" (
    id integer NOT NULL,
    supplier_id integer NOT NULL,
    date date NOT NULL,
    comments character varying(800)
);


ALTER TABLE public."order" OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16412)
-- Name: order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.order_id_seq OWNER TO postgres;

--
-- TOC entry 3415 (class 0 OID 0)
-- Dependencies: 222
-- Name: order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_id_seq OWNED BY public."order".id;


--
-- TOC entry 224 (class 1259 OID 16426)
-- Name: order_line; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.order_line (
    order_id integer NOT NULL,
    item_id integer NOT NULL,
    line_number integer NOT NULL,
    ordered_qunatity integer NOT NULL,
    unit_price double precision NOT NULL,
    delivered_quantity integer,
    last_delivery_date date
);


ALTER TABLE public.order_line OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16399)
-- Name: sale_offer; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sale_offer (
    item_id integer NOT NULL,
    supplier_id integer NOT NULL,
    delivery_time integer NOT NULL,
    price integer NOT NULL,
    date date
);


ALTER TABLE public.sale_offer OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16386)
-- Name: supplier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.supplier (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    address character varying(50) NOT NULL,
    postal_code character varying(5) NOT NULL,
    city character varying(25) NOT NULL,
    contact_name character varying(30) NOT NULL,
    satisfaction_index integer
);


ALTER TABLE public.supplier OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16385)
-- Name: supplier_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.supplier_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.supplier_id_seq OWNER TO postgres;

--
-- TOC entry 3416 (class 0 OID 0)
-- Dependencies: 217
-- Name: supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.supplier_id_seq OWNED BY public.supplier.id;


--
-- TOC entry 3238 (class 2604 OID 16396)
-- Name: item id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item ALTER COLUMN id SET DEFAULT nextval('public.item_id_seq'::regclass);


--
-- TOC entry 3239 (class 2604 OID 16416)
-- Name: order id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order" ALTER COLUMN id SET DEFAULT nextval('public.order_id_seq'::regclass);


--
-- TOC entry 3237 (class 2604 OID 16389)
-- Name: supplier id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier ALTER COLUMN id SET DEFAULT nextval('public.supplier_id_seq'::regclass);


--
-- TOC entry 3403 (class 0 OID 16393)
-- Dependencies: 220
-- Data for Name: item; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.item (id, item_code, name, stock_alert, stock, yearly_consumption, unit) FROM stdin;
0	B001	Bande magnetique 1200	20	87	240	unite
1	B002	Bande magnétique 6250	20	12	410	unite
2	D035	CD R slim 80 mm	40	42	150	B010
3	D050	CD R-W 80mm	50	4	0	B010
4	I100	Papier 1 ex continu	100	557	3500	B1000
5	I105	Papier 2 ex continu	75	5	2300	B1000
6	I108	Papier 3 ex continu	200	557	3500	B500
7	I110	Papier 4 ex continu	10	12	63	B400
8	P220	Pre-imprime commande	500	2500	24500	B500
9	P230	Pre-imprime facture	500	250	12500	B500
10	P240	Pre-imprime bulletin paie	500	3000	6250	B500
11	P250	Pre-imprime bon livraison	500	2500	24500	B500
12	P270	Pre-imprime bon fabricati	500	2500	24500	B500
13	R080	ruban Epson 850	10	2	120	unite
14	14  	ruban impl 1200 lignes	25	200	182	unite
\.


--
-- TOC entry 3406 (class 0 OID 16413)
-- Dependencies: 223
-- Data for Name: order; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."order" (id, supplier_id, date, comments) FROM stdin;
70010	120	2021-01-15	\N
70011	540	2021-01-15	Commande urgente
70020	9180	2021-01-15	\N
70025	9150	2021-01-15	Commande urgente
70210	120	2021-01-15	Commande cadencée
70250	8700	2021-01-15	Commande cadencée
70300	9120	2021-01-15	\N
70620	540	2021-01-15	\N
70625	120	2021-01-15	\N
70629	9180	2021-01-15	\N
\.


--
-- TOC entry 3407 (class 0 OID 16426)
-- Dependencies: 224
-- Data for Name: order_line; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.order_line (order_id, item_id, line_number, ordered_qunatity, unit_price, delivered_quantity, last_delivery_date) FROM stdin;
70010	4	1	3000	470	3000	2021-01-15
70010	5	2	2000	485	2000	2021-01-15
70010	6	3	1000	680	1000	2021-01-15
70010	8	5	6000	999.99	6000	2021-01-15
70010	10	6	6000	999.99	2000	2021-01-15
70010	13	2	10000	999.99	10000	2021-01-15
70011	5	1	1000	600	1000	2021-01-15
70020	0	1	200	140	\N	\N
70020	1	2	200	140	\N	\N
70025	4	1	1000	590	1000	2021-01-15
70025	5	2	500	590	500	2021-01-15
70210	4	1	1000	470	1000	2021-01-15
70250	8	2	10000	999.99	10000	2021-01-15
70250	9	1	15000	999.99	12000	2021-01-15
70300	7	1	50	790	50	2021-01-15
70620	5	1	200	600	200	2021-01-15
70625	4	1	1000	470	1000	2021-01-15
70625	8	2	10000	999.99	10000	2021-01-15
70629	0	1	200	140	\N	\N
70629	1	2	200	140	\N	\N
70010	2	4	200	40	200	2021-01-15
\.


--
-- TOC entry 3404 (class 0 OID 16399)
-- Dependencies: 221
-- Data for Name: sale_offer; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sale_offer (item_id, supplier_id, delivery_time, price, date) FROM stdin;
0	8700	15	150	\N
1	8700	15	210	\N
2	120	0	40	\N
2	9120	5	40	\N
4	120	90	700	\N
4	540	70	710	\N
4	9120	60	800	\N
4	9150	90	650	\N
4	9180	30	720	\N
5	120	90	705	\N
5	540	70	810	\N
5	8700	30	720	\N
5	9120	60	920	\N
5	9150	90	685	\N
6	120	90	795	\N
6	9120	60	920	\N
7	9120	60	950	\N
7	9180	90	900	\N
13	9120	10	120	\N
14	9120	5	275	\N
\.


--
-- TOC entry 3401 (class 0 OID 16386)
-- Dependencies: 218
-- Data for Name: supplier; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.supplier (id, name, address, postal_code, city, contact_name, satisfaction_index) FROM stdin;
120	GROBRIGAN	20 rue du papier	92200	papercity	georges	8
540	ECLIPSE	53 rue laisse flotter	78250	bugbugville	nestor	7
8700	MEDICIS	120 rue des plantes	75014	paris	lison	\N
9120	DICOBOL	11 rue des sports	85100	roche/yon	hercule	8
9150	DEPANPAP	26 av des loco	59987	coroncountry	pollux	5
9180	HURRYTAPE	68 bvd des octets	04044	Dumpville	Track	\N
1	TEST	10 rue du test	17000	La Rochelle	DUfont	3
\.


--
-- TOC entry 3417 (class 0 OID 0)
-- Dependencies: 219
-- Name: item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_id_seq', 1, false);


--
-- TOC entry 3418 (class 0 OID 0)
-- Dependencies: 222
-- Name: order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_id_seq', 1, false);


--
-- TOC entry 3419 (class 0 OID 0)
-- Dependencies: 217
-- Name: supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.supplier_id_seq', 1, false);


--
-- TOC entry 3243 (class 2606 OID 16398)
-- Name: item item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- TOC entry 3249 (class 2606 OID 16440)
-- Name: order_line order_line_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT order_line_pk PRIMARY KEY (order_id, item_id);


--
-- TOC entry 3247 (class 2606 OID 16420)
-- Name: order order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order"
    ADD CONSTRAINT order_pkey PRIMARY KEY (id);


--
-- TOC entry 3245 (class 2606 OID 16442)
-- Name: sale_offer sale_offer_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT sale_offer_pk PRIMARY KEY (item_id, supplier_id);


--
-- TOC entry 3241 (class 2606 OID 16391)
-- Name: supplier supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (id);


--
-- TOC entry 3253 (class 2606 OID 16434)
-- Name: order_line order_line_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT order_line_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item(id);


--
-- TOC entry 3254 (class 2606 OID 16429)
-- Name: order_line order_line_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT order_line_order_id_fkey FOREIGN KEY (order_id) REFERENCES public."order"(id);


--
-- TOC entry 3252 (class 2606 OID 16421)
-- Name: order order_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order"
    ADD CONSTRAINT order_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(id);


--
-- TOC entry 3250 (class 2606 OID 16402)
-- Name: sale_offer sale_offer_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT sale_offer_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item(id);


--
-- TOC entry 3251 (class 2606 OID 16407)
-- Name: sale_offer sale_offer_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT sale_offer_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(id);


-- Completed on 2025-07-11 12:08:42

--
-- PostgreSQL database dump complete
--

