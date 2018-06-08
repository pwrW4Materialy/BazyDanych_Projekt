/*
Usercase: user-client chce wyszukac apartament wedug parametrów:
    kraj (obowiazkowe),
    cena za noc,
    ilosc lozek (obowiazkowe),
    klimatyzacja,
    standard
*/
CREATE PUBLIC SYNONYM get_apartments
   FOR markot.get_apartments;
   
CREATE OR REPLACE FUNCTION get_apartments (
    v_country_name      IN VARCHAR2,
    v_bed_count         IN INT,
    v_cost_per_night   IN INT DEFAULT 1000000,
    v_air_cond        IN INT DEFAULT 0,
    v_standard        IN INT DEFAULT 1
) RETURN SYS_REFCURSOR AS
    my_cursor   SYS_REFCURSOR;
BEGIN
    OPEN my_cursor FOR SELECT
            apartment_id
        FROM apartments
        JOIN locations USING ( location_id )
        WHERE
            country_name = v_country_name
            AND   bed_count = v_bed_count
            AND   cost_per_night <= v_cost_per_night
            AND   air_cond >= v_air_cond
            AND   standard >= v_standard
	ORDER BY cost_per_night;

    RETURN my_cursor;
END;

DECLARE
  res int;
  x SYS_REFCURSOR;
BEGIN
    x := GET_APARTMENTS('Indonesia', 7, 100000);
    LOOP
      FETCH x INTO res;
      EXIT WHEN x%NOTFOUND;
      dbms_output.put_line(res);
    END LOOP;
end;

--przykladowe:
SELECT
    apartment_id
FROM
    apartments
    JOIN locations USING ( location_id )
WHERE
    country_name = 'Indonesia'
    AND   bed_count = 7
    AND   cost_per_night <= 50000
    AND   air_cond >= 0
    AND   standard >= 3;


/*
Usercase: user-client chce zarezerwowac apartament:
    apartment_id (obowiazkowe),
    data_poczatek (obowiazkowe),
    data_koniec (obowiazkowe)
*/
CREATE PUBLIC SYNONYM reserve_apartment
   FOR markot.reserve_apartment;
   
CREATE OR REPLACE FUNCTION reserve_apartment (
    v_apartment_id   IN INT,
    v_date_begin     IN DATE,
    v_date_end       IN DATE,
    v_user_id        IN INT
) RETURN INT AS
    id   INT := v_apartment_id;
BEGIN
    INSERT INTO reservations VALUES (
        (
            SELECT
                MAX(r.reservation_id)
            FROM
                reservations r
        ) + 1,
        v_date_begin,
        v_date_end,
        v_apartment_id,
        v_user_id,
        1
    );

    RETURN id;
END;

--przykladowe:
INSERT INTO reservations VALUES (
    (
        SELECT
            MAX(r.reservation_id)
        FROM
            reservations r
    ) + 1,
    '2018-08-10',
    '2018-08-17',
    50,
    400,
    1
);


/*
Usercase: user-owner chce wyswietlic rezerwacje jego apartamentu:
    apartment_id (obowiazkowe)
*/
CREATE PUBLIC SYNONYM get_reservations
   FOR markot.get_reservations;
   
CREATE OR REPLACE FUNCTION get_reservations (
    v_apartment_id IN INT
) RETURN SYS_REFCURSOR AS
    my_cursor   SYS_REFCURSOR;
BEGIN
    OPEN my_cursor FOR SELECT
            reservation_id, status
        FROM reservations
        WHERE
            apartment_id = v_apartment_id;

    RETURN my_cursor;
END;

--przykladowe:
select reservation_id, status
from reservations
where apartment_id = 50;

/*
Usercase: user-owner chce zmieniæ status wybranej rezerwacji:
	reservation_id (wymagane),
	nowy status (wymagane)
 */
CREATE FUNCTION RESERVATION_UPDATE (reservation IN int, status IN int)
RETURN int
IS id int := reservation;
BEGIN
  UPDATE RESERVATIONS
  SET STATUS = status
  WHERE RESERVATION_ID = reservation;
RETURN id;
end;

--przyk³adowe:
UPDATE RESERVATIONS
SET STATUS = 1
WHERE RESERVATION_ID = 1;

/*
Usercase: system otrzyma³ potwierdzenie p³atno¶ci:
	payment_id (wymagane)
	nowy status (wymagane)
 */
CREATE FUNCTION PAYMENT_COMPLETED (payment IN int, status IN varchar2)
RETURN int
IS id int := payment;
BEGIN
  UPDATE PAYMENTS
  SET STATUS = status
  WHERE PAYMENT_ID = payment;
RETURN id;
end;

--przyk³adowe:
UPDATE PAYMENTS
SET STATUS = 'started'
WHERE PAYMENT_ID = 5;

/*
Usercase: user-client chce anulowaæ rezerwacjê
	reservation_id (wymagane)
 */
CREATE FUNCTION RESERVATION_CANCEL (reservation IN int)
RETURN int
IS refund_amount int := 0;
  payment_type varchar2(16);
BEGIN
  UPDATE RESERVATIONS
  SET STATUS = 3
  WHERE RESERVATION_ID = 1;
  COMMIT;

  SELECT 'TYPE' into payment_type
  FROM PAYMENTS
  WHERE RESERVATION_ID = reservation;

  IF payment_type = 'advance' THEN
    RETURN refund_amount;
  ELSE
    SELECT VALUE*0.8 into refund_amount
    FROM PAYMENTS
    WHERE RESERVATION_ID = reservation;
    UPDATE PAYMENTS
    SET STATUS = 'refunded'
    WHERE RESERVATION_ID = reservation;
    COMMIT;
  end if;

RETURN refund_amount;
end;

--przyk³adowe
UPDATE RESERVATIONS
SET STATUS = 3
WHERE RESERVATION_ID = 1;

SELECT 'TYPE'
FROM PAYMENTS
WHERE RESERVATION_ID = 1;

SELECT VALUE*0.8
FROM PAYMENTS
WHERE RESERVATION_ID = 1;

UPDATE PAYMENTS
SET STATUS = 'refunded'
WHERE RESERVATION_ID = 1;

/*
Usercase: user-client chce wy¶wietliæ swoje rezerwacje
	user_id clienta (wymagane)
 */
CREATE FUNCTION GET_USER_RESERVATIONS (client_id IN int)
RETURN SYS_REFCURSOR
IS my_cursor SYS_REFCURSOR;
BEGIN
    OPEN my_cursor FOR SELECT RESERVATION_ID, STATUS
    FROM RESERVATIONS
    WHERE USER_ID = client_id;
RETURN my_cursor;
END;

--przyk³adowe
SELECT *
FROM RESERVATIONS
WHERE USER_ID = 499;

--2
/*
Usercase: user-client chce sprawdziæ dostêpnoœæ apartamentu:
    apartament_id (obowi¹zkowe)
*/
CREATE OR REPLACE FUNCTION apartment_busy (
    v_apartment_id IN INT
) RETURN SYS_REFCURSOR AS
    my_cursor   SYS_REFCURSOR;
BEGIN
    OPEN my_cursor FOR SELECT
        	date_begin,
        	date_end
        FROM reservations
        WHERE
        	apartment_id = v_apartment_id
	AND STATUS != 3;

    RETURN my_cursor;
END;

--przyk³ad

SELECT
    date_begin,
    date_end
FROM
    reservations
WHERE
    apartment_id = 1
AND status != 3;
    
--9
/*
Usercase: user-owner chce dodaæ apartament:
        cost_per_night (obowi¹zkowe)
        bed_count (obowi¹zkowe)
        location_id (obowi¹zkowe)
        agency_id (obowi¹zkowe)
        air_cond (obowi¹zkowe)
        standard (obowi¹zkowe)
        owner_id (obowi¹zkowe)
*/

CREATE OR REPLACE FUNCTION insert_apartment (
    v_cost_per_night   IN INT,
    v_bed_count        IN INT,
    v_location_id      IN INT,
    v_agency_id        IN INT,
    v_air_cond         IN INT,
    v_standard         IN INT,
    v_owner_id         IN INT
) RETURN INT IS
    ret   INT := 0;
BEGIN
    INSERT INTO apartments (
        apartment_id,
        cost_per_night,
        bed_count,
        location_id,
        agency_id,
        air_cond,
        standard,
        owner_id
    ) VALUES (
        (
            SELECT
                MAX(a.apartment_id)
            FROM
                apartments a
        ) + 1,
        v_cost_per_night,
        v_bed_count,
        v_location_id,
        v_agency_id,
        v_air_cond,
        v_standard,
        v_owner_id
    );

    RETURN ret;
END;

--przyk³ad

INSERT INTO apartments (
    apartment_id,
    cost_per_night,
    bed_count,
    location_id,
    agency_id,
    air_cond,
    standard,
    owner_id
) VALUES (
    (
        SELECT
            MAX(a.apartment_id)
        FROM
            apartments a
    ) + 1,
    50000,
    2,
    66,
    11,
    1,
    2,
    400
);

DECLARE
    x   INT;
BEGIN
    x := insert_apartment(200000,3,250,25,1,2,451);
END;
