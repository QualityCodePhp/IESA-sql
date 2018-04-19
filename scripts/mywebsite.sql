DROP DATABASE mywebsite;

CREATE DATABASE mywebsite;

USE mywebsite;

CREATE TABLE customer (
    id_customer INT UNSIGNED AUTO_INCREMENT,
    firstname VARCHAR(150),
    lastname VARCHAR(150),
    birthday DATE,
    phone VARCHAR(15),
    email VARCHAR(500) NOT NULL,
    PRIMARY KEY (id_customer)
);

CREATE TABLE address (
    id_address INT UNSIGNED AUTO_INCREMENT,
    line1 VARCHAR(150),
    line2 VARCHAR(150),
    line3 VARCHAR(150),
    country VARCHAR(100),
    zicode VARCHAR(10),
    id_customer INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_address),
    FOREIGN KEY (id_customer) REFERENCES customer(id_customer)
);

CREATE TABLE product (
    id_product INT UNSIGNED AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    picture BLOB,
    PRIMARY KEY (id_product)
);

CREATE TABLE price (
    id_price INT UNSIGNED AUTO_INCREMENT,
    value FLOAT,
    begin_date DATE NOT NULL,
    end_date DATE NOT NULL,
    id_product INT UNSIGNED NOT NULL,
    PRIMARY KEY (id_price),
    FOREIGN KEY (id_product) REFERENCES product(id_product)
);

CREATE TABLE customer_order (
    id_customer_order INT UNSIGNED AUTO_INCREMENT,
    id_customer INT UNSIGNED NOT NULL,
    order_date DATETIME NOT NULL,
    state VARCHAR(10),
    PRIMARY KEY (id_customer_order),
    FOREIGN KEY (id_customer) REFERENCES customer(id_customer)
);

CREATE TABLE order_products (
    quantity SMALLINT NOT NULL DEFAULT 1,
    id_customer_order INT UNSIGNED NOT NULL,
    id_price INT UNSIGNED NOT NULL,
    id_product INT UNSIGNED NOT NULL,
    FOREIGN KEY (id_customer_order) REFERENCES customer_order(id_customer_order),
    FOREIGN KEY (id_price) REFERENCES price(id_price),
    FOREIGN KEY (id_product) REFERENCES product(id_product)
);

CREATE TABLE feature (
    id_feature INT UNSIGNED AUTO_INCREMENT,
    name VARCHAR(50),
    PRIMARY KEY (id_feature)
);

CREATE TABLE product_features (
    id_product INT UNSIGNED NOT NULL,
    id_feature INT UNSIGNED NOT NULL,
    FOREIGN KEY (id_product) REFERENCES product(id_product),
    FOREIGN KEY (id_feature) REFERENCES feature(id_feature)
);

ALTER TABLE customer
    ADD created_at DATETIME NOT NULL DEFAULT now(),
    ADD updated_at DATETIME,
    ADD deleted_at DATETIME
;

ALTER TABLE customer
    MODIFY updated_at DATETIME ON UPDATE now()
;

ALTER TABLE customer
    ADD number_orders SMALLINT UNSIGNED NOT NULL DEFAULT 0
;

/*
DELIMITER //
CREATE TRIGGER total_order AFTER INSERT ON customer_order
FOR EACH ROW
BEGIN
    UPDATE customer SET number_orders = number_orders + 1 WHERE id_customer = NEW.id_customer;
END;//
DELIMITER ;
*/

DELIMITER //
CREATE TRIGGER total_order AFTER INSERT ON customer_order
FOR EACH ROW
BEGIN
    UPDATE customer SET number_orders = (SELECT count(id_customer_order) FROM customer_order WHERE id_customer = NEW.id_customer) WHERE id_customer = NEW.id_customer;
END;//
DELIMITER ;

CREATE TABLE lead (
    id_lead INT UNSIGNED AUTO_INCREMENT,
    firstname VARCHAR(150),
    lastname VARCHAR(150),
    birthday DATE,
    phone VARCHAR(15),
    email VARCHAR(500) NOT NULL,
    state ENUM('1', '2', '3'),
    PRIMARY KEY (id_lead)
);

ALTER TABLE customer
    ADD id_lead INT UNSIGNED,
    ADD FOREIGN KEY (id_lead) REFERENCES lead(id_lead)
;

DELIMITER //
CREATE TRIGGER lead_to_customer BEFORE UPDATE on lead
FOR EACH ROW
BEGIN
    IF NEW.state = 3 THEN
        INSERT INTO `customer`
            (`firstname`, `lastname`, `birthday`, `phone`, `email`, `id_lead`)
        VALUES
            (NEW.firstname, NEW.lastname, NEW.birthday, NEW.phone, NEW.email, NEW.id_lead);
    END IF;
END;//
DELIMITER ;

CREATE TABLE log (
    id_log INT UNSIGNED AUTO_INCREMENT,
    log_at DATETIME NOT NULL DEFAULT now(),
    action_name ENUM('insert', 'update', 'delete'),
    table_name VARCHAR(255),
    data JSON,
    PRIMARY KEY (id_log)
);

DELIMITER //
CREATE PROCEDURE log_data(data JSON, event VARCHAR(9), table_name VARCHAR(255))
BEGIN
    CASE event
        WHEN 'insert' THEN INSERT INTO log (`log_at`, `table_name`, `action_name`, `data`) VALUES (now(), table_name, 'insert', data);
        WHEN 'update' THEN INSERT INTO log (`log_at`, `table_name`, `action_name`, `data`) VALUES (now(), table_name, 'update', data);
        WHEN 'delete' THEN INSERT INTO log (`log_at`, `table_name`, `action_name`, `data`) VALUES (now(), table_name, 'delete', data);
    END CASE;
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER log_customer_on_update AFTER UPDATE on customer
FOR EACH ROW
BEGIN
    CALL log_data(
        JSON_OBJECT(
            'id_customer', OLD.id_customer,
            'firstname', OLD.firstname,
            'lastname', OLD.lastname,
            'birthday', OLD.birthday,
            'phone', OLD.phone,
            'email', OLD.email,
            'created_at', OLD.created_at,
            'id_lead', OLD.id_lead
        ), 'update', 'customer');
END;//
DELIMITER ;

DELIMITER //
CREATE TRIGGER log_customer_on_delete AFTER DELETE on customer
FOR EACH ROW
BEGIN
CALL log_data(
    JSON_OBJECT(
        'id_customer', OLD.id_customer,
        'firstname', OLD.firstname,
        'lastname', OLD.lastname,
        'birthday', OLD.birthday,
        'phone', OLD.phone,
        'email', OLD.email,
        'created_at', OLD.created_at,
        'id_lead', OLD.id_lead
    ), 'delete', 'customer');
END;//
DELIMITER ;
