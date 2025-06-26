CREATE TABLE thermal_inspections (
    Inspection_ID VARCHAR(10) PRIMARY KEY,
    Relative_Days INT,
    Relative_Months INT,
    Relative_Quarters INT,
    Relative_Years INT,
    Season VARCHAR(5) -- SW = South West Monsoon, NE = North East Monsoon
);

CREATE TABLE environmental_conditions (
    Env_ID VARCHAR(10) PRIMARY KEY,
    Relative_Humidity INT,
    Atmos_Temp DOUBLE
);

CREATE TABLE equipment_settings (
    Equipment_ID VARCHAR(10) PRIMARY KEY,
    Emissivity DOUBLE,
    Reflected_Temp DOUBLE,
    Distance DOUBLE,
    Zoom DOUBLE,
    Palette_Type VARCHAR(10) -- WHITE HOT, BLACK HOT
);

CREATE TABLE thermal_images (
    File_ID VARCHAR(10) PRIMARY KEY,
    Inspection_ID VARCHAR(10),
    Env_ID VARCHAR(10),
    Equipment_ID VARCHAR(10),
    Point_Temp DOUBLE,
    Min_Temp DOUBLE,
    Max_Temp DOUBLE,
    Has_Water BOOLEAN,
    
    -- Thermal Features
    Thermal_Range DOUBLE GENERATED ALWAYS AS (Max_Temp - Min_Temp) STORED,
    Thermal_Gradient DOUBLE GENERATED ALWAYS AS 
        (CASE WHEN (Max_Temp - Min_Temp) = 0 THEN 0 
         ELSE (Point_Temp - Min_Temp) / (Max_Temp - Min_Temp) END) STORED,
    Temp_Contrast DOUBLE GENERATED ALWAYS AS 
        (CASE WHEN Point_Temp = 0 THEN 0 
         ELSE (Max_Temp - Min_Temp) / Point_Temp END) STORED,
    
    FOREIGN KEY (Inspection_ID) REFERENCES thermal_inspections(Inspection_ID),
    FOREIGN KEY (Env_ID) REFERENCES environmental_conditions(Env_ID),
    FOREIGN KEY (Equipment_ID) REFERENCES equipment_settings(Equipment_ID)
); 

-- Inspection Strategy View
CREATE VIEW inspection_analysis AS
SELECT 
    ti.Inspection_ID,
    ti.Season,
    COUNT(tim.File_ID) AS Total_Images,
    CASE WHEN COUNT(tim.File_ID) = 1 THEN 'TARGETED' ELSE 'SYSTEMATIC' END AS Inspection_Strategy,
    MAX(tim.Has_Water) AS Water_Detected,
    AVG(tim.Thermal_Range) AS Avg_Thermal_Range
FROM thermal_inspections AS ti
JOIN thermal_images tim ON ti.Inspection_ID = tim.Inspection_ID
GROUP BY ti.Inspection_ID, ti.Season;

-- Environmental Risk View
CREATE VIEW environmental_risk AS
SELECT 
    ec.*,
    ti.Season,
    CASE 
        WHEN ec.Relative_Humidity > 40 AND ti.Season = 'SW' THEN 'HIGH'
        WHEN ec.Relative_Humidity > 30 AND ti.Season = 'NE' THEN 'MEDIUM'
        ELSE 'LOW'
    END as Environmental_Risk_Score
FROM environmental_conditions AS ec
JOIN thermal_images AS tim ON ec.Env_ID = tim.Env_ID
JOIN thermal_inspections AS ti ON tim.Inspection_ID = ti.Inspection_ID;