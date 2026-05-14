-- 1.1 List customers subscribed to 'Kobiye Destek' tariff
-- We join the CUSTOMERS and TARIFFS tables using the TARIFF_ID foreign key to access the tariff name.
-- Then, we filter the results with a WHERE clause specifically looking for the 'Kobiye Destek' plan.
-- Finally, we select relevant customer details such as their ID, Name, City, and Signup Date to provide a complete list.
SELECT c.CUSTOMER_ID, c.NAME, c.CITY, c.SIGNUP_DATE
FROM CUSTOMERS c
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
WHERE t.NAME = 'Kobiye Destek';


-- 1.2 Find the newest customer who subscribed to this tariff
-- We start by joining CUSTOMERS and TARIFFS to filter down to customers on the 'Kobiye Destek' plan.
-- To find the newest customer, we use the ORDER BY clause on SIGNUP_DATE in descending order.
-- We then use the FETCH FIRST 1 ROWS ONLY syntax (standard in modern Oracle) to limit the output to the single most recent signup.
SELECT c.CUSTOMER_ID, c.NAME, c.CITY, c.SIGNUP_DATE
FROM CUSTOMERS c
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
WHERE t.NAME = 'Kobiye Destek'
ORDER BY c.SIGNUP_DATE DESC
FETCH FIRST 1 ROWS ONLY;


-- 2.1 Find the distribution of tariffs among customers
-- We perform a LEFT JOIN from TARIFFS to CUSTOMERS to ensure all tariffs are listed, even if they have no current customers.
-- By grouping the results by the tariff name, we can aggregate the data on a per-tariff basis.
-- The COUNT function tallies the number of associated CUSTOMER_IDs for each tariff, and we sort the list from most to least popular.
SELECT t.NAME AS TARIFF_NAME, COUNT(c.CUSTOMER_ID) AS CUSTOMER_COUNT
FROM TARIFFS t
LEFT JOIN CUSTOMERS c ON t.TARIFF_ID = c.TARIFF_ID
GROUP BY t.NAME
ORDER BY CUSTOMER_COUNT DESC;


-- 3.1 Identify the earliest customers to sign up
-- Since multiple customers could have signed up on the very first day, a simple sort and limit might miss some people.
-- Instead, we use a subquery to definitively find the minimum (earliest) signup date across the entire CUSTOMERS table.
-- Then, the main query selects all customer records whose signup date exactly matches that earliest date.
SELECT CUSTOMER_ID, NAME, CITY, SIGNUP_DATE
FROM CUSTOMERS
WHERE SIGNUP_DATE = (SELECT MIN(SIGNUP_DATE) FROM CUSTOMERS);


-- 3.2 Distribution of earliest customers across cities
-- Building upon the previous logic, we use a WHERE clause with a subquery to isolate the customers who signed up on the first day.
-- We then use the GROUP BY clause on the CITY column to gather these specific customers by their geographic location.
-- Counting the customer IDs within these groups gives us the distribution, which is then ordered to show the cities with the most early adopters first.
SELECT CITY, COUNT(CUSTOMER_ID) AS CUSTOMER_COUNT
FROM CUSTOMERS
WHERE SIGNUP_DATE = (SELECT MIN(SIGNUP_DATE) FROM CUSTOMERS)
GROUP BY CITY
ORDER BY CUSTOMER_COUNT DESC;


-- 4.1 Find IDs of customers with missing monthly records
-- We use a LEFT JOIN starting from the CUSTOMERS table to the MONTHLY_STATS table on the CUSTOMER_ID.
-- This ensures that every customer is included in the intermediate result set, regardless of their activity.
-- By filtering for rows where the MONTHLY_STATS.ID is NULL, we isolate the customers who completely lack any monthly usage records.
SELECT c.CUSTOMER_ID, c.NAME
FROM CUSTOMERS c
LEFT JOIN MONTHLY_STATS m ON c.CUSTOMER_ID = m.CUSTOMER_ID
WHERE m.ID IS NULL;


-- 4.2 Distribution of missing customers across cities
-- Similar to the previous query, we isolate customers lacking usage records by doing a LEFT JOIN and filtering for a NULL stats ID.
-- Once this subset of customers is identified, we group them by their city of residence.
-- Finally, we count the number of missing records per city and order the results descending to highlight problem areas.
SELECT c.CITY, COUNT(c.CUSTOMER_ID) AS MISSING_RECORDS_COUNT
FROM CUSTOMERS c
LEFT JOIN MONTHLY_STATS m ON c.CUSTOMER_ID = m.CUSTOMER_ID
WHERE m.ID IS NULL
GROUP BY c.CITY
ORDER BY MISSING_RECORDS_COUNT DESC;


-- 5.1 Find customers who used at least 75% of their data limit
-- We join the MONTHLY_STATS, CUSTOMERS, and TARIFFS tables together to compare actual usage against the allowed package limits.
-- We add a condition to verify that the DATA_LIMIT is greater than 0, preventing logical issues if a tariff has no data allocation.
-- The core logic checks if the user's DATA_USAGE is greater than or equal to 75% (limit * 0.75) of their specific tariff's data limit.
SELECT c.CUSTOMER_ID, c.NAME, m.DATA_USAGE, t.DATA_LIMIT
FROM MONTHLY_STATS m
JOIN CUSTOMERS c ON m.CUSTOMER_ID = c.CUSTOMER_ID
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
WHERE t.DATA_LIMIT > 0 
  AND m.DATA_USAGE >= (t.DATA_LIMIT * 0.75);


-- 5.2 Find customers who exhausted ALL package limits (data, minutes, SMS)
-- This query requires joining all three tables to associate a customer's usage statistics with their assigned tariff limits.
-- The WHERE clause consists of three separate conditions linked by AND operators to ensure every single limit is checked.
-- Only customers whose actual usage meets or exceeds the limits for data, minutes, AND SMS will be returned by this query.
SELECT c.CUSTOMER_ID, c.NAME, m.DATA_USAGE, m.MINUTE_USAGE, m.SMS_USAGE
FROM MONTHLY_STATS m
JOIN CUSTOMERS c ON m.CUSTOMER_ID = c.CUSTOMER_ID
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
WHERE m.DATA_USAGE >= t.DATA_LIMIT
  AND m.MINUTE_USAGE >= t.MINUTE_LIMIT
  AND m.SMS_USAGE >= t.SMS_LIMIT;


-- 6.1 Find customers with unpaid fees
-- We query the MONTHLY_STATS table which tracks the payment status for each billing cycle.
-- By joining with the CUSTOMERS table, we can retrieve the specific identities (Name, ID) associated with these problem accounts.
-- The WHERE clause strictly filters for the 'UNPAID' status to identify customers who have completely failed to pay their fees.
SELECT c.CUSTOMER_ID, c.NAME, m.PAYMENT_STATUS
FROM MONTHLY_STATS m
JOIN CUSTOMERS c ON m.CUSTOMER_ID = c.CUSTOMER_ID
WHERE m.PAYMENT_STATUS = 'UNPAID';


-- 6.2 Distribution of payment statuses across different tariffs
-- To see how different plans perform regarding payments, we join TARIFFS, CUSTOMERS, and MONTHLY_STATS together.
-- The GROUP BY clause categorizes the results based on a combination of both the tariff name and the payment status.
-- Counting the records within these groups reveals if certain tariffs (e.g., cheaper vs expensive) have higher rates of unpaid or late payments.
SELECT t.NAME AS TARIFF_NAME, m.PAYMENT_STATUS, COUNT(m.ID) AS STATUS_COUNT
FROM MONTHLY_STATS m
JOIN CUSTOMERS c ON m.CUSTOMER_ID = c.CUSTOMER_ID
JOIN TARIFFS t ON c.TARIFF_ID = t.TARIFF_ID
GROUP BY t.NAME, m.PAYMENT_STATUS
ORDER BY t.NAME, m.PAYMENT_STATUS;
