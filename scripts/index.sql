use mywebsite;

ALTER TABLE product
    ADD ean16 VARCHAR(16) NOT NULL;

UPDATE product SET ean16 = (select UPPER(LEFT(TO_BASE64( SHA(rand())), 16)));

CREATE INDEX product_ean ON product (ean16);
