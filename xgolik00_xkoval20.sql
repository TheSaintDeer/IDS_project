DROP TABLE CENIK;
DROP TABLE PUJCENI;
DROP TABLE ZANR;
DROP TABLE KLIENT;
DROP TABLE ZAMESTNANCE;
DROP TABLE KAZETA;


DROP SEQUENCE SEQ_KAZETA;
DROP SEQUENCE SEQ_KLIENT;
DROP SEQUENCE SEQ_PUJCENI;

DROP PROCEDURE the_best_seller;
DROP PROCEDURE new_batch;


CREATE TABLE klient(klient_id INT NOT NULL PRIMARY KEY,
					jmeno VARCHAR(50) NOT NULL,
					prijmeni VARCHAR(50) NOT NULL,
					email VARCHAR(50),
					datum_narozeni DATE
);

CREATE TABLE zamestnance(rodne_cislo INT NOT NULL PRIMARY KEY, 
                         jmeno VARCHAR(50) NOT NULL, 
                         prijmeni VARCHAR(50) NOT NULL, 
                         pozice VARCHAR(50) NOT NULL, 
                         email VARCHAR(50) NOT NULL, 
                         datum_narozeni DATE NOT NULL
);

CREATE TABLE kazeta(id_kazeta INT NOT NULL PRIMARY KEY, 
                    titul VARCHAR(80) NOT NULL,  
                    datum_premiery DATE, 
                    mnozstvi INT NOT NULL CHECK (mnozstvi >= 0),
                    cena INT NOT NULL
);

CREATE TABLE pujceni(id_pujceni INT NOT NULL PRIMARY KEY,
                     id_klienta INT NOT NULL REFERENCES klient, 
                     id_kazety INT NOT NULL REFERENCES kazeta, 
                     id_zamestnance INT NOT NULL REFERENCES zamestnance(rodne_cislo)
);

CREATE TABLE cenik(cenik_id INT NOT NULL,
				   datum_od DATE NOT NULL, 
                   datum_do DATE NOT NULL,
                   celkem FLOAT,
				   CONSTRAINT interval CHECK (datum_od < datum_do),
				   FOREIGN KEY (cenik_id) REFERENCES pujceni(id_pujceni)
);

CREATE TABLE zanr(zanr_id INT NOT NULL,
				  nazev_zanru VARCHAR(50) NOT NULL,
				  FOREIGN KEY (zanr_id) REFERENCES kazeta(id_kazeta)
);


--------------------------------------------------------
-- SEQUENCE and TRIGGER
--------------------------------------------------------

CREATE SEQUENCE seq_kazeta INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER kazeta_id
    BEFORE INSERT ON Kazeta
    FOR EACH ROW
    BEGIN
        :NEW.id_kazeta := seq_kazeta.nextval;
    END;
/
    
CREATE SEQUENCE seq_klient INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER id_klient
    BEFORE INSERT ON Klient
    FOR EACH ROW
    BEGIN
        :NEW.klient_id := seq_klient.nextval;
    END;
/

CREATE SEQUENCE seq_pujceni INCREMENT BY 1 START WITH 1;
CREATE OR REPLACE TRIGGER pujceni_id
    BEFORE INSERT ON pujceni
    FOR EACH ROW
    BEGIN
        :NEW.id_pujceni := seq_pujceni.nextval;
    END;
/

CREATE OR REPLACE TRIGGER kazeta_count_minus
    AFTER INSERT ON pujceni
    FOR EACH ROW
    BEGIN
        UPDATE kazeta SET mnozstvi = mnozstvi - 1 WHERE id_kazeta = :NEW.id_kazety;
    END;
/

--------------------------------------------------------
-- PROCEDURE
--------------------------------------------------------

create or replace PROCEDURE the_best_seller (input_datum_od DATE, input_datum_do DATE) IS
        CURSOR zamestnan IS SELECT * FROM zamestnance;
        RD_zamestnance zamestnance%ROWTYPE;
        celkem_kazet NUMBER;
        pocet_prodej NUMBER;
        vypocet NUMBER;
    BEGIN
        SELECT COUNT(*) INTO celkem_kazet FROM pujceni, cenik WHERE pujceni.id_pujceni = cenik.cenik_id AND cenik.datum_od >= input_datum_od AND cenik.datum_od <= input_datum_do;
        DBMS_OUTPUT.PUT_LINE('Procento prodej od ' || input_datum_od || ' do ' || input_datum_do || ':');
        OPEN zamestnan;
        LOOP
            FETCH zamestnan INTO RD_zamestnance;
            EXIT WHEN zamestnan%NOTFOUND;
            SELECT COUNT(*) INTO pocet_prodej FROM pujceni, cenik WHERE pujceni.id_zamestnance = RD_zamestnance.rodne_cislo AND pujceni.id_pujceni = cenik.cenik_id AND cenik.datum_od >= input_datum_od AND cenik.datum_od <= input_datum_do;
            vypocet := ROUND(pocet_prodej/celkem_kazet*100, 2);
            IF RD_zamestnance.pozice = 'Prodavac'
            THEN
                DBMS_OUTPUT.PUT_LINE('Prodavac ' || RD_zamestnance.jmeno || ' ' || RD_zamestnance.prijmeni || ' ' || RD_zamestnance.pozice ||': ' || TO_CHAR(vypocet) || ' %');
            END IF;
        END LOOP;
    EXCEPTION
        WHEN others THEN
         DBMS_OUTPUT.PUT_LINE('Error executing the the_best_seller procedure.');
    END;

/

CREATE OR REPLACE PROCEDURE new_batch (pocet INT, titul_kazety VARCHAR) AS
    
    BEGIN
        IF pocet < 1
        THEN 
            DBMS_OUTPUT.PUT_LINE('Error executing the new_batch procedure.');
        ELSE
            UPDATE kazeta SET mnozstvi = mnozstvi + pocet WHERE titul = titul_kazety; 
        END IF;
               
    END;
/

--------------------------------------------------------

INSERT INTO zamestnance VALUES (7708170420, 'Adam', 'Bitcoin', 'Manezer', 'bitcoin@gmail.com', TO_DATE('1979-11-27', 'yyyy-mm-dd'));
INSERT INTO zamestnance VALUES (7911210300, 'Borek', 'Ethereum', 'Prodavac', 'ethereum@gmail.com', TO_DATE('1979-11-21', 'yyyy-mm-dd'));
INSERT INTO zamestnance VALUES (6501051111, 'Barbora', 'Solana', 'Prodavac', 'solana@gmail.com', TO_DATE('1965-1-05', 'yyyy-mm-dd'));
INSERT INTO zamestnance VALUES (8010122020, 'Jakob', 'Litecoin', 'Cistic', 'litecoin@gmail.com', TO_DATE('1980-10-12', 'yyyy-mm-dd'));

INSERT INTO klient (jmeno, prijmeni, email, datum_narozeni) VALUES ('Janicka', 'Kovar', 'kovar@gmail.com', TO_DATE('2000-12-01', 'yyyy-mm-dd'));
INSERT INTO klient (jmeno, prijmeni, email, datum_narozeni) VALUES ('Kamila', 'Liska', 'liska@gmail.com', TO_DATE('1989-10-06', 'yyyy-mm-dd'));
INSERT INTO klient (jmeno, prijmeni, email, datum_narozeni) VALUES ('Karel', 'Sedlak', 'sedlak@gmail.com', TO_DATE( '1975-08-11', 'yyyy-mm-dd'));
INSERT INTO klient (jmeno, prijmeni, datum_narozeni) VALUES ('Lukas', 'Zajic', TO_DATE( '1999-06-16', 'yyyy-mm-dd'));
INSERT INTO klient (jmeno, prijmeni, datum_narozeni) VALUES ('Michal', 'Cermak', TO_DATE( '2002-04-21', 'yyyy-mm-dd'));
INSERT INTO klient (jmeno, prijmeni, email) VALUES ('Ales', 'Prochazka', 'prochazka@gmail.com');
INSERT INTO klient (jmeno, prijmeni) VALUES ('Adela', 'Ruzicka');
INSERT INTO klient (jmeno, prijmeni) VALUES ('Brigita', 'Oliva');
INSERT INTO klient (jmeno, prijmeni) VALUES ('Dan', 'Moravec');

INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('Avatar', TO_DATE( '2009-12-09', 'yyyy-mm-dd'), 20, 50);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('Kung Fu Panda', TO_DATE( '2008-05-15', 'yyyy-mm-dd'), 20, 40);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('I Am Legend', TO_DATE( '2007-12-05', 'yyyy-mm-dd'), 20, 20);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('Hitman', TO_DATE('2007-11-29', 'yyyy-mm-dd'), 20, 5);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('300', NULL, 20, 0);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('Charlie and the Chocolate Factory', TO_DATE('2005-07-25', 'yyyy-mm-dd'), 20, 30);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('Pirates of the Caribbean: The Curse of the Black Pearl', NULL, 20, 30);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('The Lord of the Rings: The Fellowship of the Ring', TO_DATE( '2001-02-07', 'yyyy-mm-dd'), 20, 20);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('The Lord of the Rings: The Two Towers', TO_DATE( '2002-12-05', 'yyyy-mm-dd'), 20, 25);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('The Lord of the Rings: The Return of the King', TO_DATE('2003-12-01', 'yyyy-mm-dd'), 20, 70);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('Spider-Man', NULL, 20, 30);
INSERT INTO kazeta(titul, datum_premiery, mnozstvi, cena) VALUES ('Harry Potter and the Sorcerers Stone', NULL, 20, 30);

INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (1, 1, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (1, 4, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (5, 7, 6501051111);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (7, 10, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (9, 2, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (2, 5, 6501051111);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (4, 8, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (6, 1, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (8, 3, 6501051111);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (6, 6, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (3, 1, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (6, 5, 6501051111);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (6, 8, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (2, 11, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (9, 3, 6501051111);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (8, 1, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (3, 4, 7911210300);
INSERT INTO pujceni(id_klienta, id_kazety, id_zamestnance) VALUES (7, 7, 6501051111);

INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (1, TO_DATE('2007-01-01', 'yyyy-mm-dd'), TO_DATE('2007-02-01', 'yyyy-mm-dd'), 120);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (2, TO_DATE('2007-01-01', 'yyyy-mm-dd'), TO_DATE('2007-02-01', 'yyyy-mm-dd'), 100);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (3, TO_DATE('2007-01-15', 'yyyy-mm-dd'), TO_DATE('2007-01-20', 'yyyy-mm-dd'), 200);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (4, TO_DATE('2007-03-08', 'yyyy-mm-dd'), TO_DATE('2007-03-30', 'yyyy-mm-dd'), 200);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (5, TO_DATE('2007-04-15', 'yyyy-mm-dd'), TO_DATE('2007-04-17', 'yyyy-mm-dd'), 100);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (6, TO_DATE('2007-06-01', 'yyyy-mm-dd'), TO_DATE('2007-06-10', 'yyyy-mm-dd'), 50);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (7, TO_DATE('2007-06-01', 'yyyy-mm-dd'), TO_DATE('2007-06-21', 'yyyy-mm-dd'), 100);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (8, TO_DATE('2007-07-07', 'yyyy-mm-dd'), TO_DATE('2007-07-17', 'yyyy-mm-dd'), 50);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (9, TO_DATE('2007-08-10', 'yyyy-mm-dd'), TO_DATE('2007-08-15', 'yyyy-mm-dd'), 150);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (10, TO_DATE('2007-10-10', 'yyyy-mm-dd'), TO_DATE('2007-10-20', 'yyyy-mm-dd'), 200);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (11, TO_DATE('2007-01-15', 'yyyy-mm-dd'), TO_DATE('2007-01-20', 'yyyy-mm-dd'), 200);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (12, TO_DATE('2007-03-08', 'yyyy-mm-dd'), TO_DATE('2007-03-30', 'yyyy-mm-dd'), 200);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (13, TO_DATE('2007-04-15', 'yyyy-mm-dd'), TO_DATE('2007-04-17', 'yyyy-mm-dd'), 100);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (14, TO_DATE('2007-06-01', 'yyyy-mm-dd'), TO_DATE('2007-06-10', 'yyyy-mm-dd'), 50);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (15, TO_DATE('2007-06-01', 'yyyy-mm-dd'), TO_DATE('2007-06-21', 'yyyy-mm-dd'), 100);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (16, TO_DATE('2007-07-07', 'yyyy-mm-dd'), TO_DATE('2007-07-17', 'yyyy-mm-dd'), 50);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (17, TO_DATE('2007-08-10', 'yyyy-mm-dd'), TO_DATE('2007-08-15', 'yyyy-mm-dd'), 150);
INSERT INTO cenik(cenik_id, datum_od, datum_do, celkem) VALUES (18, TO_DATE('2007-10-10', 'yyyy-mm-dd'), TO_DATE('2007-10-20', 'yyyy-mm-dd'), 200);

INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (1, 'Action');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (1, 'Adventures');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (1, 'Comedy');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (5, 'Drama');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (8, 'Thriller');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (7, 'Action');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (4, 'Action');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (9, 'Fantasy');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (10, 'Adventures');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (10, 'Action');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (10, 'Comedy');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (11, 'Comedy');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (11, 'Fantasy');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (12, 'Fantasy');
INSERT INTO zanr(zanr_id, nazev_zanru) VALUES (12, 'Comedy');

--SELECT * FROM KLIENT;
--SELECT * FROM ZAMESTNANCE;
--SELECT * FROM KAZETA;
--SELECT * FROM CENIK;
--SELECT * FROM PUJCENI;
--SELECT * FROM ZANR;

-- 2x spojeni dvou tabulek

--zanr kazdy kazety
SELECT kazeta.titul, zanr.nazev_zanru AS zanr
FROM kazeta, zanr
WHERE kazeta.id_kazeta = zanr.zanr_id;

--ktery zamestnanec obsluhoval klienta
SELECT zamestnance.jmeno, zamestnance.prijmeni, klient.jmeno, klient.prijmeni
FROM klient, zamestnance, pujceni
WHERE pujceni.id_klienta = klient.klient_id AND 
      pujceni.id_zamestnance = zamestnance.rodne_cislo;

-- 1x spojeni tri tabulek

--jakou kazetu si zakaznik vzal
SELECT pujceni.id_pujceni, klient.jmeno, klient.prijmeni, kazeta.titul AS titul_kazety
FROM klient, kazeta, pujceni
WHERE klient.klient_id = pujceni.id_klienta AND
      kazeta.id_kazeta = pujceni.id_kazety;

-- 2x dotazy s klauzuli GROUP BY

--kolikrat byla kazda kazeta vypujcena
SELECT kazeta.titul, COUNT(*) AS cislo_pronajmu
FROM kazeta, pujceni
WHERE kazeta.id_kazeta = pujceni.id_kazety
GROUP BY kazeta.titul
ORDER BY cislo_pronajmu DESC;

--kolik kazet si kazdy klient vzal
SELECT klient.jmeno, klient.prijmeni , COUNT(pujceni.id_kazety) AS cislo_kazet
FROM kazeta, pujceni, klient
WHERE klient.klient_id = pujceni.id_klienta AND 
      kazeta.id_kazeta = pujceni.id_kazety
GROUP BY klient.jmeno, klient.prijmeni
ORDER BY cislo_kazet DESC;

-- 1x dotaz obsahujici predikat EXISTS

--kazety, ktery nebyly vypujceni
SELECT *
FROM kazeta
WHERE NOT EXISTS (SELECT * FROM pujceni WHERE kazeta.id_kazeta = pujceni.id_kazety);

----------------------------------------------------------------------------------
-- Grand pro druheho clenu tymu
----------------------------------------------------------------------------------

GRANT ALL ON cenik TO xkoval20;
GRANT ALL ON kazeta TO xkoval20;
GRANT ALL ON klient TO xkoval20;
GRANT ALL ON pujceni TO xkoval20;
GRANT ALL ON zamestnance TO xkoval20;
GRANT ALL ON zanr TO xkoval20;

GRANT EXECUTE ON the_best_seller TO xkoval20;
GRANT EXECUTE ON new_batch TO xkoval20;

----------------------------------------------------------------------------------
-- View
----------------------------------------------------------------------------------

DROP VIEW kazety_comedy;

CREATE VIEW kazety_comedy AS
    SELECT K.titul
    FROM XGOLIK00.kazeta K, XGOLIK00.zanr Z
    WHERE K.id_kazeta = Z.zanr_id and Z.nazev_zanru = 'Comedy';

DROP MATERIALIZED VIEW mat_kazety_comedy;

CREATE MATERIALIZED VIEW mat_kazety_comedy
REFRESH ON COMMIT AS
    SELECT K.titul
    FROM XGOLIK00.kazeta K, XGOLIK00.zanr Z
    WHERE K.id_kazeta = Z.zanr_id and Z.nazev_zanru = 'Comedy';
    
    
SELECT * FROM kazety_comedy;
SELECT * FROM mat_kazety_comedy;

INSERT INTO XGOLIK00.zanr(zanr_id, nazev_zanru) VALUES (6, 'Comedy');
COMMIT;

SELECT * FROM kazety_comedy;
SELECT * FROM mat_kazety_comedy;

----------------------------------------------------------------------------------

DECLARE
  POCET NUMBER;
  TITUL_KAZETY VARCHAR2(200);
BEGIN
  POCET := 100;
  TITUL_KAZETY := '300';

  NEW_BATCH(
    POCET => POCET,
    TITUL_KAZETY => TITUL_KAZETY
  );
END;

/

SELECT * FROM KAZETA;

DECLARE
  INPUT_DATUM_OD DATE;
  INPUT_DATUM_DO DATE;
BEGIN
  INPUT_DATUM_OD := to_date('2007-01-01','yyyy-MM-dd');
  INPUT_DATUM_DO := to_date('2007-01-31','yyyy-MM-dd');

  THE_BEST_SELLER(
    INPUT_DATUM_OD => INPUT_DATUM_OD,
    INPUT_DATUM_DO => INPUT_DATUM_DO
  );
--rollback; 
END;

/

----------------------------------------------------------------------------------
-- Explain plan bez indexu
----------------------------------------------------------------------------------

EXPLAIN PLAN FOR
    SELECT klient.jmeno, klient.prijmeni , COUNT(pujceni.id_kazety) AS cislo_kazet
    FROM kazeta, pujceni, klient
    WHERE klient.klient_id = pujceni.id_klienta AND 
          kazeta.id_kazeta = pujceni.id_kazety
    GROUP BY klient.jmeno, klient.prijmeni
    ORDER BY cislo_kazet DESC;
SELECT * FROM table (DBMS_XPLAN.DISPLAY);


------------------------------------------------------------------------------------
---- Explain plan s indexem
------------------------------------------------------------------------------------

--DROP INDEX klient_index; 
--DROP INDEX pujceni_index;

CREATE INDEX klient_index ON klient (jmeno, prijmeni, klient_id);
CREATE INDEX pujceni_index ON pujceni (id_klienta, id_kazety);

EXPLAIN PLAN FOR
    SELECT klient.jmeno, klient.prijmeni , COUNT(pujceni.id_kazety) AS cislo_kazet
    FROM kazeta, pujceni, klient
    WHERE klient.klient_id = pujceni.id_klienta AND 
          kazeta.id_kazeta = pujceni.id_kazety
    GROUP BY klient.jmeno, klient.prijmeni
    ORDER BY cislo_kazet DESC;
SELECT * FROM table (DBMS_XPLAN.DISPLAY);





