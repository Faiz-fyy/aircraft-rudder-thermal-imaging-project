-- SUMMARY --
-- KPI
SELECT 
    COUNT(DISTINCT ti.Inspection_ID) AS Total_Inspections,
    MAX(ti.Relative_Days) AS Inspection_Period_Days,
    ROUND(COUNT(CASE WHEN tim.Has_Water = 1 THEN 1 END) * 100.0 / COUNT(*), 1) AS Water_Detection_Rate_Percent,
    ROUND(AVG(images_per_inspection.img_count), 1) AS Avg_Images_Per_Inspection,
    ROUND(COUNT(CASE WHEN es.Palette_Type = 'WHITE HOT' THEN 1 END) * 100.0 / COUNT(*), 1) AS Data_Quality_Percentt
FROM thermal_inspections AS ti
JOIN thermal_images AS tim ON ti.Inspection_ID = tim.Inspection_ID
JOIN equipment_settings AS es ON tim.Equipment_ID = es.Equipment_ID
JOIN (
    SELECT Inspection_ID, COUNT(*) AS img_count 
    FROM thermal_images 
    GROUP BY Inspection_ID
) images_per_inspection ON ti.Inspection_ID = images_per_inspection.Inspection_ID;

-- Inspection Summary by ID
SELECT 
    ti.Inspection_ID,
    ti.Season,
    ti.Relative_Days,
    COUNT(tim.File_ID) AS Total_Images,
    COUNT(CASE WHEN tim.Has_Water = 1 THEN 1 END) AS Water_Images,
    ROUND(AVG(CASE WHEN tim.Has_Water = 1 THEN 1.0 ELSE 0.0 END) * 100, 1) AS Water_Rate_Percent,
    CASE WHEN COUNT(tim.File_ID) = 1 THEN 'TARGETED' ELSE 'SYSTEMATIC' END AS Inspection_Strategy
FROM thermal_inspections AS ti
JOIN thermal_images AS tim ON ti.Inspection_ID = tim.Inspection_ID
GROUP BY ti.Inspection_ID, ti.Season, ti.Relative_Days
ORDER BY ti.Relative_Days;

-- SEASONAL ANALYSIS --
-- Seasonal Detection Rates
SELECT 
    ti.Season,
    COUNT(DISTINCT ti.Inspection_ID) AS Inspection_Count,
    COUNT(tim.File_ID) AS Total_Images,
    COUNT(CASE WHEN tim.Has_Water = 1 THEN 1 END) AS Water_Images,
    ROUND(AVG(CASE WHEN tim.Has_Water = 1 THEN 1.0 ELSE 0.0 END) * 100, 1) AS Water_Detection_Rate_Percent,
    AVG(ec.Relative_Humidity) AS Avg_Humidity,
    AVG(ec.Atmos_Temp) AS Avg_Atmos_Temp
FROM thermal_inspections AS ti
JOIN thermal_images AS tim ON ti.Inspection_ID = tim.Inspection_ID
JOIN environmental_conditions AS ec ON tim.Env_ID = ec.Env_ID
GROUP BY ti.Season
ORDER BY Water_Detection_Rate_Percent DESC;

-- THERMAL ANALYSIS --
-- Temperature Distribution by Water Status
SELECT 
    tim.Has_Water,
    COUNT(*) AS Image_Count,
    MIN(tim.Point_Temp) AS Min_Point_Temp,
    ROUND(AVG(tim.Point_Temp), 2) AS Avg_Point_Temp,
    MAX(tim.Point_Temp) AS Max_Point_Temp,
    MIN(tim.Thermal_Range) AS Min_Thermal_Range,
    ROUND(AVG(tim.Thermal_Range), 2) AS Avg_Thermal_Range,
    MAX(tim.Thermal_Range) AS Max_Thermal_Range,
    ROUND(AVG(tim.Thermal_Gradient), 3) AS Avg_Thermal_Gradient,
    ROUND(AVG(tim.Temp_Contrast), 3) AS Avg_Temp_Contrast
FROM thermal_images AS tim
GROUP BY tim.Has_Water;

-- Zero Gradient Cases
SELECT 
    tim.File_ID,
    tim.Inspection_ID,
    tim.Point_Temp,
    tim.Min_Temp,
    tim.Max_Temp,
    tim.Thermal_Range,
    tim.Thermal_Gradient,
    tim.Has_Water,
    ti.Season
FROM thermal_images AS tim
JOIN thermal_inspections AS ti ON tim.Inspection_ID = ti.Inspection_ID
WHERE tim.Thermal_Gradient = 0
ORDER BY tim.Inspection_ID;