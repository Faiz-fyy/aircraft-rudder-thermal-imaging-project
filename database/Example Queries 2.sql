-- INSPECTION ANALYSIS
-- Detection Success
WITH inspection_analysis AS (
    SELECT 
        ti.Inspection_ID,
        COUNT(tim.File_ID) AS Images_Per_Inspection,
        MAX(tim.Has_Water) AS Water_Detected
    FROM thermal_inspections AS ti
    JOIN thermal_images tim ON ti.Inspection_ID = tim.Inspection_ID
    GROUP BY ti.Inspection_ID
)
SELECT 
    Images_Per_Inspection,
    COUNT(*) AS Inspection_Count,
    SUM(Water_Detected) AS Water_Detected_Count,
    ROUND(SUM(Water_Detected) * 100.0 / COUNT(*), 1) AS Detection_Success_Rate_Percent
FROM inspection_analysis
WHERE Images_Per_Inspection IN (1,2,3,4,5,8,9,18)
GROUP BY Images_Per_Inspection
ORDER BY Images_Per_Inspection;

-- Targeted vs Systematic Approach
SELECT 
    CASE WHEN img_counts.img_count = 1 THEN 'TARGETED' ELSE 'SYSTEMATIC' END AS Approach,
    COUNT(*) AS Inspection_Count,
    SUM(img_counts.img_count) AS Total_Images,
    ROUND(AVG(img_counts.img_count), 1) AS Avg_Images_Per_Inspection,
    COUNT(CASE WHEN water_status.has_water = 1 THEN 1 END) AS Water_Detected_Count,
    ROUND(COUNT(CASE WHEN water_status.has_water = 1 THEN 1 END) * 100.0 / COUNT(*), 1) AS Detection_Rate_Percent
FROM (
    SELECT Inspection_ID, COUNT(*) AS img_count 
    FROM thermal_images 
    GROUP BY Inspection_ID
) img_counts
JOIN (
    SELECT Inspection_ID, MAX(Has_Water) AS has_water 
    FROM thermal_images 
    GROUP BY Inspection_ID
) water_status ON img_counts.Inspection_ID = water_status.Inspection_ID
GROUP BY CASE WHEN img_counts.img_count = 1 THEN 'TARGETED' ELSE 'SYSTEMATIC' END;

-- DATA VALIDATION --
-- Palette Correction
SELECT 
    es.Palette_Type,
    COUNT(*) AS Image_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM thermal_images), 1) AS Percentage,
    COUNT(DISTINCT tim.Inspection_ID) AS Inspections_Affected
FROM thermal_images AS tim
JOIN equipment_settings AS es ON tim.Equipment_ID = es.Equipment_ID
GROUP BY es.Palette_Type
ORDER BY Image_Count DESC;

-- Class Balance Analysis
SELECT 
    CASE WHEN tim.Has_Water = 1 THEN 'Water' ELSE 'NWI' END AS Class,
    COUNT(*) AS Image_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM thermal_images), 1) AS Percentage
FROM thermal_images tim
GROUP BY tim.Has_Water;

-- HUMIDITY ANALYSIS --
SELECT 
    CASE 
        WHEN ec.Relative_Humidity >= 45 THEN 'High Humidity (45+)'
        WHEN ec.Relative_Humidity >= 35 THEN 'Medium Humidity (35-44)'
        ELSE 'Low Humidity (<35)'
    END AS Humidity_Level,
    ti.Season,
    COUNT(*) AS Image_Count,
    ROUND(AVG(CASE WHEN tim.Has_Water = 1 THEN 1.0 ELSE 0.0 END) * 100, 1) AS Water_Detection_Rate_Percent
FROM thermal_images AS tim
JOIN thermal_inspections AS ti ON tim.Inspection_ID = ti.Inspection_ID
JOIN environmental_conditions AS ec ON tim.Env_ID = ec.Env_ID
GROUP BY 
    CASE 
        WHEN ec.Relative_Humidity >= 45 THEN 'High Humidity (45+)'
        WHEN ec.Relative_Humidity >= 35 THEN 'Medium Humidity (35-44)'
        ELSE 'Low Humidity (<35)'
    END,
    ti.Season
ORDER BY ti.Season, MIN(ec.Relative_Humidity);
