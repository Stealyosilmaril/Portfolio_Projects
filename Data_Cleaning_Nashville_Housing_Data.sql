SELECT * FROM nash
WHERE propertyaddress IS NULL

--alter date column data type (text to date) with to_
ALTER TABLE nash
ALTER COLUMN saledate TYPE DATE USING TO_DATE(saledate, 'Month-DD-YYYY');


--altering empty string to null value
UPDATE nash SET propertyaddress = NULL WHERE propertyaddress='';


--adding address field to all rows. This way populates all null addresses with the first address that the coalesce function finds.
SELECT a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress,
       COALESCE(a.propertyaddress, b.propertyaddress)  AS nullsreplaced
FROM nash a
JOIN nash b
    ON a.parcelid = b.parcelid
    AND a.uniqueid != b.uniqueid
WHERE a.propertyaddress IS NULL

-- way that works. CASE WHEN also applies here under slight changes
UPDATE nash AS a
SET PropertyAddress = COALESCE(b.propertyaddress, a.propertyaddress)
FROM nash AS b
WHERE a.parcelid = b.parcelid AND a.uniqueid <> b.uniqueid AND a.propertyaddress IS NULL

--Separating propertyaddress into two distinct fields with substring and STRPOS function
SELECT SUBSTRING(propertyaddress, 0, STRPOS(propertyaddress, ',')) AS address,
       SUBSTRING(propertyaddress, STRPOS(propertyaddress, ',')+1, LENGTH(propertyaddress)) AS address
FROM nash;


ALTER TABLE nash ADD COLUMN property_city text, ADD COLUMN property_address text;

UPDATE nash
SET property_address = SUBSTRING(propertyaddress, 0, STRPOS(propertyaddress, ','));

UPDATE nash
SET property_city = SUBSTRING(propertyaddress, STRPOS(propertyaddress, ',')+1, LENGTH(propertyaddress));


--Postgres also has a function, SPLIT_PART, that is even easier to use. It splits a string on a selected delimiter. Here we'll split
--the owneraddress into three distinct parts: the house address itself, the house, and then the house state
ALTER TABLE nash ADD COLUMN  owner_address text, ADD COLUMN owner_city text, ADD COLUMN owner_state text;
UPDATE nash SET owner_address = SPLIT_PART(owneraddress, ',', 1);
UPDATE nash SET owner_city = SPLIT_PART(owneraddress, ',', 2);
UPDATE nash SET owner_state = SPLIT_PART(owneraddress, ',', 3);

--Changing all 'Y' and 'N' values to 'Yes' and 'No' values in the soldasvacant column

SELECT DISTINCT(soldasvacant), COUNT(soldasvacant)
FROM nash
GROUP BY soldasvacant

SELECT soldasvacant,
    CASE WHEN soldasvacant = 'Y' THEN 'Yes'
    WHEN soldasvacant = 'N' THEN 'No'
    ELSE soldasvacant
    END
FROM nash

UPDATE nash
SET soldasvacant =
    CASE WHEN soldasvacant = 'Y' THEN 'Yes'
    WHEN soldasvacant = 'N' THEN 'No'
    ELSE soldasvacant
    END

--deleting duplicates. The way described below works in SQL Server, but not Postgres
WITH row_number_cte AS(
SELECT *, ROW_NUMBER() OVER (
    PARTITION BY parcelid, propertyaddress, saleprice, saledate, legalreference
    ORDER BY uniqueid) AS row_number
FROM nash)
DELETE
FROM nash
USING nash a
JOIN row_number_cte b
ON a.parcelid = b.parcelid
WHERE row_number >1;

-- this way works with Postgres
DELETE FROM nash
WHERE uniqueid IN
    (SELECT uniqueid
    FROM
        (SELECT uniqueid,
         ROW_NUMBER() OVER( PARTITION BY parcelid, propertyaddress, saleprice, saledate, legalreference
        ORDER BY  uniqueid ) AS row_number
        FROM nash ) t
        WHERE t.row_number > 1 );

--deleting unused columns
ALTER TABLE nash DROP COLUMN propertyaddress, DROP COLUMN owneraddress, DROP COLUMN taxdistrict
