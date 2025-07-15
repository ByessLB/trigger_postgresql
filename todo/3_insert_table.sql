-- ! EXERCICE : Procédure de création d'utilisateur

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


-- ! EXERCICE : Déclencheur de modification de contenu de tables

-- ? Création de la table items_to_order

CREATE TABLE items_to_order (
    id SERIAL PRIMARY KEY,
    item_id INTEGER,
    quantity INTEGER,
    date_update DATE,
    FOREIGN KEY (item_id) REFERENCES item(id)
    );

-- ! EXERCICE : Table d'audit

-- ? Création de table audit

CREATE TABLE item_audit (
	changed_id SERIAL PRIMARY KEY,
	operation VARCHAR(10) NOT NULL,
	old_values TEXT,
	new_values TEXT,
	changed_on TIMESTAMPTZ NOT NULL DEFAULT now()
);