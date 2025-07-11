CREATE TABLE supplier (
    id              SERIAL PRIMARY KEY,
    "name"          VARCHAR(50) NOT NULL,
    address         VARCHAR(50) NOT NULL,
    postal_code     VARCHAR(5) NOT NULL,
    city            VARCHAR(25) NOT NULL,
    contact_name    VARCHAR(30) NOT NULL,
    satisfaction_index INT
);

CREATE TABLE item (
    id              SERIAL PRIMARY KEY,
    item_code       CHAR(4) NOT NULL,
    "name"          VARCHAR(50) NOT NULL,
    stock_alert     INT NOT NULL,
    stock           INT NOT NULL,
    yearly_consumption INT NOT NULL,
    unit            VARCHAR(15) NOT NULL
);

CREATE TABLE sale_offer (
    item_id         INT NOT NULL,
    supplier_id     INT NOT NULL,
    delivery_time   INT NOT NULL,
    price           INT NOT NULL,
    "date"          DATE,
    FOREIGN KEY (item_id) REFERENCES item(id),
    FOREIGN KEY (supplier_id) REFERENCES supplier(id)
);

CREATE TABLE "order" (
    id              SERIAL PRIMARY KEY,
    supplier_id     INT NOT NULL,
    "date"          DATE NOT NULL,
    comments        VARCHAR(800),
    FOREIGN KEY (supplier_id) REFERENCES supplier(id)
);

CREATE TABLE order_line (
    order_id        INT NOT NULL,
    item_id         INT NOT NULL,
    line_number     INT NOT NULL,
    ordered_qunatity INT NOT NULL,
    unit_price      FLOAT NOT NULL,
    delivered_quantity INT,
    last_delivery_date DATE ,
    FOREIGN KEY (order_id) REFERENCES "order"(id),
    FOREIGN KEY (item_id) REFERENCES item(id)
);

ALTER TABLE public.order_line ADD CONSTRAINT order_line_pk PRIMARY KEY (order_id,item_id);
ALTER TABLE public.sale_offer ADD CONSTRAINT sale_offer_pk PRIMARY KEY (item_id,supplier_id);
