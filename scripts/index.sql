use mywebsite;

ALTER TABLE product
    ADD ean16 VARCHAR(16) NOT NULL
;

UPDATE product SET
    ean16 = (select UPPER(LEFT(TO_BASE64( SHA(rand())), 16)))
;

CREATE INDEX product_ean ON product (ean16);

DROP INDEX product_ean ON product;

CREATE INDEX product_ean ON product (ean16, id_product);

CREATE FULLTEXT INDEX product_name_description ON product (name, description);

SELECT
    *
FROM
    product
WHERE
    MATCH (name, description) AGAINST ('dicta' IN NATURAL LANGUAGE MODE)
;
