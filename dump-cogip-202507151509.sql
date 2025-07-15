--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2 (Debian 17.2-1.pgdg120+1)
-- Dumped by pg_dump version 17.0

-- Started on 2025-07-15 15:09:14

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
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3503 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


--
-- TOC entry 242 (class 1255 OID 24635)
-- Name: add_days(date, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_days(date_entered date, days_to_add integer) RETURNS date
    LANGUAGE plpgsql
    AS $$
	DECLARE
		new_date DATE;
	BEGIN
		SELECT date_entered + days_to_add INTO new_date;

		RAISE NOTICE 'Date après ajout de jours : %', new_date;

		RETURN new_date;
	END;
$$;


ALTER FUNCTION public.add_days(date_entered date, days_to_add integer) OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 16450)
-- Name: best_supplier(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.best_supplier() RETURNS integer
    LANGUAGE plpgsql
    AS $$
	DECLARE
		fournisseur integer;
	BEGIN
		SELECT supplier_id INTO fournisseur
		FROM "order"
		GROUP BY supplier_id
		ORDER BY supplier_id
		LIMIT 1;

		RETURN fournisseur;

	END;
$$;


ALTER FUNCTION public.best_supplier() OWNER TO postgres;

--
-- TOC entry 291 (class 1255 OID 32892)
-- Name: check_orderline_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_orderline_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		IF OLD.delivered_quantity < OLD.ordered_qunatity THEN
			RAISE EXCEPTION 'Impossible de supprimer cet enregistrement de livraison.';
		END IF;
		RETURN OLD;
	END;
$$;


ALTER FUNCTION public.check_orderline_delete() OWNER TO postgres;

--
-- TOC entry 290 (class 1255 OID 32888)
-- Name: check_user_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.check_user_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		IF OLD.role = 'MAIN_ADMIN' THEN
			RAISE EXCEPTION 'Impossible de supprimer l''utilisateur %. Il s''agit de l''administrateur principal.', OLD.id;
		END IF;
		RETURN NULL;
	END;
$$;


ALTER FUNCTION public.check_user_delete() OWNER TO postgres;

--
-- TOC entry 287 (class 1255 OID 16463)
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
			SELECT COUNT(item_id) INTO count_items
			FROM sale_offer
			WHERE supplier_id = id_sup;

			RAISE NOTICE '% articles proposé par le fournisseur %', count_items, id_fournisseur;

			RETURN count_items;
		END IF;
	END;
$$;


ALTER FUNCTION public.count_items_by_supplier(id_sup integer) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 16449)
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
-- TOC entry 288 (class 1255 OID 32839)
-- Name: create_user(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.create_user(p_email character varying, p_password character varying, p_role character varying) RETURNS void
    LANGUAGE plpgsql
    AS $_$
	DECLARE
		hashed_password VARCHAR;
		valid_email BOOLEAN;
	BEGIN
		-- Vérification de la longueur du mot de passe
		IF LENGTH(p_password) < 8 THEN
			RAISE EXCEPTION 'Le mot de passe doit contenir au moins 8 caractères';
		END IF;

		-- Vérification du format de l'email
		valid_email := p_email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
		IF NOT valid_email THEN
			RAISE EXCEPTION 'Format de l''email invalide : %', p_email;
		END IF;

		-- Vérification du rôle
		IF p_role NOT IN ('MAIN_ADMIN', 'ADMIN', 'COMMON') THEN
			RAISE EXCEPTION 'Rôle invalide : %, rôle autorisés : MAIN_ADMIN, ADMIN, COMMON', p_role;
		END IF;

		-- Hachage du mot de passe avec SHA1
		hashed_password := encode(digest(p_password, 'sha1'), 'hex');

		-- Insertion de l'utilisateur
		INSERT INTO "user" (email, password, role)
		VALUES (p_email, hashed_password, p_role);

		RAISE NOTICE 'Utilisateur % ajouté avec succès.', p_email;

	END;
$_$;


ALTER FUNCTION public.create_user(p_email character varying, p_password character varying, p_role character varying) OWNER TO postgres;

--
-- TOC entry 293 (class 1255 OID 32884)
-- Name: display_message_on_supplier_insert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.display_message_on_supplier_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RAISE NOTICE '"Un ajout de fournisseur va être fait. Le nouveau fournisseur est %"', NEW.name;
		RETURN NULL;
	END;
$$;


ALTER FUNCTION public.display_message_on_supplier_insert() OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 32885)
-- Name: display_message_on_supplier_update(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.display_message_on_supplier_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RAISE NOTICE '"Mise à jour de la table des fournisseurs. Ancien nom : %; nouveau nom : %."', OLD.name, NEW.name;
		RETURN NULL;
	END;
$$;


ALTER FUNCTION public.display_message_on_supplier_update() OWNER TO postgres;

--
-- TOC entry 233 (class 1255 OID 16447)
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
-- TOC entry 237 (class 1255 OID 16448)
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
-- TOC entry 259 (class 1255 OID 32827)
-- Name: get_items_stock_alert(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_items_stock_alert() RETURNS TABLE(id integer, item_code character, name character varying, stock_difference integer)
    LANGUAGE plpgsql
    AS $$
	BEGIN
		RETURN QUERY
		SELECT
			i.id,
			i.item_code,
			i."name",
			(i.stock_alert - i.stock) AS stock_difference
		FROM
			item i
		WHERE (i.stock_alert - i.stock) >= 0;

	END;
$$;


ALTER FUNCTION public.get_items_stock_alert() OWNER TO postgres;

--
-- TOC entry 297 (class 1255 OID 32931)
-- Name: item_audit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.item_audit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	DECLARE
		operation_type TEXT;
	BEGIN
	IF TG_OP = 'UPDATE' THEN
		operation_type := 'UPDATE';
		INSERT INTO item_audit(operation, old_values, new_values, changed_on)
		VALUES (operation_type, row_to_json(OLD), row_to_json(NEW), now());
		RETURN NEW;
	ELSIF TG_OP = 'INSERT' THEN
		operation_type := 'INSERT';
		INSERT INTO item_audit(operation, new_values, changed_on)
		VALUES (operation_type, row_to_json(NEW), now());
		RETURN NEW;
	ELSIF TG_OP = 'DELETE' THEN
		operation_type := 'DELETE';
		INSERT INTO item_audit(operation, old_values, changed_on)
		VALUES (operation_type, row_to_json(OLD), row());
		RETURN OLD;
	END IF;

	RETURN NULL;
	END;
$$;


ALTER FUNCTION public.item_audit() OWNER TO postgres;

--
-- TOC entry 296 (class 1255 OID 32909)
-- Name: prevent_negative_stock(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prevent_negative_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		IF NEW.stock < 0 THEN
			RAISE EXCEPTION 'Stock négatif interdit pour l''article %. Vérifiez la quantité.', NEW.id;
		END IF;
	
		RETURN NEW;
	END;
$$;


ALTER FUNCTION public.prevent_negative_stock() OWNER TO postgres;

--
-- TOC entry 289 (class 1255 OID 16466)
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
-- TOC entry 274 (class 1255 OID 16459)
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
-- TOC entry 286 (class 1255 OID 16451)
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

--
-- TOC entry 295 (class 1255 OID 32907)
-- Name: update_items_to_order(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_items_to_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
	BEGIN
		IF NEW.stock <= NEW.stock_alert THEN
			IF EXISTS (
				SELECT 1 FROM items_to_order WHERE item_id = new.id
			) THEN
				UPDATE items_to_order
				SET
					quantity = NEW.stock_alert - NEW.stock,
					date_update = CURRENT_DATE
				WHERE item_id = NEW.id;
			ELSE
				INSERT INTO items_to_order(item_id, date_update, quantity)
				VALUES (new.id, CURRENT_DATE, NEW.stock_alert - NEW.stock);
			END IF;
		END IF;

		RETURN NEW;
	END;
$$;


ALTER FUNCTION public.update_items_to_order() OWNER TO postgres;

--
-- TOC entry 292 (class 1255 OID 32883)
-- Name: user_connection(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.user_connection(user_email character varying, user_password character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
	DECLARE
		user_id_reference INTEGER;
		user_password_reference VARCHAR;
		hashed_password VARCHAR;
		current_attempts INTEGER;
		is_blocked BOOLEAN;
	BEGIN
		-- Vérification de l'existance de l'utilisateur
		SELECT id, "password", connexion_attempt, blocked_account
		INTO user_id_reference, user_password_reference, current_attempts, is_blocked
		FROM "user"
		WHERE email = user_email;

		-- S'il n'existe pas -> on retourne FALSE directement
		IF NOT FOUND THEN
			RAISE NOTICE 'L''utilisateur ayant pour email : %, n''existe pas.', user_email;
			RETURN FALSE;
		END IF;

		-- Si le compte est bloqué, on ne va pas plus loin
		IF is_blocked THEN
			RAISE NOTICE 'Le compte de l''utilisateur ayant pour email : %, est bloqué.', user_email;
			RETURN FALSE;
		END IF;

		-- Hachage du pot de passe transmis
		hashed_password := encode(digest(user_password::bytea, 'sha1'), 'hex');

		-- Comparaison avec le mot de passe existant
		IF hashed_password = user_password_reference THEN
			-- Réinitialisation des tentatives, mise à jour de la date de la connexion
			UPDATE "user"
			SET
				last_connection = NOW(),
				connexion_attempt = 0
			WHERE id = user_id_reference;

			RAISE NOTICE 'Connexion réussie pour l''utilisateur ayant pour email : %', user_email;
			RETURN TRUE;
		ELSE
			-- Incrémentation des tentatives
			current_attempts := current_attempts +1;

			-- Mise à jour : soit juste tentative, soit tentative + blocage
			UPDATE "user"
			SET
				connexion_attempt = current_attempts,
				blocked_account = (current_attempts >= 3)
			WHERE id = user_id_reference;

			IF current_attempts >= 3 THEN
				RAISE NOTICE 'Compte bloqué après 3 tentatives pour l''utilisateur ayant pour email : %', user_email;
			ELSE
				RAISE NOTICE 'Mot de passe incorrect pour l''utilisateur ayant pour email : %; tentative n° %.', user_email, current_attempts;
			END IF;

			RETURN FALSE;
		END IF;
	END;
$$;


ALTER FUNCTION public.user_connection(user_email character varying, user_password character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 231 (class 1259 OID 32922)
-- Name: audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit (
    changed_id integer NOT NULL,
    operation character varying(10) NOT NULL,
    old_values text,
    new_values text,
    changed_on timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 32921)
-- Name: audit_changed_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_changed_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_changed_id_seq OWNER TO postgres;

--
-- TOC entry 3504 (class 0 OID 0)
-- Dependencies: 230
-- Name: audit_changed_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_changed_id_seq OWNED BY public.audit.changed_id;


--
-- TOC entry 221 (class 1259 OID 16393)
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
-- TOC entry 220 (class 1259 OID 16392)
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
-- TOC entry 3505 (class 0 OID 0)
-- Dependencies: 220
-- Name: item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_id_seq OWNED BY public.item.id;


--
-- TOC entry 229 (class 1259 OID 32895)
-- Name: items_to_order; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.items_to_order (
    id integer NOT NULL,
    item_id integer,
    quantity integer,
    date_update date
);


ALTER TABLE public.items_to_order OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 32894)
-- Name: items_to_order_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.items_to_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.items_to_order_id_seq OWNER TO postgres;

--
-- TOC entry 3506 (class 0 OID 0)
-- Dependencies: 228
-- Name: items_to_order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.items_to_order_id_seq OWNED BY public.items_to_order.id;


--
-- TOC entry 224 (class 1259 OID 16413)
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
-- TOC entry 223 (class 1259 OID 16412)
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
-- TOC entry 3507 (class 0 OID 0)
-- Dependencies: 223
-- Name: order_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.order_id_seq OWNED BY public."order".id;


--
-- TOC entry 225 (class 1259 OID 16426)
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
-- TOC entry 222 (class 1259 OID 16399)
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
-- TOC entry 219 (class 1259 OID 16386)
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
-- TOC entry 218 (class 1259 OID 16385)
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
-- TOC entry 3508 (class 0 OID 0)
-- Dependencies: 218
-- Name: supplier_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.supplier_id_seq OWNED BY public.supplier.id;


--
-- TOC entry 227 (class 1259 OID 32829)
-- Name: user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."user" (
    id integer NOT NULL,
    email character varying NOT NULL,
    last_connection timestamp without time zone,
    password character varying NOT NULL,
    role character varying NOT NULL,
    connexion_attempt integer DEFAULT 0,
    blocked_account boolean DEFAULT false
);


ALTER TABLE public."user" OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 32828)
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_id_seq OWNER TO postgres;

--
-- TOC entry 3509 (class 0 OID 0)
-- Dependencies: 226
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- TOC entry 3306 (class 2604 OID 32925)
-- Name: audit changed_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit ALTER COLUMN changed_id SET DEFAULT nextval('public.audit_changed_id_seq'::regclass);


--
-- TOC entry 3300 (class 2604 OID 16396)
-- Name: item id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item ALTER COLUMN id SET DEFAULT nextval('public.item_id_seq'::regclass);


--
-- TOC entry 3305 (class 2604 OID 32898)
-- Name: items_to_order id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items_to_order ALTER COLUMN id SET DEFAULT nextval('public.items_to_order_id_seq'::regclass);


--
-- TOC entry 3301 (class 2604 OID 16416)
-- Name: order id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order" ALTER COLUMN id SET DEFAULT nextval('public.order_id_seq'::regclass);


--
-- TOC entry 3299 (class 2604 OID 16389)
-- Name: supplier id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier ALTER COLUMN id SET DEFAULT nextval('public.supplier_id_seq'::regclass);


--
-- TOC entry 3302 (class 2604 OID 32832)
-- Name: user id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- TOC entry 3497 (class 0 OID 32922)
-- Dependencies: 231
-- Data for Name: audit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit (changed_id, operation, old_values, new_values, changed_on) FROM stdin;
\.


--
-- TOC entry 3487 (class 0 OID 16393)
-- Dependencies: 221
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
-- TOC entry 3495 (class 0 OID 32895)
-- Dependencies: 229
-- Data for Name: items_to_order; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.items_to_order (id, item_id, quantity, date_update) FROM stdin;
\.


--
-- TOC entry 3490 (class 0 OID 16413)
-- Dependencies: 224
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
-- TOC entry 3491 (class 0 OID 16426)
-- Dependencies: 225
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
-- TOC entry 3488 (class 0 OID 16399)
-- Dependencies: 222
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
-- TOC entry 3485 (class 0 OID 16386)
-- Dependencies: 219
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
-- TOC entry 3493 (class 0 OID 32829)
-- Dependencies: 227
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."user" (id, email, last_connection, password, role, connexion_attempt, blocked_account) FROM stdin;
2	test@example.com	2025-07-15 11:19:11.136214	1b6d189f62601715f58c410310273479f44caabb	ADMIN	0	f
\.


--
-- TOC entry 3510 (class 0 OID 0)
-- Dependencies: 230
-- Name: audit_changed_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_changed_id_seq', 1, false);


--
-- TOC entry 3511 (class 0 OID 0)
-- Dependencies: 220
-- Name: item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.item_id_seq', 1, false);


--
-- TOC entry 3512 (class 0 OID 0)
-- Dependencies: 228
-- Name: items_to_order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.items_to_order_id_seq', 1, false);


--
-- TOC entry 3513 (class 0 OID 0)
-- Dependencies: 223
-- Name: order_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.order_id_seq', 1, false);


--
-- TOC entry 3514 (class 0 OID 0)
-- Dependencies: 218
-- Name: supplier_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.supplier_id_seq', 1, false);


--
-- TOC entry 3515 (class 0 OID 0)
-- Dependencies: 226
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_id_seq', 2, true);


--
-- TOC entry 3323 (class 2606 OID 32930)
-- Name: audit audit_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit
    ADD CONSTRAINT audit_pkey PRIMARY KEY (changed_id);


--
-- TOC entry 3311 (class 2606 OID 16398)
-- Name: item item_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item
    ADD CONSTRAINT item_pkey PRIMARY KEY (id);


--
-- TOC entry 3321 (class 2606 OID 32900)
-- Name: items_to_order items_to_order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items_to_order
    ADD CONSTRAINT items_to_order_pkey PRIMARY KEY (id);


--
-- TOC entry 3317 (class 2606 OID 16440)
-- Name: order_line order_line_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT order_line_pk PRIMARY KEY (order_id, item_id);


--
-- TOC entry 3315 (class 2606 OID 16420)
-- Name: order order_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order"
    ADD CONSTRAINT order_pkey PRIMARY KEY (id);


--
-- TOC entry 3313 (class 2606 OID 16442)
-- Name: sale_offer sale_offer_pk; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT sale_offer_pk PRIMARY KEY (item_id, supplier_id);


--
-- TOC entry 3309 (class 2606 OID 16391)
-- Name: supplier supplier_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.supplier
    ADD CONSTRAINT supplier_pkey PRIMARY KEY (id);


--
-- TOC entry 3319 (class 2606 OID 32838)
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- TOC entry 3332 (class 2620 OID 32908)
-- Name: item after_update_item_check_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER after_update_item_check_stock AFTER UPDATE ON public.item FOR EACH ROW EXECUTE FUNCTION public.update_items_to_order();


--
-- TOC entry 3330 (class 2620 OID 32887)
-- Name: supplier after_update_supplier; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER after_update_supplier AFTER UPDATE ON public.supplier FOR EACH ROW EXECUTE FUNCTION public.display_message_on_supplier_update();


--
-- TOC entry 3337 (class 2620 OID 32893)
-- Name: order_line before_delete_orderline; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_delete_orderline BEFORE DELETE ON public.order_line FOR EACH ROW EXECUTE FUNCTION public.check_orderline_delete();


--
-- TOC entry 3338 (class 2620 OID 32891)
-- Name: user before_delete_user; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_delete_user BEFORE DELETE ON public."user" FOR EACH ROW EXECUTE FUNCTION public.check_user_delete();


--
-- TOC entry 3331 (class 2620 OID 32886)
-- Name: supplier before_insert_supplier; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_insert_supplier BEFORE INSERT ON public.supplier FOR EACH ROW EXECUTE FUNCTION public.display_message_on_supplier_insert();


--
-- TOC entry 3333 (class 2620 OID 32910)
-- Name: item before_update_prevent_negative_stock; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_update_prevent_negative_stock BEFORE UPDATE ON public.item FOR EACH ROW EXECUTE FUNCTION public.prevent_negative_stock();


--
-- TOC entry 3334 (class 2620 OID 32935)
-- Name: item item_delete_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER item_delete_audit AFTER DELETE ON public.item FOR EACH ROW EXECUTE FUNCTION public.item_audit();


--
-- TOC entry 3335 (class 2620 OID 32934)
-- Name: item item_insert_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER item_insert_audit AFTER INSERT ON public.item FOR EACH ROW EXECUTE FUNCTION public.item_audit();


--
-- TOC entry 3336 (class 2620 OID 32933)
-- Name: item item_update_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER item_update_audit AFTER UPDATE ON public.item FOR EACH ROW EXECUTE FUNCTION public.item_audit();


--
-- TOC entry 3329 (class 2606 OID 32901)
-- Name: items_to_order items_to_order_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.items_to_order
    ADD CONSTRAINT items_to_order_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item(id);


--
-- TOC entry 3327 (class 2606 OID 16434)
-- Name: order_line order_line_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT order_line_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item(id);


--
-- TOC entry 3328 (class 2606 OID 16429)
-- Name: order_line order_line_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.order_line
    ADD CONSTRAINT order_line_order_id_fkey FOREIGN KEY (order_id) REFERENCES public."order"(id);


--
-- TOC entry 3326 (class 2606 OID 16421)
-- Name: order order_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."order"
    ADD CONSTRAINT order_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(id);


--
-- TOC entry 3324 (class 2606 OID 16402)
-- Name: sale_offer sale_offer_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT sale_offer_item_id_fkey FOREIGN KEY (item_id) REFERENCES public.item(id);


--
-- TOC entry 3325 (class 2606 OID 16407)
-- Name: sale_offer sale_offer_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sale_offer
    ADD CONSTRAINT sale_offer_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES public.supplier(id);


-- Completed on 2025-07-15 15:09:14

--
-- PostgreSQL database dump complete
--

