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
