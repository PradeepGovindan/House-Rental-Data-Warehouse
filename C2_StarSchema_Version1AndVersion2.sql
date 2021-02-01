/*Version 1*/

----------------------------------------------------------------------------------
/*Queries to create Level 2 Star Schema*/ 

-----CLIENT DIMENSION AND FACT CREATION-----
/*DROP TABLEs*/
DROP TABLE client_dim_lvl2;

DROP TABLE client_year_dim_lvl2;

DROP TABLE budget_type_dim_lvl2;

DROP TABLE client_wishlist_dim_lvl2;

DROP TABLE feature_dim_lvl2;

DROP TABLE client_fact_lvl2;

DROP TABLE client_tempfact_lvl2;


/*Client Dimension*/

CREATE TABLE client_dim_lvl2
    AS
        SELECT DISTINCT
            person_id
        FROM
            client;

/*Client Year Dimension TAbe*/

CREATE TABLE client_year_dim_lvl2
    AS
        SELECT DISTINCT
            year
        FROM
            (
                SELECT
                    to_char(rent_start_date, 'yyyy') AS year
                FROM
                    rent
                UNION
                SELECT
                    to_char(sale_date, 'yyyy') AS year
                FROM
                    sale
                UNION
                SELECT
                    to_char(visit_date, 'yyyy') AS year
                FROM
                    visit
            )
        WHERE
            NOT year IS NULL;

/*Client Budget Dimension*/

CREATE TABLE budget_type_dim_lvl2 (
    budget_id            VARCHAR(10),
    budget_description   VARCHAR(20)
);

INSERT INTO budget_type_dim_lvl2 VALUES (
    'Low',
    '0-1000'
);

INSERT INTO budget_type_dim_lvl2 VALUES (
    'Medium',
    '1001-100000'
);

INSERT INTO budget_type_dim_lvl2 VALUES (
    'High',
    '100001-10000000'
);

/*Client Wishlist Dimension*/

CREATE TABLE client_wishlist_dim_lvl2
    AS
        SELECT
            *
        FROM
            client_wish;

/*Feature Dimension*/

CREATE TABLE feature_dim_lvl2
    AS
        SELECT
            feature_code,
            feature_description
        FROM
            feature;

/*Client Tempfact*/

CREATE TABLE client_tempfact_lvl2
    AS
        SELECT
            person_id,
            max_budget,
            MIN(year) AS year
        FROM
            (
                SELECT
                    person_id,
                    max_budget,
                    to_char(rent_start_date, 'yyyy') AS year
                FROM
                    client   c
                    JOIN rent     r ON c.person_id = r.client_person_id
                UNION
                SELECT
                    person_id,
                    max_budget,
                    to_char(sale_date, 'yyyy') AS year
                FROM
                    client   c
                    JOIN sale     s ON c.person_id = s.client_person_id
                UNION
                SELECT
                    person_id,
                    max_budget,
                    to_char(visit_date, 'yyyy') AS year
                FROM
                    client   c
                    JOIN visit    v ON c.person_id = v.client_person_id
            )
        GROUP BY
            person_id,
            max_budget;

ALTER TABLE client_tempfact_lvl2 ADD budget_id VARCHAR(10);

UPDATE client_tempfact_lvl2
SET
    budget_id = 'Low'
WHERE
    max_budget BETWEEN 0 AND 1000;

UPDATE client_tempfact_lvl2
SET
    budget_id = 'Medium'
WHERE
    max_budget BETWEEN 1001 AND 100000;

UPDATE client_tempfact_lvl2
SET
    budget_id = 'High'
WHERE
    max_budget BETWEEN 100001 AND 10000000;

/*Client Fact*/

CREATE TABLE client_fact_lvl2
    AS
        SELECT
            person_id,
            budget_id,
            year,
            COUNT(person_id) "Number of Clients"
        FROM
            client_tempfact_lvl2
        GROUP BY
            budget_id,
            person_id,
            year;

/*SELECT Quiries*/

SELECT
    *
FROM
    client_dim_lvl2;

SELECT
    *
FROM
    budget_type_dim_lvl2;

SELECT
    *
FROM
    client_wishlist_dim_lvl2;

SELECT
    *
FROM
    client_year_dim_lvl2;

SELECT
    *
FROM
    feature_dim_lvl2;

SELECT
    *
FROM
    client_tempfact_lvl2;

SELECT
    *
FROM
    client_fact_lvl2;

-------------------------------------------------------------------------------------------

-----Advertisement-----

/*DROP TABLE*/

DROP TABLE advert_dim_lvl2;

DROP TABLE advert_date_dim_lvl2;

DROP TABLE advertisement_tempfact_lvl2;

DROP TABLE advertisement_fact_lvl2;

/*Advertisement Dimension*/

CREATE TABLE advert_dim_lvl2
    AS
        SELECT
            advert_id,
            advert_name
        FROM
            advertisement;

/*Advertisement Date Dimension*/

CREATE TABLE advert_date_dim_lvl2
    AS
        SELECT DISTINCT
            to_char(property_date_added, 'Month')
            || ' '
            || to_char(property_date_added, 'yyyy') date_id,
            to_char(property_date_added, 'Month') month,
            to_char(property_date_added, 'yyyy') year
        FROM
            property;

/*Advertisement Tempfact*/

CREATE TABLE advertisement_tempfact_lvl2
    AS
        SELECT
            p.property_id,
            pd.property_date_added,
            a.advert_id
        FROM
            advertisement

A
join

property_advert p ON a.advert_id = p.advert_id
        JOIN property pd 
            ON p.property_id=pd.property_id 
        GROUP BY
            p.property_id,pd.property_date_added,a.advert_id;

/*Advertisement Fact*/
CREATE TABLE advertisement_fact_lvl2
    AS
        SELECT
            to_char(property_date_added, 'Month')
            || ' '
            || to_char(property_date_added, 'yyyy') date_id,
            advert_id,
            COUNT(property_id) "Total number of Properties"
        FROM
            advertisement_tempfact_lvl2
        GROUP BY
            to_char(property_date_added, 'Month')
            || ' '
            || to_char(property_date_added, 'yyyy'),
            advert_id;
            
/*SELECT Queries*/
SELECT * FROM advert_dim_lvl2;
SELECT * FROM advert_date_dim_lvl2;
SELECT * FROM advertisement_tempfact_lvl2;
SELECT * FROM advertisement_fact_lvl2;

-----------------------------------------------------------------------------------------------------------
-----RENT-----
/*DROP TABLEs*/
DROP TABLE property_feature_category_dim_lvl2;
DROP TABLE property_scale_dim_lvl2;
DROP TABLE property_type_dim_lvl2;
DROP TABLE rent_time_period_dim_lvl2;
DROP TABLE rent_year_dim_lvl2;
DROP TABLE property_dim_lvl2;
DROP TABLE property_rent_scd_lvl2;
DROP TABLE location_dim_lvl2;
DROP TABLE rent_tempfact_lvl2;
DROP TABLE rent_fact_lvl2;

/* Property Feature Category Dimension*/
CREATE TABLE property_feature_category_dim_lvl2 (
    category        VARCHAR(20),
    feature_count   VARCHAR(20)
);

INSERT INTO property_feature_category_dim_lvl2 VALUES (
    'Very basic',
    '<10'
);

INSERT INTO property_feature_category_dim_lvl2 VALUES (
    'Standard',
    '10-20'
);

INSERT INTO property_feature_category_dim_lvl2 VALUES (
    'Luxurious',
    '>20'
);

/*Property Scale Dimension*/

CREATE TABLE property_scale_dim_lvl2 (
    scale_type       VARCHAR(20),
    no_of_bedrooms   VARCHAR(20)
);

INSERT INTO property_scale_dim_lvl2 VALUES (
    'Extra small',
    '<=1'
);

INSERT INTO property_scale_dim_lvl2 VALUES (
    'Small',
    '2-3'
);

INSERT INTO property_scale_dim_lvl2 VALUES (
    'Medium',
    '3-6'
);

INSERT INTO property_scale_dim_lvl2 VALUES (
    'Large',
    '6-10'
);

INSERT INTO property_scale_dim_lvl2 VALUES (
    'Extra large',
    '>10'
);
/*Property Type Dimension*/
CREATE TABLE property_type_dim_lvl2
    AS
        SELECT DISTINCT
            property_type
        FROM
            property;

/*Rent Time Period Dimension*/

CREATE TABLE rent_time_period_dim_lvl2 (
    period            VARCHAR(20),
    duration_months   VARCHAR(20)
);

INSERT INTO rent_time_period_dim_lvl2 VALUES (
    'Short',
    '<6'
);

INSERT INTO rent_time_period_dim_lvl2 VALUES (
    'Medium',
    '6-12'
);

INSERT INTO rent_time_period_dim_lvl2 VALUES (
    'Long',
    '>12'
);

/*Rent Year Dimension*/

CREATE TABLE rent_year_dim_lvl2
    AS
        SELECT DISTINCT
            to_char(rent_start_date, 'yyyy') AS year
        FROM
            rent
        WHERE
            NOT rent_start_date IS NULL;

/*Property Dimension*/

CREATE TABLE property_dim_lvl2
    AS
        SELECT DISTINCT
            p.property_id
        FROM
            property

p;
    
/*Property Rent SCD Dimension*/

CREATE TABLE property_rent_scd_lvl2
    AS
        SELECT
            rent_start_date,
            rent_end_date,
            property_id,
            price
        FROM
            rent
        WHERE
            NOT rent_start_date IS NULL;

/*Location Dimension*/

CREATE TABLE location_dim_lvl2
    AS
        SELECT
            a.suburb,
            p.state_code
        FROM
            address

A
join

postcode p ON a.postcode = p.postcode;

/*Rent Temfact TABLE*/
CREATE TABLE rent_tempfact_lvl2 AS 
    SELECT rent_id, r.property_id, COUNT(feature_code) AS "Feature count", property_type, floor(months_between(TO_DATE(rent_end_date,'dd-mm-yyyy'),TO_DATE(rent_start_date,'dd-mm-yyyy'))) AS Months,
    to_char(rent_start_date,'yyyy') AS years, ad.suburb, pc.state_code, price*((TO_DATE(rent_end_date,'dd-mm-yyyy')-TO_DATE(rent_start_date,'dd-mm-yyyy'))/7) AS price, p.property_no_of_bedrooms    FROM rent r 
    JOIN property p ON r.property_id=p.property_id 
    JOIN property_feature pf ON p.property_id=pf.property_id 
    JOIN address ad ON ad.address_id=p.address_id 
    JOIN postcode pc ON ad.postcode=pc.postcode
    WHERE NOT r.rent_start_date IS NULL
    GROUP BY (rent_id, r.property_id, property_type, months_between(TO_DATE(rent_end_date,'dd-mm-yyyy'),TO_DATE(rent_start_date,'dd-mm-yyyy')),
        TO_CHAR(rent_start_date,'yyyy'), price*((TO_DATE(rent_end_date,'dd-mm-yyyy')-TO_DATE(rent_start_date,'dd-mm-yyyy'))/7), p.property_no_of_bedrooms,ad.suburb, pc.state_code);
        
ALTER TABLE rent_tempfact_lvl2 ADD category VARCHAR(20); 

UPDATE rent_tempfact_lvl2 SET category='Very basic' WHERE "Feature count"<10;
UPDATE rent_tempfact_lvl2 SET category='Standard' WHERE "Feature count" BETWEEN 10 AND 20;
UPDATE rent_tempfact_lvl2 SET category='Luxurious' WHERE "Feature count">20;

ALTER TABLE rent_tempfact_lvl2 ADD scale_type VARCHAR(20);

UPDATE rent_tempfact_lvl2 SET scale_type='Extra small' WHERE property_no_of_bedrooms<=1;
UPDATE rent_tempfact_lvl2 SET scale_type='Small' WHERE property_no_of_bedrooms BETWEEN 2 AND 3;
UPDATE rent_tempfact_lvl2 SET scale_type='Medium' WHERE property_no_of_bedrooms BETWEEN 4 AND 6;
UPDATE rent_tempfact_lvl2 SET scale_type='Large' WHERE property_no_of_bedrooms BETWEEN 7 AND 10;
UPDATE rent_tempfact_lvl2 SET scale_type='Extra large' WHERE property_no_of_bedrooms>10;

ALTER TABLE rent_tempfact_lvl2 ADD period VARCHAR(20);

UPDATE rent_tempfact_lvl2 SET period='Short' WHERE Months<6;
UPDATE rent_tempfact_lvl2 SET period='Medium' WHERE Months BETWEEN 6 AND 12;
UPDATE rent_tempfact_lvl2 SET period='Long' WHERE Months>12;

/*Rent Fact TABLE*/
CREATE TABLE rent_fact_lvl2
    AS
        SELECT
            property_id,
            property_type,
            years,
            category,
            scale_type,
            period,
            suburb,
            state_code,
            COUNT(rent_id) AS "Total Number of Rent",
            SUM(price) AS "Total Rental Fees"
        FROM
            rent_tempfact_lvl2
        GROUP BY (
            property_id,
            property_type,
            years,
            category,
            scale_type,
            period,
            suburb,
            state_code
        );
/*SELECT Queries*/
SELECT * FROM property_feature_category_dim_lvl2;
SELECT * FROM property_scale_dim_lvl2;
SELECT * FROM property_type_dim_lvl2;
SELECT * FROM rent_time_period_dim_lvl2;
SELECT * FROM rent_year_dim_lvl2;
SELECT * FROM property_dim_lvl2;
SELECT * FROM property_rent_scd_lvl2;
SELECT * FROM location_dim_lvl2;
SELECT * FROM rent_tempfact_lvl2;
SELECT * FROM rent_fact_lvl2;

--------------------------------------------------------------------------------------------
-----Agent-----
/*DROP TABLEs*/
DROP TABLE agent_info_Dim_lvl2;
DROP TABLE agent_office_bridge_dim_lvl2;
DROP TABLE office_dim_lvl2;
DROP TABLE office_size_dim_lvl2;
DROP TABLE gender_dim_lvl2;
DROP TABLE agent_tempfact_lvl2;
DROP TABLE agent_fact_lvl2;

/*Agent Information Dimension*/
CREATE TABLE agent_info_dim_lvl2
    AS
        SELECT DISTINCT
            ( a.person_id ),
            p.title
            || ' '
            || p.first_name
            || ' '
            || p.last_name AS "Agent Name"
        FROM
            agent

A
join

person p ON a.person_id = p.person_id;
    
/*Agent Office Bridge Dimension*/
CREATE TABLE agent_office_bridge_dim_lvl2
    AS
        SELECT
            person_id,
            office_id
        FROM
            agent_office;

/*Office Dimension*/
CREATE TABLE office_dim_lvl2
    AS
        SELECT
            office_id,
            office_name
        FROM
            office;

/*Office Size Dimension*/
CREATE TABLE office_size_dim_lvl2 (
    office_type       VARCHAR2(30),
    no_of_employees   VARCHAR2(40)
);

INSERT INTO office_size_dim_lvl2 VALUES (
    'Small',
    '< 4'
);

INSERT INTO office_size_dim_lvl2 VALUES (
    'Medium',
    ' 4-12'
);

INSERT INTO office_size_dim_lvl2 VALUES (
    'Large',
    '> 12'
);
/*Gender Dimension*/
CREATE TABLE gender_dim_lvl2
    AS
        SELECT DISTINCT
            gender
        FROM
            person;

/*Agent Temfact*/
CREATE TABLE agent_tempfact_lvl2
    AS
        SELECT
            person_id,
            gender,
            salary,
            suburb,
            state_code,
            SUM(price) "Total Worth"
        FROM
            (
                SELECT
                    a.person_id,
                    pe.gender,
                    a.salary,
                    ad.suburb,
                    pc.state_code,
                    s.price
                FROM
                    agent          a
                    LEFT JOIN sale           s ON a.person_id = s.agent_person_id
                    LEFT JOIN property       p ON s.property_id = p.property_id
                    LEFT JOIN address        ad ON p.address_id = ad.address_id
                    LEFT JOIN postcode       pc ON pc.postcode = ad.postcode
                    LEFT JOIN agent_office   ao ON a.person_id = ao.person_id
                    LEFT JOIN person         pe ON a.person_id = pe.person_id
                UNION
                SELECT
                    a.person_id,
                    pe.gender,
                    a.salary,
                    ad.suburb,
                    pc.state_code,
                    r.price * ( r.rent_end_date - r.rent_start_date ) / 7
                FROM
                    agent          a
                    LEFT JOIN rent           r ON a.person_id = r.agent_person_id
                    LEFT JOIN property       p ON r.property_id = p.property_id
                    LEFT JOIN address        ad ON p.address_id = ad.address_id
                    LEFT JOIN postcode       pc ON pc.postcode = ad.postcode
                    LEFT JOIN agent_office   ao ON a.person_id = ao.person_id
                    LEFT JOIN person         pe ON a.person_id = pe.person_id
            )
        WHERE
            price IS NOT NULL
        GROUP BY
            person_id,
            gender,
            suburb,
            state_code,
            salary
        ORDER BY
            SUM(price) DESC;

ALTER TABLE agent_tempfact_lvl2 ADD office_size VARCHAR(10);

SELECT
    a.person_id
FROM
    agent_tempfact_lvl2       a
    JOIN agent_office_bridge_dim   b ON a.person_id = b.person_id
WHERE
    b.office_id IN (
        SELECT
            office_id
        FROM
            agent_office
        GROUP BY
            office_id
        HAVING
            COUNT(person_id) < 4
    );

UPDATE agent_tempfact_lvl2
SET
    office_size = 'Small'
WHERE
    person_id IN (
        SELECT
            a.person_id
        FROM
            agent_tempfact_lvl2   a
            JOIN agent_office          b ON a.person_id = b.person_id
        WHERE
            b.office_id IN (
                SELECT
                    office_id
                FROM
                    agent_office
                GROUP BY
                    office_id
                HAVING
                    COUNT(person_id) < 4
            )
    );

UPDATE agent_tempfact_lvl2
SET
    office_size = 'Medium'
WHERE
    person_id IN (
        SELECT
            a.person_id
        FROM
            agent_tempfact_lvl2   a
            JOIN agent_office          b ON a.person_id = b.person_id
        WHERE
            b.office_id IN (
                SELECT
                    office_id
                FROM
                    agent_office
                GROUP BY
                    office_id
                HAVING
                    COUNT(person_id) BETWEEN 4 AND 12
            )
    );

UPDATE agent_tempfact_lvl2
SET
    office_size = 'Big'
WHERE
    person_id IN (
        SELECT
            a.person_id
        FROM
            agent_tempfact_lvl2   a
            JOIN agent_office          b ON a.person_id = b.person_id
        WHERE
            b.office_id IN (
                SELECT
                    office_id
                FROM
                    agent_office
                GROUP BY
                    office_id
                HAVING
                    COUNT(person_id) > 12
            )
    );

/*Agent Fact TABLE*/

CREATE TABLE agent_fact_lvl2
    AS
        SELECT
            person_id,
            gender,
            suburb,
            state_code,
            office_size AS office_type,
            SUM(salary) "Total Salary",
            SUM("Total Worth") "Total Worth",
            COUNT(DISTINCT person_id) "Total Agents"
        FROM
            agent_tempfact_lvl2
        GROUP BY (
            person_id,
            gender,
            suburb,
            state_code,
            office_size
        );

/*SELECT Queries*/
SELECT * FROM agent_info_dim_lvl2;
SELECT * FROM office_dim_lvl2;
SELECT * FROM agent_office_bridge_dim_lvl2;
SELECT * FROM office_size_dim_lvl2;
SELECT * FROM gender_dim_lvl2;
SELECT * FROM agent_tempfact_lvl2;
SELECT * FROM agent_fact_lvl2;

------------------------------------------------------------------------------------------------

-----Sale-----
/*DROP TABLEs*/
DROP TABLE sale_year_dim_lvl2;
DROP TABLE sale_tempfact_lvl2;
DROP TABLE sale_fact_lvl2;
DROP TABLE property_feature_dim_lvl2;

/*Sale year Dimension*/
CREATE TABLE sale_year_dim_lvl2
    AS
        SELECT DISTINCT
            to_char(sale_date, 'yyyy') AS year
        FROM
            sale
        WHERE
            NOT sale_date IS NULL;
            
/*Property Feature Dimension*/

CREATE TABLE property_feature_dim_lvl2
    AS
        SELECT
            property_id,
            feature_code
        FROM
            property_feature;

/*Sale Tempfact TABLE*/

CREATE TABLE sale_tempfact_lvl2
    AS
        SELECT
            s.property_id,
            p.property_type,
            to_char(sale_date, 'yyyy') AS year,
            ad.suburb,
            pc.state_code,
            s.price
        FROM
            sale       s
            JOIN property   p ON s.property_id = p.property_id
            JOIN address    ad ON ad.address_id = p.address_id
            JOIN postcode   pc ON pc.postcode = ad.postcode
        WHERE
            NOT s.client_person_id IS NULL;
            
/*Sale Fact TABLE*/
CREATE TABLE sale_fact_lvl2
    AS
        SELECT
            property_id,
            property_type,
            year,
            suburb,
            state_code,
            SUM(price) "Total Price",
            COUNT(property_id) "Number of Sales"
        FROM
            sale_tempfact_lvl2
        GROUP BY
            property_id,
            property_type,
            year,
            suburb,
            state_code;
    
    
/*SELECT Queries*/
SELECT * FROM sale_year_dim_lvl2;
SELECT * FROM sale_tempfact_lvl2;
SELECT * FROM sale_fact_lvl2;

----------------------------------------------------------------------------------

-----VISIT DIMENSION AND FACT CREATION-----
/*DROP TABLEs*/
DROP TABLE season_dim_lvl2;
DROP TABLE client_visit_dim_scd_lvl2;
DROP TABLE visit_tempfact_lvl2;
DROP TABLE visit_fact_lvl2;

/*Seaspon dimension*/
CREATE TABLE season_dim_lvl2 (
    season           VARCHAR(10),
    month_interval   VARCHAR(20)
);

INSERT INTO season_dim_lvl2 VALUES (
    'Summer',
    'Dec-Feb'
);

INSERT INTO season_dim_lvl2 VALUES (
    'Autumn',
    'Mar-May'
);

INSERT INTO season_dim_lvl2 VALUES (
    'Winter',
    'Jun-Aug'
);

INSERT INTO season_dim_lvl2 VALUES (
    'Spring',
    'Sep-Nov'
);

/*Client Visit SCD Dimension*/
CREATE TABLE client_visit_dim_scd_lvl2 AS SELECT
    client_person_id,
    property_id, visit_date FROM
visit;

/*Visit Tempfact TABLE*/

CREATE TABLE visit_tempfact_lvl2
    AS
        SELECT
            v.client_person_id,
            p.property_id,
            v.visit_date
        FROM
            visit      v
            JOIN property   p ON p.property_id = v.property_id;

ALTER TABLE visit_tempfact_lvl2 ADD season VARCHAR(10);

UPDATE visit_tempfact_lvl2
SET
    season = 'Summer'
WHERE
    to_char(visit_date, 'mon') IN (
        'dec',
        'jan',
        'feb'
    );

UPDATE visit_tempfact_lvl2
SET
    season = 'Autumn'
WHERE
    to_char(visit_date, 'mon') IN (
        'mar',
        'apr',
        'may'
    );

UPDATE visit_tempfact_lvl2
SET
    season = 'Winter'
WHERE
    to_char(visit_date, 'mon') IN (
        'jun',
        'jul',
        'aug'
    );

UPDATE visit_tempfact_lvl2
SET
    season = 'Spring'
WHERE
    to_char(visit_date, 'mon') IN (
        'sep',
        'oct',
        'nov'
    );

/*Visit Fact TABLE*/

CREATE TABLE visit_fact_lvl2
    AS
        SELECT
            property_id,
            season,
            COUNT(visit_date) "Total number of Visits"
        FROM
            visit_tempfact_lvl2
        GROUP BY
            property_id,
            season;


/*SELECT Queries*/

SELECT * FROM season_dim_lvl2;
SELECT * FROM client_visit_dim_scd_lvl2;
SELECT * FROM visit_tempfact_lvl2;
SELECT * FROM visit_fact_lvl2;
COMMIT;

/*Version 2*/


----------------------------------------------------------------------------------
/*Queries to create Level 0 Star Schema*/ 

-----CLIENT DIMENSION AND FACT CREATION-----
/*Drop CLIENT TABLEs*/
DROP TABLE client_dim_lvl0;
DROP TABLE client_year_dim_lvl0;
DROP TABLE budget_type_dim_lvl0;
DROP TABLE client_wishlist_dim_lvl0;
DROP TABLE client_tempfact_lvl0;
DROP TABLE client_fact_lvl0;
DROP TABLE feature_dim_lvl0;
DROP TABLE property_feature_dim_lvl0;

/*Client Dimesnion*/
CREATE TABLE client_dim_lvl0
    AS
        SELECT DISTINCT
            person_id
        FROM
            client;

/*Feature Dimension*/

CREATE TABLE feature_dim_lvl0
    AS
        SELECT
            feature_code,
            feature_description
        FROM
            feature;

/*Property Feature Dimension*/

CREATE TABLE property_feature_dim_lvl0
    AS
        SELECT
            property_id,
            feature_code
        FROM
            property_feature;

/*Client Year Dimension TAble*/

CREATE TABLE client_year_dim_lvl0
    AS
        SELECT DISTINCT
            year
        FROM
            (
                SELECT
                    to_char(rent_start_date, 'yyyy') AS year
                FROM
                    rent
                UNION
                SELECT
                    to_char(sale_date, 'yyyy') AS year
                FROM
                    sale
                UNION
                SELECT
                    to_char(visit_date, 'yyyy') AS year
                FROM
                    visit
            )
        WHERE
            NOT year IS NULL;
    
/*Budget tyoe dimension*/

CREATE TABLE budget_type_dim_lvl0 (
    budget_type          VARCHAR(10),
    budget_description   VARCHAR(20)
);

INSERT INTO budget_type_dim_lvl0 VALUES (
    'Low',
    '0-1000'
);

INSERT INTO budget_type_dim_lvl0 VALUES (
    'Medium',
    '1001-100000'
);

INSERT INTO budget_type_dim_lvl0 VALUES (
    'High',
    '100001-10000000'
);

/*Client wishlist dimension*/

CREATE TABLE client_wishlist_dim_lvl0
    AS
        SELECT
            *
        FROM
            client_wish;

/*Client Tempfact Table*/

CREATE TABLE client_tempfact_lvl0
    AS
        SELECT
            person_id,
            max_budget,
            MIN(year) AS year
        FROM
            (
                SELECT
                    person_id,
                    max_budget,
                    to_char(rent_start_date, 'yyyy') AS year
                FROM
                    client   c
                    JOIN rent     r ON c.person_id = r.client_person_id
                UNION
                SELECT
                    person_id,
                    max_budget,
                    to_char(sale_date, 'yyyy') AS year
                FROM
                    client   c
                    JOIN sale     s ON c.person_id = s.client_person_id
                UNION
                SELECT
                    person_id,
                    max_budget,
                    to_char(visit_date, 'yyyy') AS year
                FROM
                    client   c
                    JOIN visit    v ON c.person_id = v.client_person_id
            )
        GROUP BY
            person_id,
            max_budget;

ALTER TABLE client_tempfact_lvl0 ADD budget_type VARCHAR(10);

UPDATE client_tempfact_lvl0
SET
    budget_type = 'Low'
WHERE
    max_budget BETWEEN 0 AND 1000;

UPDATE client_tempfact_lvl0
SET
    budget_type = 'Medium'
WHERE
    max_budget BETWEEN 1001 AND 100000;

UPDATE client_tempfact_lvl0
SET
    budget_type = 'High'
WHERE
    max_budget BETWEEN 100001 AND 10000000;

/*Client Fact Table*/

CREATE TABLE client_fact_lvl0
    AS
        SELECT DISTINCT
            ( person_id ),
            budget_type,
            year,
            COUNT(person_id) "Number of Clients"
        FROM
            client_tempfact_lvl0
        GROUP BY
            person_id,
            budget_type,
            year;


/*SELECT Queries for CLIENT*/
SELECT * FROM client_dim_lvl0; 
SELECT * FROM budget_type_dim_lvl0;
SELECT * FROM client_wishlist_dim_lvl0;
SELECT * FROM client_tempfact_lvl0;
SELECT * FROM client_fact_lvl0;
SELECT * FROM client_year_dim_lvl0;
SELECT * FROM feature_dim_lvl0;
SELECT * FROM property_feature_dim_lvl0;

----------------------------------------------------------------------------------

-----VISIT DIMENSION AND FACT CREATION-----
/*Drop all the Tables*/
DROP TABLE season_dim_lvl0;
DROP TABLE client_visit_dim_lvl0;
DROP TABLE client_visit_dim_scd_lvl0;
DROP TABLE visit_tempfact_lvl0;
DROP TABLE visit_fact_lvl0;

/*Season Dimension*/
CREATE TABLE season_dim_lvl0 (
    season           VARCHAR(10),
    month_interval   VARCHAR(20)
);

INSERT INTO season_dim_lvl0 VALUES (
    'Summer',
    'Dec-Feb'
);

INSERT INTO season_dim_lvl0 VALUES (
    'Autumn',
    'Mar-May'
);

INSERT INTO season_dim_lvl0 VALUES (
    'Winter',
    'Jun-Aug'
);

INSERT INTO season_dim_lvl0 VALUES (
    'Spring',
    'Sep-Nov'
);

/*Client Visit Dimension*/

CREATE TABLE client_visit_dim_lvl0
    AS
        SELECT DISTINCT
            client_person_id,
            property_id
        FROM
            visit;

/*Client Visit SCD Dimension*/

CREATE TABLE client_visit_dim_scd_lvl0
    AS
        SELECT
            client_person_id,
            property_id,
            visit_date
        FROM
            visit;

/*Visit Tempfact Table*/

CREATE TABLE visit_tempfact_lvl0
    AS
        SELECT
            client_person_id,
            property_id,
            visit_date
        FROM
            visit;

ALTER TABLE visit_tempfact_lvl0 ADD season VARCHAR(10);

UPDATE visit_tempfact_lvl0
SET
    season = 'Summer'
WHERE
    to_char(visit_date, 'mon') IN (
        'dec',
        'jan',
        'feb'
    );

UPDATE visit_tempfact_lvl0
SET
    season = 'Autumn'
WHERE
    to_char(visit_date, 'mon') IN (
        'mar',
        'apr',
        'may'
    );

UPDATE visit_tempfact_lvl0
SET
    season = 'Winter'
WHERE
    to_char(visit_date, 'mon') IN (
        'jun',
        'jul',
        'aug'
    );

UPDATE visit_tempfact_lvl0
SET
    season = 'Spring'
WHERE
    to_char(visit_date, 'mon') IN (
        'sep',
        'oct',
        'nov'
    );

/*Visit Fact Table*/

CREATE TABLE visit_fact_lvl0
    AS
        SELECT
            client_person_id,
            property_id,
            season,
            COUNT(visit_date) "Total number of Visits"
        FROM
            visit_tempfact_lvl0
        GROUP BY
            client_person_id,
            property_id,
            season;
/*SELECT Queries*/
SELECT * FROM season_dim_lvl0;
SELECT * FROM client_visit_dim_lvl0;
SELECT * FROM client_visit_dim_scd_lvl0;
SELECT * FROM visit_tempfact_lvl0;
SELECT * FROM visit_fact_lvl0;

-----------------------------------------------------------------------------------------------------------
-----RENT-----
/*Drop Rent Tables*/
DROP TABLE property_feature_category_dim_lvl0;
DROP TABLE property_scale_dim_lvl0;
DROP TABLE property_type_dim_lvl0;
DROP TABLE rent_time_period_dim_lvl0;
DROP TABLE rent_year_dim_lvl0;
DROP TABLE property_dim_lvl0;
DROP TABLE property_rent_scd_lvl0;
DROP TABLE rent_tempfact_lvl0;
DROP TABLE rent_fact_lvl0;

/* Property Feature Category Dimension*/
CREATE TABLE property_feature_category_dim_lvl0 (
    category        VARCHAR(20),
    feature_count   VARCHAR(20)
);

INSERT INTO property_feature_category_dim_lvl0 VALUES (
    'Very basic',
    '<10'
);

INSERT INTO property_feature_category_dim_lvl0 VALUES (
    'Standard',
    '10-20'
);

INSERT INTO property_feature_category_dim_lvl0 VALUES (
    'Luxurious',
    '>20'
);

/*Property Scale Dimension*/

CREATE TABLE property_scale_dim_lvl0 (
    scale_type       VARCHAR(20),
    no_of_bedrooms   VARCHAR(20)
);

INSERT INTO property_scale_dim_lvl0 VALUES (
    'Extra small',
    '<=1'
);

INSERT INTO property_scale_dim_lvl0 VALUES (
    'Small',
    '2-3'
);

INSERT INTO property_scale_dim_lvl0 VALUES (
    'Medium',
    '3-6'
);

INSERT INTO property_scale_dim_lvl0 VALUES (
    'Large',
    '6-10'
);

INSERT INTO property_scale_dim_lvl0 VALUES (
    'Extra large',
    '>10'
);

/*Property Type Dimension*/

CREATE TABLE property_type_dim_lvl0
    AS
        SELECT DISTINCT
            property_type
        FROM
            monre.property;

/*Rent Time Period Dimension*/

CREATE TABLE rent_time_period_dim_lvl0 (
    period            VARCHAR(20),
    duration_months   VARCHAR(20)
);

INSERT INTO rent_time_period_dim_lvl0 VALUES (
    'Short',
    '<6'
);

INSERT INTO rent_time_period_dim_lvl0 VALUES (
    'Medium',
    '6-12'
);

INSERT INTO rent_time_period_dim_lvl0 VALUES (
    'Long',
    '>12'
);

/*Rent Year Dimension*/

CREATE TABLE rent_year_dim_lvl0
    AS
        SELECT DISTINCT
            to_char(rent_start_date, 'yyyy') AS year
        FROM
            rent
        WHERE
            NOT ( to_char(rent_start_date, 'yyyy') ) IS NULL;

/*Property Dimension*/

CREATE TABLE property_dim_lvl0
    AS
        SELECT
            p.property_id,
            ad.suburb,
            pc.state_code
        FROM
            property   p
            JOIN address    ad ON p.address_id = ad.address_id
            JOIN postcode   pc ON ad.postcode = pc.postcode;
    
/*Property Rent SCD Dimension*/

CREATE TABLE property_rent_scd_lvl0
    AS
        SELECT
            rent_start_date,
            rent_end_date,
            property_id,
            price
        FROM
            rent
        WHERE
            NOT rent_start_date IS NULL;

/*Rent TempFact Table*/

CREATE TABLE rent_tempfact_lvl0
    AS
        SELECT
            rent_id,
            r.property_id,
            COUNT(feature_code) AS "Feature count",
            property_type,
            floor(months_between(to_date(rent_end_date, 'dd-mm-yyyy'), to_date(rent_start_date, 'dd-mm-yyyy'))) AS months,
            to_char(rent_start_date, 'yyyy') AS years,
            price * ( ( to_date(rent_end_date, 'dd-mm-yyyy') - to_date(rent_start_date, 'dd-mm-yyyy') ) / 7 ) AS price,
            p.property_no_of_bedrooms
        FROM
            rent

R

JOIN property p ON r.property_id = p.property_id 
    JOIN property_feature pf ON p.property_id=pf.property_id 
    JOIN address ad ON ad.address_id=p.address_id 
    JOIN postcode pc ON ad.postcode=pc.postcode
    WHERE NOT r.rent_start_date IS NULL
    GROUP BY (rent_id, r.property_id, property_type, months_between(TO_DATE(rent_end_date,'dd-mm-yyyy'),TO_DATE(rent_start_date,'dd-mm-yyyy')),
        to_char(rent_start_date,'yyyy'), price*((TO_DATE(rent_end_date,'dd-mm-yyyy')-TO_DATE(rent_start_date,'dd-mm-yyyy'))/7), p.property_no_of_bedrooms);
        
ALTER TABLE rent_tempfact_lvl0 ADD category VARCHAR(20); 

UPDATE rent_tempfact_lvl0 SET category='Very basic' WHERE "Feature count"<10;
UPDATE rent_tempfact_lvl0 SET category='Standard' WHERE "Feature count" between 10 and 20;
UPDATE rent_tempfact_lvl0 SET category='Luxurious' WHERE "Feature count">20;

ALTER TABLE rent_tempfact_lvl0 ADD scale_type VARCHAR(20);

UPDATE rent_tempfact_lvl0 SET scale_type='Extra small' WHERE property_no_of_bedrooms<=1;
UPDATE rent_tempfact_lvl0 SET scale_type='Small' WHERE property_no_of_bedrooms BETWEEN 2 AND 3;
UPDATE rent_tempfact_lvl0 SET scale_type='Medium' WHERE property_no_of_bedrooms BETWEEN 4 AND 6;
UPDATE rent_tempfact_lvl0 SET scale_type='Large' WHERE property_no_of_bedrooms BETWEEN 7 AND 10;
UPDATE rent_tempfact_lvl0 SET scale_type='Extra large' WHERE property_no_of_bedrooms>10;

ALTER TABLE rent_tempfact_lvl0 ADD period VARCHAR(20);

UPDATE rent_tempfact_lvl0 SET period='Short' WHERE Months<6;
UPDATE rent_tempfact_lvl0 SET period='Medium' WHERE Months BETWEEN 6 AND 12;
UPDATE rent_tempfact_lvl0 SET period='Long' WHERE Months>12;

/*Rent Fact Table*/
CREATE TABLE rent_fact_lvl0
    AS
        SELECT
            property_id,
            property_type,
            years,
            category,
            scale_type,
            period,
            COUNT(rent_id) AS "Total Number of Rent",
            SUM(price) AS "Total Rental Fees"
        FROM
            rent_tempfact_lvl0
        GROUP BY (
            property_id,
            property_type,
            years,
            category,
            scale_type,
            period
        );
/*SELECT Queries*/
SELECT * FROM property_feature_category_dim_lvl0;
SELECT * FROM property_scale_dim_lvl0;
SELECT * FROM property_type_dim_lvl0;
SELECT * FROM rent_time_period_dim_lvl0;
SELECT * FROM rent_year_dim_lvl0;
SELECT * FROM property_dim_lvl0;
SELECT * FROM property_rent_scd_lvl0;
SELECT * FROM rent_tempfact_lvl0;
SELECT * FROM rent_fact_lvl0;

--------------------------------------------------------------------------------------------
-----Agent-----
/*Drop Tables*/
DROP TABLE agent_info_dim_lvl0;
DROP TABLE agent_office_bridge_dim_lvl0;
DROP TABLE office_dim_lvl0;
DROP TABLE office_size_dim_lvl0;
DROP TABLE gender_dim_lvl0;
DROP TABLE agent_tempfact_lvl0;
DROP TABLE agent_fact_lvl0;

/*Agent Information Dimension*/
CREATE TABLE agent_info_dim_lvl0
    AS
        SELECT DISTINCT
            ( a.person_id ),
            p.title
            || ' '
            || p.first_name
            || ' '
            || p.last_name AS "Agent Name"
        FROM
            agent

A
join

person p ON a.person_id = p.person_id;
    
/*Agent Office Bridge Dimension*/
CREATE TABLE agent_office_bridge_dim_lvl0 AS SELECT person_Id, office_id FROM agent_office;

/*Office Dimension*/
CREATE TABLE office_dim_lvl0 AS SELECT office_id, office_name FROM
office;

/*Office Size Dimension*/

CREATE TABLE office_size_dim_lvl0 (
    office_type       VARCHAR2(30),
    no_of_employees   VARCHAR2(40)
);

INSERT INTO office_size_dim_lvl0 VALUES (
    'Small',
    '< 4'
);

INSERT INTO office_size_dim_lvl0 VALUES (
    'Medium',
    ' 4-12'
);

INSERT INTO office_size_dim_lvl0 VALUES (
    'Large',
    '> 12'
);

/*Gender Dimension*/
CREATE TABLE gender_dim_lvl0 AS SELECT DISTINCT gender FROM person;

/*Agent Tempfact Table*/
CREATE TABLE agent_tempfact_lvl0
    AS
        SELECT
            person_id,
            gender,
            property_id,
            salary,
            SUM(price) "Total Worth",
            COUNT(person_id) "Total Agents"
        FROM
            (
                SELECT
                    a.person_id,
                    pe.gender,
                    a.salary,
                    p.property_id,
                    s.price
                FROM
                    agent          a
                    LEFT JOIN sale           s ON a.person_id = s.agent_person_id
                    LEFT JOIN property       p ON s.property_id = p.property_id
                    LEFT JOIN address        ad ON p.address_id = ad.address_id
                    LEFT JOIN agent_office   ao ON a.person_id = ao.person_id
                    LEFT JOIN person         pe ON a.person_id = pe.person_id
                UNION
                SELECT
                    a.person_id,
                    pe.gender,
                    a.salary,
                    p.property_id,
                    r.price * ( r.rent_end_date - r.rent_start_date ) / 7
                FROM
                    agent          a
                    LEFT JOIN rent           r ON a.person_id = r.agent_person_id
                    LEFT JOIN property       p ON r.property_id = p.property_id
                    LEFT JOIN address        ad ON p.address_id = ad.address_id
                    LEFT JOIN agent_office   ao ON a.person_id = ao.person_id
                    LEFT JOIN person         pe ON a.person_id = pe.person_id
            )
        WHERE
            price IS NOT NULL
        GROUP BY
            person_id,
            gender,
            property_id,
            salary
        ORDER BY
            SUM(price) DESC;

ALTER TABLE agent_tempfact_lvl0 ADD office_type VARCHAR(10);

UPDATE agent_tempfact_lvl0
SET
    office_type = 'Small'
WHERE
    person_id IN (
        SELECT
            a.person_id
        FROM
            agent_tempfact_lvl0   a
            JOIN agent_office          b ON a.person_id = b.person_id
        WHERE
            b.office_id IN (
                SELECT
                    office_id
                FROM
                    agent_office
                GROUP BY
                    office_id
                HAVING
                    COUNT(person_id) < 4
            )
    );

UPDATE agent_tempfact_lvl0
SET
    office_type = 'Medium'
WHERE
    person_id IN (
        SELECT
            a.person_id
        FROM
            agent_tempfact_lvl0   a
            JOIN agent_office          b ON a.person_id = b.person_id
        WHERE
            b.office_id IN (
                SELECT
                    office_id
                FROM
                    agent_office
                GROUP BY
                    office_id
                HAVING
                    COUNT(person_id) BETWEEN 4 AND 12
            )
    );

UPDATE agent_tempfact_lvl0
SET
    office_type = 'Big'
WHERE
    person_id IN (
        SELECT
            a.person_id
        FROM
            agent_tempfact_lvl0   a
            JOIN agent_office          b ON a.person_id = b.person_id
        WHERE
            b.office_id IN (
                SELECT
                    office_id
                FROM
                    agent_office
                GROUP BY
                    office_id
                HAVING
                    COUNT(person_id) > 12
            )
    );

/*Agent Fact Table*/

CREATE TABLE agent_fact_lvl0
    AS
        SELECT
            person_id,
            gender,
            property_id,
            office_type,
            SUM(salary) "Total Salary",
            SUM("Total Worth") "Total Worth",
            SUM("Total Agents") "Total Agents"
        FROM
            agent_tempfact_lvl0
        GROUP BY (
            person_id,
            gender,
            property_id,
            office_type
        );


/*SELECT Queries*/
SELECT * FROM agent_info_dim_lvl0;
SELECT * FROM agent_office_bridge_dim_lvl0;
SELECT * FROM office_dim_lvl0;
SELECT * FROM office_size_dim_lvl0;
SELECT * FROM gender_dim_lvl0;
SELECT * FROM agent_tempfact_lvl0;
SELECT * FROM agent_fact_lvl0;

-------------------------------------------------------------------------------------------

-----Advertisement-----
/*Drop Advertisement Tables*/
DROP TABLE advert_date_dim_lvl0;
DROP TABLE property_advert_bridge_dim_lvl0;
DROP TABLE advert_dim_lvl0;
DROP TABLE advertisement_tempfact_lvl0;
DROP TABLE advertisement_fact_lvl0;

/*Advertisement Date Dimension*/
CREATE TABLE advert_date_dim_lvl0
    AS
        SELECT DISTINCT
            to_char(property_date_added, 'Month')
            || ' '
            || to_char(property_date_added, 'yyyy') AS date_id,
            to_char(property_date_added, 'Month') AS month,
            to_char(property_date_added, 'yyyy') AS year
        FROM
            property;

/*Property Advertisement Bridge Dimension*/
CREATE TABLE property_advert_bridge_dim_lvl0
    AS
        SELECT
            property_id,
            advert_id
        FROM
            property_advert;

/*Advertisement Dimension*/

CREATE TABLE advert_dim_lvl0
    AS
        SELECT
            advert_id,
            advert_name
        FROM
            advertisement;

/*Advertisement TempFact Table*/
CREATE TABLE advertisement_tempfact_lvl0
    AS
        SELECT
            p.property_id,
            pd.property_date_added,
            a.advert_name
        FROM
            advertisement

A
join

property_advert p ON a.advert_id = p.advert_id
JOIN property pd ON p.property_id=pd.property_id 
GROUP BY p.property_id,pd.property_date_added,a.advert_name;


/*Advertisement Fact Table*/
CREATE TABLE advertisement_fact_lvl0
    AS
        SELECT
            property_id,
            to_char(property_date_added, 'Month')
            || ' '
            || to_char(property_date_added, 'yyyy') date_id,
            COUNT(property_id) "Total number of Properties"
        FROM
            advertisement_tempfact_lvl0
        GROUP BY
            property_id,
            to_char(property_date_added, 'Month')
            || ' '
            || to_char(property_date_added, 'yyyy');
/*Select Queries*/
SELECT * FROM advert_date_dim_lvl0;
SELECT * FROM property_advert_bridge_dim_lvl0;
SELECT * FROM advert_dim_lvl0;
SELECT * FROM advertisement_tempfact_lvl0;
SELECT * FROM advertisement_fact_lvl0;

------------------------------------------------------------------------------------------------

-----Sale-----
/*Drop Tables*/
DROP TABLE sale_year_lvl0;
DROP TABLE sale_tempfact_lvl0;
DROP TABLE sale_fact_lvl0;

/*Sale Year DIMENSION*/
CREATE TABLE sale_year_lvl0
    AS
        SELECT DISTINCT
            ( to_char(sale_date, 'yyyy') ) AS sale_year
        FROM
            sale
        WHERE
            NOT ( to_char(sale_date, 'yyyy') ) IS NULL;

/*Sale Tempfact Table*/

CREATE TABLE sale_tempfact_lvl0
    AS
        SELECT
            s.property_id,
            p.property_type,
            to_char(s.sale_date, 'yyyy') AS sale_year,
            s.price
        FROM
            sale            s
            JOIN property        p ON s.property_id = p.property_id
            JOIN monre.address   ad ON ad.address_id = p.address_id
            JOIN postcode        pc ON pc.postcode = ad.postcode
        WHERE
            NOT s.client_person_id IS NULL;

/*Sale Fact Table*/
CREATE TABLE sale_fact_lvl0
    AS
        SELECT
            property_id,
            property_type,
            sale_year,
            SUM(price) "Total Price",
            COUNT(property_id) "Number of Sales"
        FROM
            sale_tempfact_lvl0
        GROUP BY
            property_id,
            property_type,
            sale_year;

/*Select Queries*/

SELECT * FROM sale_tempfact_lvl0;

SELECT * FROM sale_fact_lvl0;

SELECT * FROM sale_year_lvl0;
commit;