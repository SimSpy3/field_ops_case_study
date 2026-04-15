DROP TABLE IF EXISTS stores;
CREATE TABLE stores (
  store_id                                            VARCHAR PRIMARY KEY,
  region                                              VARCHAR,
  city                                                VARCHAR,
  lat                                                 DOUBLE,
  lon                                                 DOUBLE,
  avg_daily_transactions                              INTEGER,
  terminal_count                                      INTEGER,
  terminal_age_years                                  DOUBLE,
  incident_tickets_90d                                INTEGER,  
  nearest_store_miles                                  DOUBLE
);

INSERT INTO stores VALUES
  ('STR001', 'Central OH',      'Columbus - Downtown',   39.9612, -82.9988, 8200, 4, 7.2, 23,  2.1),
  ('STR002', 'Central OH',      'Columbus - Easton',     40.0548, -82.9154, 6800, 3, 4.5, 11,  4.8),
  ('STR003', 'Northeast OH',    'Cleveland - Downtown',  41.4993, -81.6944, 7400, 5, 8.9, 31,  3.3),
  ('STR004', 'Northeast OH',    'Cleveland Heights',     41.5120, -81.5568, 3900, 2, 5.1, 14,  6.7),
  ('STR005', 'Southwest OH',    'Cincinnati - Downtown', 39.1031, -84.5120, 7100, 4, 9.3, 28,  2.8),
  ('STR006', 'Southwest OH',    'Cincinnati - Blue Ash', 39.2323, -84.3788, 4600, 2, 3.2,  8, 11.2),
  ('STR007', 'Northwest OH',    'Toledo',                41.6528, -83.5379, 3800, 3, 6.7, 19, 18.5),
  ('STR008', 'Northeast OH',    'Akron',                 41.0814, -81.5190, 4200, 3, 5.8, 17,  9.4),
  ('STR009', 'Southwest OH',    'Dayton',                39.7589, -84.1916, 5100, 3, 7.1, 22, 14.0),
  ('STR010', 'Northeast OH',    'Youngstown',            41.0998, -80.6495, 2600, 2,11.4, 38, 32.1),
  ('STR011', 'Northeast OH',    'Canton',                40.7989, -81.3784, 3100, 2, 8.2, 25, 22.6),
  ('STR012', 'North Central OH','Lorain',                41.4528, -82.1824, 2200, 2, 6.9, 16, 27.8),
  ('STR013', 'Southwest OH',    'Hamilton',              39.3995, -84.5613, 2900, 2, 4.8, 13, 19.3),
  ('STR014', 'Central OH',      'Springfield',           39.9242, -83.8088, 2500, 2, 9.6, 33, 24.4),
  ('STR015', 'Southwest OH',    'Kettering',             39.6895, -84.1688, 4400, 3, 3.9,  9, 12.7),
  ('STR016', 'North Central OH','Elyria',                41.3684, -82.1077, 2000, 2, 7.8, 21, 30.6),
  ('STR017', 'Northeast OH',    'Lakewood',              41.4820, -81.7982, 5400, 3, 6.3, 18,  5.9),
  ('STR018', 'North Central OH','Mansfield',             40.7584, -82.5154, 1800, 1,10.2, 29, 38.2),
  ('STR019', 'Northeast OH',    'Mentor',                41.6661, -81.3395, 3400, 2, 2.1,  6, 16.8),
  ('STR020', 'Northwest OH',    'Findlay',               41.0442, -83.6499, 1900, 1, 9.8, 27, 44.9);

  
  WITH bounds AS (
    SELECT
    MIN(avg_daily_transactions)             AS min_vol,
    MAX(avg_daily_transactions)             AS max_vol,
    MIN(terminal_age_years)                 AS min_age,
    MAX(terminal_age_years)                 AS max_age,
    MIN(incident_tickets_90d)               AS min_tickets,
    MAX(incident_tickets_90d)               AS max_tickets,
    MIN(nearest_store_miles)                AS min_miles,
    MAX(nearest_store_miles)                AS max_miles
  FROM stores
  ),

  normalized AS (
    SELECT
      s.store_id,
      s.region,
      s.city,
      s.lat,
      s.lon,
      s.avg_daily_transactions,
      s.terminal_count,
      s.incident_tickets_90d,
      s.nearest_store_miles,

      ROUND((s.avg_daily_transactions - b.min_vol)
          /  (b.max_vol - b.min_vol) * 100, 1) AS norm_vol,

      ROUND((s.terminal_age_years - b.min_age)
          /  (b.max_age - b.min_age) * 100, 1) AS norm_age,

      ROUND((s.incident_tickets_90d - b.min_tickets)
          /  (b.max_tickets - b.min_tickets) * 100, 1) AS norm_tickets,

      ROUND((1-(s.nearest_store_miles - b.min_miles)
          /  (b.max_miles - b.min_miles)) * 100, 1) AS proximity_score
  FROM stores s
  CROSS JOIN bounds b
  )

,

scored AS (
  SELECT
    store_id,                                                             
    region, 
    city,
    lat,
    lon,
    avg_daily_transactions,
    terminal_count,                                                       
    incident_tickets_90d,
    nearest_store_miles,                                                  
    norm_vol,
    norm_age,                                                             
    norm_tickets,
    proximity_score, 

    ROUND (
      (norm_vol    *0.40) +
      (norm_tickets * 0.35) + 
      (proximity_score * 0.25), 
    2) AS priority_score
    FROM normalized
)
SELECT * FROM scored
ORDER BY priority_score DESC;