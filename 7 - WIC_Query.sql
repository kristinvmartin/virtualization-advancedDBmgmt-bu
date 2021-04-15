--import all other ChMS scripts scripts and the wic vendors csv with table name WIC_Authorized_Vendors before running this script

--function to calculate distance between two zip codes
CREATE OR ALTER FUNCTION f_distance_math (@ZipCode1 decimal(5,0),@ZipCode2 decimal(5,0))
RETURNS decimal(12,2)
AS
BEGIN
	--vars for getting lat/lng
	DECLARE @Lat1 decimal(9,6),@Lng1 decimal(9,6), @Lat2 decimal(9,6), @Lng2 decimal(9,6);
	--vars for arithmetic calc
	DECLARE @X decimal,@Y decimal,@distance decimal (12,2);

	--get lats/lngs
	SET @Lat1 = (SELECT usz.lat FROM US_Zip_codes usz WHERE usz.zip = @ZipCode1);
	SET @Lng1 = (SELECT usz.lng FROM US_Zip_codes usz WHERE usz.zip = @ZipCode1);
	SET @Lat2 = (SELECT usz.lat FROM US_Zip_codes usz WHERE usz.zip = @ZipCode2);
	SET @Lng2 = (SELECT usz.lng FROM US_Zip_codes usz WHERE usz.zip = @ZipCode2);

	--calculations
	SET @X = (69.1 * (@Lat2 - @Lat1));
	SET @Y = (69.1 * (@Lng2 - @Lng1) * cos(@Lat1/57.3));
	SET @distance = SQRT(@X * @X + @Y * @Y);

	RETURN @distance
END
GO

--transformation of WIC data
ALTER TABLE WIC_Authorized_Vendors
ADD vendor_id decimal NOT NULL DEFAULT 0;

--add PK sequence
CREATE SEQUENCE WIC_PK 
START WITH 1
INCREMENT BY 1;

--add PK vals
UPDATE WIC_Authorized_Vendors
SET vendor_id = NEXT VALUE FOR WIC_PK

ALTER TABLE WIC_Authorized_Vendors
ADD PRIMARY KEY (vendor_id);

GO
--get WIC vendors within radius of person's home zip
GO
CREATE OR ALTER VIEW v1_WICVendor_Person_Distance
AS
--fields to return
SELECT	p1.first_name,p1.last_name,p1.email,wv.Vendor AS [WIC Authorized Vendor],wv.[Street Address],wv.City,
		RIGHT('00000'+CAST(wv.[Zip Code] AS varchar(5)),5) AS [Zip Code],wv.Phone,
		dbo.f_distance_math(p1.zip_code,CAST(wv.[Zip Code] AS decimal)) AS distance

--subquery to get person in CT w/ email address)
FROM (SELECT p0.first_name,p0.last_name,p0.email, z.zip_code 
		FROM dbo.Churchgoer p0
		JOIN dbo.Family f
		ON (p0.family_id = f.family_id)
		JOIN dbo.Zip_code z
		ON (f.address_id = z.zip_id)
		--only persons in CT
		WHERE z.state_id = 7
		AND p0.email IS NOT NULL) AS p1

--cross join for all options
CROSS JOIN dbo.WIC_Authorized_Vendors wv
--filter by distance
WHERE dbo.f_distance_math(p1.zip_code,wv.[Zip Code]) < 5;
GO

--test view
SELECT * FROM v1_WICVendor_Person_Distance;

/*
--alternative implementation to mirror denodo configuration, without hard coded mileage value.  Run time extremely long, over 3 mins then I terminated.
GO
CREATE OR ALTER FUNCTION f_WICVendor_Person_Distance(@miles decimal)
RETURNS table
AS
RETURN
(
SELECT p1.first_name,p1.last_name,p1.email,wv.Vendor AS [WIC Authorized Vendor],wv.[Street Address],wv.City,
	RIGHT('00000'+CAST(wv.[Zip Code] AS varchar(5)),5) AS [Zip Code] ,wv.Phone,dbo.f_distance_math(p1.zip_code,CAST(wv.[Zip Code] AS decimal)) AS distance
FROM (SELECT p0.first_name,p0.last_name,p0.email, z.zip_code 
		FROM dbo.Churchgoer p0
		JOIN dbo.Family f
		ON p0.family_id = f.family_id
		JOIN dbo.Zip_code z
		ON f.address_id = z.zip_id
		WHERE z.state_id = 7 --only results in CT
		AND p0.email IS NOT NULL
		AND f.address_ID IS NOT NULL) AS p1
CROSS JOIN dbo.WIC_Authorized_Vendors wv
WHERE dbo.f_distance_math(p1.zip_code,wv.[Zip Code]) < @miles
);
GO

--get result set for 5 mi
SELECT * FROM f_WICVendor_Person_Distance(5)
GO

*/
