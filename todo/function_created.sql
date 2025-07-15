-- ! Fonction formatant une date donnée ('DD'/'MM'/'YYYY')

-- DROP FUNCTION public.format_date();

CREATE OR REPLACE FUNCTION public.format_date(date DATE, separator VARCHAR)
	RETURNS date
	LANGUAGE plpgsql
AS $function$
	BEGIN
		RETURN to_char(date, 'DD' || separator || 'MM' || separator || 'YYYY');
	END;
$function$
;


-- ! Fonction affiche et retourne le nbr d'articles total en BDD

-- DROP FUNCTION public.get_item_count();

CREATE OR REPLACE FUNCTION public.get_item_count()
	returns integer
	LANGUAGE plpgsql
AS $function$
	DECLARE
		items_count integer;
		time_now time = now();
	BEGIN
		SELECT count(id) INTO items_count
		FROM item;

		RAISE NOTICE '% articles à %', items_count, time_now;

		RETURN items_count;
	END;
$function$
;


-- ! Fonction affiche message + retourne nbr articles : stock < stock_alert

-- DROP FUNCTION public.count_items_to_order();

CREATE OR REPLACE FUNCTION public.count_items_to_order()
	RETURNS int4
	LANGUAGE plpgsql
AS $function$
	DECLARE
		article integer;
	BEGIN
		SELECT COUNT(*) INTO article
		FROM item
		WHERE stock < stock_alert;

			RAISE NOTICE 'Stock insuffisant : %', article;

		RETURN article;
	END;
$function$
;

-- ! Fonction affiche meilleur fournisseur (+ de commande)

-- DROP FUNCTION public.best_supplier();

CREATE OR REPLACE FUNCTION public.best_supplier()
	RETURNS integer
	LANGUAGE plpgsql
AS $function$
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
$function$
;

-- ! Fonction : affiche "texte" pour satisfaction client du fournisseur (en IF) (param: index_satisfaction)

-- DROP FUNCTION public.satisfaction_string_if();

CREATE OR REPLACE FUNCTION public.satisfaction_string_if(sat_id integer)
	RETURNS varchar
	LANGUAGE plpgsql
AS $function$
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
$function$
;

-- ! Fonction : affiche "texte" pour satisfaction client du fournisseur (en CASE) (param: index_satisfaction)

-- DROP FUNCTION public.satisfaction_string_case();

CREATE OR REPLACE FUNCTION public.satisfaction_string_case(sat_id integer)
	RETURNS varchar
	LANGUAGE plpgsql
AS $function$
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
$function$
;

-- ! Fonction qui rajoutera des jours à une date (param1 : date, param2: jours)

-- DROP FUNCTION public.add_days(DATE, INTEGER);

CREATE OR REPLACE FUNCTION public.add_days(base_date DATE, dta integer)
	RETURNS date
	LANGUAGE plpgsql
AS $function$
	DECLARE
		date_to_add INTERVAL;
	BEGIN
		date_to_add := (dta || ' days')::interval;
		RETURN base_date + date_to_add;
	END;
$function$
;

-- ! Fonction qui retourne le nombre d'articles proposés par un fournisseur
-- ? Gestion d'exception

-- DROP FUNCTION public.count_items_by_supplier(INTEGER);

CREATE OR REPLACE FUNCTION public.count_items_by_supplier(id_sup INTEGER)
	RETURNS integer
	LANGUAGE plpgsql
AS $function$
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
$function$
;

-- * Teste de la fonction
SELECT count_items_by_supplier(120);

-- ! Fonction : calcule de chiffre d'affaire + tva(20%) (param1: id_fournisseur, param2: année)

-- DROP FUNCTION public.sales_revenue(INTEGER, INTEGER);

CREATE OR REPLACE FUNCTION public.sales_revenue(sup_id INTEGER, year_entered INTEGER)
	RETURNS float8
	LANGUAGE plpgsql
AS $function$
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
$function$
;

-- * Teste de la fonction
SELECT sales_revenue(120, 2021);


-- ! Fonction : renvoi un ensemble d'enregistrement (similaire à une table)

-- DROP FUNCTION public.get_items_stock_alert();

CREATE OR REPLACE FUNCTION public.get_items_stock_alert()
	RETURNS TABLE (
		id int,
		item_code character(4),
		"name" varchar,
		stock_difference int
	)
	LANGUAGE plpgsql
AS $function$
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
$function$
;

-- * Teste de la fonction
SELECT * FROM get_items_stock_alert();

-- ! Procédure de création d'utilisateur

-- ? Création de la table "user"

CREATE TABLE "user" (
    id SERIAL PRIMARY KEY,
    email VARCHAR NOT NULL,
    last_connection TIMESTAMP,
    password VARCHAR NOT NULL,
    role VARCHAR NOT NULL,
    connexion_attempt INTEGER DEFAULT 0,
    blocked_account BOOLEAN DEFAULT FALSE
);


-- ? Fonction : création d'utilisateur avec plusieurs vérifications (email, password, role)
--* NE PAS OUBLIER D'AJOUTER L'EXTENSION : pgcrypto

CREATE OR REPLACE FUNCTION create_user(p_email VARCHAR, p_password VARCHAR, p_role VARCHAR)
RETURNS VOID
LANGUAGE plpgsql
AS $$
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
$$;

-- * Test de la fonction
SELECT create_user('test@example.com', 'MonMotDePasse123', 'ADMIN');

-- ! Fonction de connexion d'un utilisateur

-- DROP FUNCTION public.user_connection(VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION public.user_connection(user_email VARCHAR, user_password VARCHAR)
	RETURNS boolean
	LANGUAGE plpgsql
AS $function$
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
$function$
;

-- * Test de la fonction
SELECT user_connection('test@example.com', 'MonMotDePasse123');

-- ! Déclencheurs affichant des messages

-- ? Message avant un "INSERT"

CREATE OR REPLACE FUNCTION public.display_message_on_supplier_insert()
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS $$
	BEGIN
		RAISE NOTICE '"Un ajout de fournisseur va être fait. Le nouveau fournisseur est %"', NEW.name;
		RETURN NULL;
	END;
$$

-- ? Création du déclencheur

CREATE TRIGGER before_insert_supplier -- nom du déclencheur
BEFORE INSERT -- type d'évènement du déclencheur
ON public.supplier -- Nom de la table concernée
FOR EACH ROW -- Quand se déclencher
EXECUTE FUNCTION display_message_on_supplier_insert(); -- appel de la fonction lorsque le déclencheur s'active

-- ? Message après un "UPDATE"

CREATE OR REPLACE FUNCTION public.display_message_on_supplier_update()
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS $$
	BEGIN
		RAISE NOTICE '"Mise à jour de la table des fournisseurs. Ancien nom : %, nouveau nom : %."', OLD.name, NEW.name;
		RETURN NULL;
	END;
$$;

-- ? Création du déclencheur

CREATE TRIGGER after_update_supplier
AFTER UPDATE
ON public.supplier
FOR EACH ROW
EXECUTE FUNCTION display_message_on_supplier_update();

-- ! Déclencheur empéchant une requête

-- ? Empêcher la suppression de l'utilisateur ayant pour rôle "MAIN_ADMIN"

-- DROP FUNCTION public.check_user_delete();

CREATE OR REPLACE FUNCTION public.check_user_delete()
	RETURNS trigger
	LANGUAGE plpgsql
AS $function$
	BEGIN
		IF OLD.role = 'MAIN_ADMIN' THEN
			RAISE EXCEPTION 'Impossible de supprimer l''utilisateur %. Il s''agit de l''administrateur principal.', OLD.id;
		END IF;
		RETURN NULL;
	END;
$function$

-- ? Création du déclencheur (avant suppression)

CREATE TRIGGER before_delete_user
BEFORE DELETE
ON public."user"
FOR EACH ROW -- ROW: pour pouvoir accéder au élément (OLD ou NEW (pas dans ce cas là))
EXECUTE FUNCTION check_user_delete()

-- ? Empêcher la suppression des commandes non livrées

CREATE OR REPLACE FUNCTION public.check_orderline_delete()
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS $$
	BEGIN
		IF OLD.delivered_quantity < OLD.ordered_qunatity THEN
			RAISE EXCEPTION 'Impossible de supprimer cet enregistrement de livraison.';
		END IF;
		RETURN OLD;
	END;
$$;

-- ? Creation du déclencheur

CREATE TRIGGER before_delete_orderline
BEFORE DELETE
ON public.order_line
FOR EACH ROW
EXECUTE FUNCTION check_orderline_delete();

-- ! Déclencheur de modification de contenu de tables

-- ? Création de la table items_to_order

CREATE TABLE items_to_order (
    id SERIAL PRIMARY KEY,
    item_id INTEGER,
    quantity INTEGER,
    date_update DATE,
    FOREIGN KEY (item_id) REFERENCES item(id)
    );

-- ? Fonction pour peupler "items_to_order"

-- DROP FUNCTION public.update_items_to_order();

CREATE OR REPLACE FUNCTION public.update_items_to_order()
	RETURNS trigger
	LANGUAGE plpgsql
AS $function$
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
$function$
;

-- ? Création du déclencheur

CREATE TRIGGER after_update_item_check_stock
AFTER UPDATE ON item
FOR EACH ROW
EXECUTE FUNCTION update_items_to_order();

-- ? Empêcher les stocks négatifs

-- DROP FUNCTION public.prevent_negative_stock();

CREATE OR REPLACE FUNCTION public.prevent_negative_stock()
	RETURNS trigger
	LANGUAGE plpgsql
AS $function$
	BEGIN
		IF NEW.stock < 0 THEN
			RAISE EXCEPTION 'Stock négatif interdit pour l''article %. Vérifiez la quantité.', NEW.id;
		END IF;
	
		RETURN NEW;
	END;
$function$

-- ? Création du céclencheur

CREATE TRIGGER before_update_prevent_negative_stock
BEFORE UPDATE ON item
FOR EACH ROW
EXECUTE FUNCTION prevent_negative_stock();

-- ! Table d'audit

-- ? Création de table audit

CREATE TABLE audit (
	changed_id SERIAL PRIMARY KEY,
	operation VARCHAR(10) NOT NULL,
	old_values TEXT,
	new_values TEXT,
	changed_on TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ? Création de la fonction trigger

CREATE OR REPLACE FUNCTION public.item_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
$$
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

-- ? Création de déclencheur

--* audit UPDATE
CREATE TRIGGER item_update_audit
AFTER UPDATE ON item
FOR EACH ROW
EXECUTE FUNCTION item_audit();

-- * audit INSERT
CREATE TRIGGER item_insert_audit
AFTER INSERT ON item
FOR EACH ROW
EXECUTE FUNCTION item_audit();

-- * audit DELETE
CREATE TRIGGER item_delete_audit
AFTER DELETE ON item
FOR EACH ROW
EXECUTE FUNCTION item_audit();

-- * Lister les trigger initialisés

SELECT event_object_table AS table_name,
       trigger_name,
       action_timing,
       event_manipulation
FROM information_schema.triggers;

-- * Supprimer un trigger

DROP TRIGGER ['nom du trigger'] ON ['nom de la table'];
