
INSERT INTO public.item VALUES (0, 'B001', 'Bande magnetique 1200', 20, 87, 240, 'unite');
INSERT INTO public.item VALUES (1, 'B002', 'Bande magnétique 6250', 20, 12, 410, 'unite');
INSERT INTO public.item VALUES (2, 'D035', 'CD R slim 80 mm', 40, 42, 150, 'B010');
INSERT INTO public.item VALUES (3, 'D050', 'CD R-W 80mm', 50, 4, 0, 'B010');
INSERT INTO public.item VALUES (4, 'I100', 'Papier 1 ex continu', 100, 557, 3500, 'B1000');
INSERT INTO public.item VALUES (5, 'I105', 'Papier 2 ex continu', 75, 5, 2300, 'B1000');
INSERT INTO public.item VALUES (6, 'I108', 'Papier 3 ex continu', 200, 557, 3500, 'B500');
INSERT INTO public.item VALUES (7, 'I110', 'Papier 4 ex continu', 10, 12, 63, 'B400');
INSERT INTO public.item VALUES (8, 'P220', 'Pre-imprime commande', 500, 2500, 24500, 'B500');
INSERT INTO public.item VALUES (9, 'P230', 'Pre-imprime facture', 500, 250, 12500, 'B500');
INSERT INTO public.item VALUES (10, 'P240', 'Pre-imprime bulletin paie', 500, 3000, 6250, 'B500');
INSERT INTO public.item VALUES (11, 'P250', 'Pre-imprime bon livraison', 500, 2500, 24500, 'B500');
INSERT INTO public.item VALUES (12, 'P270', 'Pre-imprime bon fabricati', 500, 2500, 24500, 'B500');
INSERT INTO public.item VALUES (13, 'R080', 'ruban Epson 850', 10, 2, 120, 'unite');
INSERT INTO public.item VALUES (14, '14  ', 'ruban impl 1200 lignes', 25, 200, 182, 'unite');

--
-- TOC entry 3406 (class 0 OID 25957)
-- Dependencies: 216
-- Data for Name: supplier; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.supplier VALUES (120, 'GROBRIGAN', '20 rue du papier', '92200', 'papercity', 'georges', 8);
INSERT INTO public.supplier VALUES (540, 'ECLIPSE', '53 rue laisse flotter', '78250', 'bugbugville', 'nestor', 7);
INSERT INTO public.supplier VALUES (8700, 'MEDICIS', '120 rue des plantes', '75014', 'paris', 'lison', NULL);
INSERT INTO public.supplier VALUES (9120, 'DICOBOL', '11 rue des sports', '85100', 'roche/yon', 'hercule', 8);
INSERT INTO public.supplier VALUES (9150, 'DEPANPAP', '26 av des loco', '59987', 'coroncountry', 'pollux', 5);
INSERT INTO public.supplier VALUES (9180, 'HURRYTAPE', '68 bvd des octets', '04044', 'Dumpville', 'Track', NULL);
INSERT INTO public.supplier VALUES (1, 'TEST', '10 rue du test', '17000', 'La Rochelle', 'DUfont', 3);

--
-- TOC entry 3408 (class 0 OID 25965)
-- Dependencies: 218
-- Data for Name: order; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public."order" VALUES (70010, 120, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70011, 540, '2021-01-15', 'Commande urgente');
INSERT INTO public."order" VALUES (70020, 9180, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70025, 9150, '2021-01-15', 'Commande urgente');
INSERT INTO public."order" VALUES (70210, 120, '2021-01-15', 'Commande cadencée');
INSERT INTO public."order" VALUES (70250, 8700, '2021-01-15', 'Commande cadencée');
INSERT INTO public."order" VALUES (70300, 9120, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70620, 540, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70625, 120, '2021-01-15', NULL);
INSERT INTO public."order" VALUES (70629, 9180, '2021-01-15', NULL);


--
-- TOC entry 3412 (class 0 OID 25985)
-- Dependencies: 222
-- Data for Name: order_line; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.order_line VALUES (70010, 4, 1, 3000, 470, 3000, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 5, 2, 2000, 485, 2000, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 6, 3, 1000, 680, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 8, 5, 6000, 999.99, 6000, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 10, 6, 6000, 999.99, 2000, '2021-01-15');
INSERT INTO public.order_line VALUES (70010, 13, 2, 10000, 999.99, 10000, '2021-01-15');
INSERT INTO public.order_line VALUES (70011, 5, 1, 1000, 600, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70020, 0, 1, 200, 140, NULL, NULL);
INSERT INTO public.order_line VALUES (70020, 1, 2, 200, 140, NULL, NULL);
INSERT INTO public.order_line VALUES (70025, 4, 1, 1000, 590, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70025, 5, 2, 500, 590, 500, '2021-01-15');
INSERT INTO public.order_line VALUES (70210, 4, 1, 1000, 470, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70250, 8, 2, 10000, 999.99, 10000, '2021-01-15');
INSERT INTO public.order_line VALUES (70250, 9, 1, 15000, 999.99, 12000, '2021-01-15');
INSERT INTO public.order_line VALUES (70300, 7, 1, 50, 790, 50, '2021-01-15');
INSERT INTO public.order_line VALUES (70620, 5, 1, 200, 600, 200, '2021-01-15');
INSERT INTO public.order_line VALUES (70625, 4, 1, 1000, 470, 1000, '2021-01-15');
INSERT INTO public.order_line VALUES (70625, 8, 2, 10000, 999.99, 10000, '2021-01-15');
INSERT INTO public.order_line VALUES (70629, 0, 1, 200, 140, NULL, NULL);
INSERT INTO public.order_line VALUES (70629, 1, 2, 200, 140, NULL, NULL);
INSERT INTO public.order_line VALUES (70010, 2, 4, 200, 40, 200, '2021-01-15');


--
-- TOC entry 3413 (class 0 OID 26002)
-- Dependencies: 223
-- Data for Name: sale_offer; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.sale_offer VALUES (0, 8700, 15, 150, NULL);
INSERT INTO public.sale_offer VALUES (1, 8700, 15, 210, NULL);
INSERT INTO public.sale_offer VALUES (2, 120, 0, 40, NULL);
INSERT INTO public.sale_offer VALUES (2, 9120, 5, 40, NULL);
INSERT INTO public.sale_offer VALUES (4, 120, 90, 700, NULL);
INSERT INTO public.sale_offer VALUES (4, 540, 70, 710, NULL);
INSERT INTO public.sale_offer VALUES (4, 9120, 60, 800, NULL);
INSERT INTO public.sale_offer VALUES (4, 9150, 90, 650, NULL);
INSERT INTO public.sale_offer VALUES (4, 9180, 30, 720, NULL);
INSERT INTO public.sale_offer VALUES (5, 120, 90, 705, NULL);
INSERT INTO public.sale_offer VALUES (5, 540, 70, 810, NULL);
INSERT INTO public.sale_offer VALUES (5, 8700, 30, 720, NULL);
INSERT INTO public.sale_offer VALUES (5, 9120, 60, 920, NULL);
INSERT INTO public.sale_offer VALUES (5, 9150, 90, 685, NULL);
INSERT INTO public.sale_offer VALUES (6, 120, 90, 795, NULL);
INSERT INTO public.sale_offer VALUES (6, 9120, 60, 920, NULL);
INSERT INTO public.sale_offer VALUES (7, 9120, 60, 950, NULL);
INSERT INTO public.sale_offer VALUES (7, 9180, 90, 900, NULL);
INSERT INTO public.sale_offer VALUES (13, 9120, 10, 120, NULL);
INSERT INTO public.sale_offer VALUES (14, 9120, 5, 275, NULL);


