/*Version 1*/

/* REPORT 1 */

/* WHO ARE THE TOP 10 MALE AGENTS IN VICTORIA */
SELECT
    *
FROM
    (
        SELECT
            a.person_id,
            a.gender,
            "Agent Name",
            SUM("Total Worth") AS "Total_worth",
            RANK() OVER(
                ORDER BY
                    SUM("Total Worth") DESC
            ) AS total_worth_rank
        FROM
            agent_fact_lvl2       a,
            agent_info_dim_lvl2   ai
        WHERE
            a.person_id=ai.person_id AND
            state_code = 'VIC'
            AND a.gender = 'Male'
        GROUP BY (
            a.person_id,
            a.gender,
            "Agent Name"
        )
    )
WHERE
    total_worth_rank <= 10;

/* REPORT 2 */

/* /*WHAT ARE THE TOP PERCENTAGE OF PROPERTIES RENTED IN VICTORIA BASED ON DIFFERENT PROPERTY TYPES*/

SELECT
    *
FROM
    (
        SELECT
            PERCENT_RANK() OVER(
                ORDER BY
                    SUM("Total Number of Rent") DESC
            ) AS property_rank,
            state_code,
            property_type
        FROM
            rent_fact_lvl2
        WHERE
            state_code = 'VIC'
        GROUP BY (
            state_code,
            property_type
        )
    )
WHERE
    property_rank <= 0.50
    Order by PROPERTY_RANK desc;

/* REPORT 3 */
/*SHOW ALL THE ADVERTISEMENT NAME AND THE TOTAL NUMBER OF PROPERTIES ADVERTISED UNDER IT */

SELECT
    ad.advert_name,
    SUM("Total number of Properties") AS "Total_number_of_properties"
FROM
    advertisement_fact_lvl2   af,
    advert_dim_lvl2           ad
WHERE
    af.advert_id = ad.advert_id
    AND ad.advert_name LIKE 'Sale%'
GROUP BY (
    ad.advert_name
)
ORDER BY
    SUM("Total number of Properties") DESC;

/* Report 4 and 5 */

/*WHAT ARE THE SUB-TOTAL AND TOTAL RENTAL FEES FROM EACH SUBURB, TIME PERIOD AND PROPERTY TYPE*/

-- Cube

SELECT
    suburb,
    property_type,
    period,
    round(SUM("Total Rental Fees"), 2) AS total_rental_fees
FROM
    rent_fact_lvl2
GROUP BY
    CUBE(suburb,
         property_type,
         period)
ORDER BY
    suburb;

-- Partial Cube

SELECT
    suburb,
    property_type,
    period,
    round(SUM("Total Rental Fees"), 2) AS total_rental_fees
FROM
    rent_fact_lvl2
GROUP BY
    suburb,
    CUBE(property_type,
         period)
ORDER BY
    suburb;

/**************************************/
/* Report 6 and 7 */
-- What is the Sub total and Total Sales for each property type in different year in VIC and SA states

--ROLL UP

SELECT
    state_code,
    property_type,
    year,
    round(SUM("Total Price"), 2) AS total_sales
FROM
    sale_fact_lvl2
WHERE
    state_code IN (
        'VIC',
        'SA'
    )
GROUP BY
    ROLLUP(state_code,
           property_type,
           year)
ORDER BY
    state_code;

-- PARTIAL ROLLUP


SELECT
    state_code,
    property_type,
    year,
    round(SUM("Total Price"), 2) AS total_sales
FROM
    sale_fact_lvl2
WHERE
    state_code IN (
        'VIC',
        'SA'
    )
GROUP BY
    state_code,
    ROLLUP(property_type,
           year)
ORDER BY
    state_code;

/* Report 8 - What is the total number of clients and cumulative number of clients with a high budget in each year? */

SELECT
    year,
    SUM("Number of Clients") AS total_number_of_clients,
    SUM(SUM("Number of Clients")) OVER(
        ORDER BY
            year
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_number_of_clients
FROM
    client_fact_lvl2
WHERE
    budget_id LIKE '%High%'
GROUP BY (
    year
);

/* Report 9 */
/* Total number of visits and cumulative number of visits for each month in every year */

select to_char(v.visit_date, 'mm') as Month,
to_char(v.visit_date, 'YYYY') as Year,
sum("Total number of Visits") as Total_number_of_visits,
sum(sum("Total number of Visits")) over 
(order by to_char(v.visit_date, 'mm'), to_char(v.visit_date, 'YYYY')
rows unbounded preceding) as Cumulative_number_of_visits
from visit_fact_lvl2, client_visit_dim_scd_lvl2 v
group by (to_char(v.visit_date, 'mm'), to_char(v.visit_date, 'YYYY'));


/* Report 10 */

/* TOTAL RENTAL AND MOVING AGGREGATE OF RENTAL FEE FOR EACH MONTH OF DIFFERENT YEARS */

SELECT
    to_char(r.rent_start_date, 'mm') AS month,
    to_char(r.rent_start_date, 'yyyy') AS year,
    round(SUM("Total Rental Fees"), 2) AS total_rental_fees,
    round(AVG(SUM("Total Rental Fees")) OVER(
        ORDER BY
        to_char(r.rent_start_date, 'yyyy'),
            to_char(r.rent_start_date, 'mm')
             
        ROWS 2 PRECEDING
    ), 2) AS moving_aggregate_rental_fees
FROM
    rent_fact_lvl2           rf,
    property_rent_scd_lvl2   r
WHERE
    rf.property_id = r.property_id
GROUP BY (
    to_char(r.rent_start_date, 'mm'),
    to_char(r.rent_start_date, 'yyyy')
);

/* Report 11 */

--Show ranking of each property type based on the yearly total number of sales and the ranking of each state based on the yearly total number of sales.
SELECT
    *
FROM
    sale_fact_lvl2;
-- assumption: total sale is based on total price

SELECT
    property_type,
    year,
    SUM("Total Price"),
    RANK() OVER(
        PARTITION BY property_type
        ORDER BY
            SUM("Total Price") DESC
    ) AS rank_by_property_type,
    RANK() OVER(
        PARTITION BY state_code
        ORDER BY
            SUM("Total Price") DESC
    ) AS rank_by_state
FROM
    sale_fact_lvl2
GROUP BY (
    property_type,
    year,
    state_code
);

/* Report 12 */
-- SHOW THE RANK OF PROPERTY TYPES BASED ON AVERAGE RENT PARTITIONED BY YEAR

SELECT
    property_type,
    years,
    round(AVG("Total Rental Fees"), 2) AS average_rent,
    RANK() OVER(
        PARTITION BY years
        ORDER BY
            AVG("Total Rental Fees") DESC
    ) AS rank_by_property_type
FROM
    rent_fact_lvl2
GROUP BY (
    years,
    property_type
)
ORDER BY
    years;
    
    
    
/*Version 2*/

/* REPORT 1 */

/* WHO ARE THE TOP 10 MALE AGENTS IN VICTORIA */
SELECT
    *
FROM
    (
        SELECT
            a.person_id,
            a.gender,
            "Agent Name",
            SUM("Total Worth") AS "Total_worth",
            RANK() OVER(
                ORDER BY
                    SUM("Total Worth") DESC
            ) AS total_worth_rank
        FROM
            agent_fact_lvl0       a,
            property_dim_lvl0     p,
            agent_info_dim_lvl0   ai
        WHERE
            a.property_id = p.property_id
            AND a.person_id = ai.person_id
            AND p.state_code = 'VIC'
            AND a.gender = 'Male'
        GROUP BY (
            a.person_id,
            a.gender,
            "Agent Name"
        )
    )
WHERE
    total_worth_rank <= 10;

/* REPORT 2 */

/*WHAT ARE THE TOP PERCENTAGE OF PROPERTIES RENTED IN VICTORIA BASED ON DIFFERENT PROPERTY TYPES*/

SELECT
    *
FROM
    (
        SELECT
            PERCENT_RANK() OVER(
                ORDER BY
                    COUNT("Total Number of Rent") DESC
            ) AS property_rank,
            p.state_code,
            r.property_type
        FROM
            rent_fact_lvl0      r,
            property_dim_lvl0   p
        WHERE
            p.property_id = r.property_id
            AND p.state_code = 'VIC'
        GROUP BY (
            p.state_code,
            r.property_type
        )
    )
WHERE
    property_rank <= 0.50;

/* REPORT 3 */

/*SHOW ALL THE ADVERTISEMENT NAME AND THE TOTAL NUMBER OF PROPERTIES ADVERTISED UNDER IT */

SELECT
    ad.advert_name,
    SUM("Total number of Properties") AS "Total_number_of_properties"
FROM
    advertisement_fact_lvl0           af,
    property_advert_bridge_dim_lvl0   pa,
    advert_dim_lvl0                   ad
WHERE
    af.property_id = pa.property_id
    AND pa.advert_id = ad.advert_id
    AND ad.advert_name LIKE 'Sale%'
GROUP BY (
    ad.advert_name
)
ORDER BY
    SUM("Total number of Properties") DESC;

/* Report 4 and 5 */
/*WHAT ARE THE SUB-TOTAL AND TOTAL RENTAL FEES FROM EACH SUBURB, TIME PERIOD AND PROPERTY TYPE*/
-- Cube

SELECT
    pd.suburb,
    r.property_type,
    r.period,
    round(SUM("Total Rental Fees"), 2) AS total_rental_fees
FROM
    rent_fact_lvl0      r,
    property_dim_lvl0   pd
WHERE
    pd.property_id = r.property_id
GROUP BY
    CUBE(pd.suburb,
         r.property_type,
         r.period)
ORDER BY
    pd.suburb;

-- Partial Cube

SELECT
    pd.suburb,
    r.property_type,
    r.period,
    round(SUM("Total Rental Fees"), 2) AS total_rental_fees
FROM
    rent_fact_lvl0      r,
    property_dim_lvl0   pd
WHERE
    pd.property_id = r.property_id
GROUP BY
    pd.suburb,
    CUBE(r.property_type,
         r.period)
ORDER BY
    pd.suburb;

/* Report 6 and 7 */
-- What is the Sub total and Total Sales for each property type in different year in VIC and SA states

--ROLL UP

SELECT
    pd.state_code,
    s.property_type,
    s.sale_year,
    round(SUM("Total Price"), 2) AS total_sales
FROM
    sale_fact_lvl0      s,
    property_dim_lvl0   pd
WHERE
    pd.property_id = s.property_id
    AND pd.state_code IN (
        'VIC',
        'SA'
    )
GROUP BY
    ROLLUP(pd.state_code,
           s.property_type,
           s.sale_year)
ORDER BY
    pd.state_code;

-- PARTIAL ROLLUP

SELECT
    pd.state_code,
    s.property_type,
    s.sale_year,
    round(SUM("Total Price"), 2) AS total_sales
FROM
    sale_fact_lvl0      s,
    property_dim_lvl0   pd
WHERE
    pd.property_id = s.property_id
    AND pd.state_code IN (
        'VIC',
        'SA'
    )
GROUP BY
    pd.state_code,
    ROLLUP(s.property_type,
           s.sale_year)
ORDER BY
    pd.state_code;

--Report 8
--What is the total number of clients and cumulative number of clients with a high budget in each year? 
SELECT
    year,
    SUM("Number of Clients") AS total_number_of_clients,
    SUM(SUM("Number of Clients")) OVER(
        ORDER BY
            year
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_number_of_clients
FROM
    client_fact_lvl0
WHERE
    budget_type LIKE '%High%'
GROUP BY (
    year
);

/* Report 9 */
/* Total number of visits and cumulative number of visits for each month in every year */

SELECT
    to_char(v.visit_date, 'mm') AS month,
    to_char(v.visit_date, 'yyyy') AS year,
    SUM("Total number of Visits") AS total_number_of_visits,
    SUM(SUM("Total number of Visits")) OVER(
        ORDER BY
         to_char(v.visit_date, 'yyyy'),
            to_char(v.visit_date, 'mm')
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_number_of_visits
FROM
    visit_fact_l0,
    client_visit_dim_scd_l0 v
GROUP BY (
    to_char(v.visit_date, 'mm'),
    to_char(v.visit_date, 'yyyy')
);

/* Report 10 */
/* TOTAL RENTAL AND MOVING AGGREGATE OF RENTAL FEE FOR EACH MONTH OF DIFFERENT YEARS */

SELECT
    to_char(r.rent_start_date, 'mm') AS month,
    to_char(r.rent_start_date, 'YYYY') AS year,
    round(SUM("Total Rental Fees"), 2) AS total_rental_fees,
    round(AVG(SUM("Total Rental Fees")) OVER(
        ORDER BY
            to_char(r.rent_start_date, 'YYYY'),
            to_char(r.rent_start_date, 'mm')
            
            
        ROWS 2 PRECEDING
    ), 2) AS moving_aggregate_rental_fees
FROM
    rent_fact_l0           rf,
    property_rent_scd_l0   r
WHERE
    rf.property_id = r.property_id
GROUP BY (
    to_char(r.rent_start_date, 'mm'),
    to_char(r.rent_start_date, 'YYYY')
);

/* Report 11 */
--Show ranking of each property type based on the yearly total number of sales and the ranking of each state based on the yearly total number of sales.
-- Assumption : The total sale is based on the total price
SELECT
    s.property_type,
    s.sale_year,
    SUM("Total Price"),
    RANK() OVER(
        PARTITION BY s.property_type
        ORDER BY
            SUM("Total Price") DESC
    ) AS rank_by_property_type,
    RANK() OVER(
        PARTITION BY p.state_code
        ORDER BY
            SUM("Total Price") DESC
    ) AS rank_by_state
FROM
    sale_fact_lvl0      s,
    property_dim_lvl0   p
WHERE
    s.property_id = p.property_id
GROUP BY (
    s.property_type,
    s.sale_year,
    p.state_code
);

/* Report 12 */
-- SHOW THE RANK OF PROPERTY TYPES BASED ON AVERAGE RENT PARTITIONED BY YEAR

SELECT
    property_type,
    years,
    round(AVG("Total Rental Fees"), 2) AS average_rent,
    RANK() OVER(
        PARTITION BY years
        ORDER BY
            AVG("Total Rental Fees") DESC
    ) AS rank_by_property_type
FROM
    rent_fact_lvl0
GROUP BY (
    years,
    property_type
)
ORDER BY
    years;