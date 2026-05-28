-- ============================================================
-- ReadmitGuard Analytics
-- Advanced SQL Queries — Showcase Findings
-- MySQL (AWS RDS Compatible)
-- Data Analytics Capstone 2026
-- ============================================================
-- NOTE: All queries run against the flat diabetic_data table
-- since that is where your live data lives.
-- Each query maps directly to a finding from your EDA.
-- ============================================================


-- ============================================================
-- QUERY 1: Readmission Distribution
-- Replicates your #1 EDA finding
-- Shows the 53.9 / 34.9 / 11.2 breakdown with exact counts
-- ============================================================
SELECT
    readmitted                                          AS readmission_status,
    COUNT(*)                                            AS patient_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)  AS percentage,
    CASE readmitted
        WHEN '<30' THEN 'HIGH RISK — readmitted within 30 days'
        WHEN '>30' THEN 'Readmitted after 30 days'
        WHEN 'NO'  THEN 'Not readmitted'
    END                                                 AS description
FROM diabetic_data
GROUP BY readmitted
ORDER BY
    CASE readmitted
        WHEN '<30' THEN 1
        WHEN '>30' THEN 2
        WHEN 'NO'  THEN 3
    END;


-- ============================================================
-- QUERY 2: High-Risk Rate by Age Group
-- Replicates your age line chart — shows 80-90 is highest risk
-- ============================================================
SELECT
    age                                                         AS age_group,
    COUNT(*)                                                    AS total_patients,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct
FROM diabetic_data
GROUP BY age
ORDER BY
    CASE age
        WHEN '[0-10)'   THEN 1
        WHEN '[10-20)'  THEN 2
        WHEN '[20-30)'  THEN 3
        WHEN '[30-40)'  THEN 4
        WHEN '[40-50)'  THEN 5
        WHEN '[50-60)'  THEN 6
        WHEN '[60-70)'  THEN 7
        WHEN '[70-80)'  THEN 8
        WHEN '[80-90)'  THEN 9
        WHEN '[90-100)' THEN 10
    END;


-- ============================================================
-- QUERY 3: Medication Change Impact on Readmission
-- Shows the 46.2% medication change finding and its effect
-- ============================================================
SELECT
    CASE `change`
        WHEN 'Ch' THEN 'Medication Changed'
        WHEN 'No' THEN 'No Medication Change'
    END                                                         AS medication_change,
    COUNT(*)                                                    AS total_patients,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)           AS pct_of_all_patients
FROM diabetic_data
WHERE `change` IS NOT NULL
GROUP BY `change`
ORDER BY high_risk_pct DESC;


-- ============================================================
-- QUERY 4: Prior Inpatient Visits — The 3.7x Risk Multiplier
-- Your strongest EDA finding — shows escalating risk
-- ============================================================
SELECT
    CASE
        WHEN number_inpatient = 0              THEN '0 prior visits'
        WHEN number_inpatient = 1              THEN '1 prior visit'
        WHEN number_inpatient BETWEEN 2 AND 3  THEN '2-3 prior visits'
        WHEN number_inpatient >= 4             THEN '4+ prior visits'
    END                                                         AS inpatient_history,
    COUNT(*)                                                    AS total_patients,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)           AS pct_of_dataset
FROM diabetic_data
GROUP BY
    CASE
        WHEN number_inpatient = 0              THEN '0 prior visits'
        WHEN number_inpatient = 1              THEN '1 prior visit'
        WHEN number_inpatient BETWEEN 2 AND 3  THEN '2-3 prior visits'
        WHEN number_inpatient >= 4             THEN '4+ prior visits'
    END
ORDER BY high_risk_pct DESC;


-- ============================================================
-- QUERY 5: Race Distribution with Readmission Rates
-- Shows demographic breakdown + bias flag
-- ============================================================
SELECT
    COALESCE(race, 'Unknown')                                   AS race,
    COUNT(*)                                                    AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)           AS pct_of_dataset,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct
FROM diabetic_data
GROUP BY race
ORDER BY total_patients DESC;


-- ============================================================
-- QUERY 6: Top 5 Prescribed Medications
-- Shows insulin dominance and medication complexity
-- ============================================================
SELECT medication_name, prescribed_count,
    ROUND(prescribed_count * 100.0 / total.total_encounters, 1) AS pct_of_encounters
FROM (
    SELECT 'Insulin'      AS medication_name,
        SUM(CASE WHEN insulin      != 'No' THEN 1 ELSE 0 END) AS prescribed_count FROM diabetic_data
    UNION ALL
    SELECT 'Metformin',
        SUM(CASE WHEN metformin    != 'No' THEN 1 ELSE 0 END) FROM diabetic_data
    UNION ALL
    SELECT 'Glipizide',
        SUM(CASE WHEN glipizide    != 'No' THEN 1 ELSE 0 END) FROM diabetic_data
    UNION ALL
    SELECT 'Glyburide',
        SUM(CASE WHEN glyburide    != 'No' THEN 1 ELSE 0 END) FROM diabetic_data
    UNION ALL
    SELECT 'Glimepiride',
        SUM(CASE WHEN glimepiride  != 'No' THEN 1 ELSE 0 END) FROM diabetic_data
    UNION ALL
    SELECT 'Pioglitazone',
        SUM(CASE WHEN pioglitazone != 'No' THEN 1 ELSE 0 END) FROM diabetic_data
    UNION ALL
    SELECT 'Metformin-Rosiglitazone',
        SUM(CASE WHEN `metformin-rosiglitazone` != 'No' THEN 1 ELSE 0 END) FROM diabetic_data
) AS meds
CROSS JOIN (SELECT COUNT(*) AS total_encounters FROM diabetic_data) AS total
ORDER BY prescribed_count DESC;


-- ============================================================
-- QUERY 7: Descriptive Statistics for Key Numerical Features
-- Replicates your notebook describe() output in pure SQL
-- ============================================================
SELECT
    'num_medications'       AS feature,
    ROUND(AVG(num_medications), 2)                          AS mean_val,
    ROUND(STDDEV(num_medications), 2)                       AS std_dev,
    MIN(num_medications)                                    AS min_val,
    MAX(num_medications)                                    AS max_val,
    ROUND(AVG(num_medications) - MIN(num_medications), 2)   AS range_val
FROM diabetic_data WHERE num_medications IS NOT NULL
UNION ALL
SELECT
    'num_lab_procedures',
    ROUND(AVG(num_lab_procedures), 2),
    ROUND(STDDEV(num_lab_procedures), 2),
    MIN(num_lab_procedures),
    MAX(num_lab_procedures),
    ROUND(AVG(num_lab_procedures) - MIN(num_lab_procedures), 2)
FROM diabetic_data
UNION ALL
SELECT
    'time_in_hospital',
    ROUND(AVG(time_in_hospital), 2),
    ROUND(STDDEV(time_in_hospital), 2),
    MIN(time_in_hospital),
    MAX(time_in_hospital),
    ROUND(AVG(time_in_hospital) - MIN(time_in_hospital), 2)
FROM diabetic_data
UNION ALL
SELECT
    'number_inpatient',
    ROUND(AVG(number_inpatient), 2),
    ROUND(STDDEV(number_inpatient), 2),
    MIN(number_inpatient),
    MAX(number_inpatient),
    ROUND(AVG(number_inpatient) - MIN(number_inpatient), 2)
FROM diabetic_data WHERE number_inpatient IS NOT NULL
UNION ALL
SELECT
    'number_diagnoses',
    ROUND(AVG(number_diagnoses), 2),
    ROUND(STDDEV(number_diagnoses), 2),
    MIN(number_diagnoses),
    MAX(number_diagnoses),
    ROUND(AVG(number_diagnoses) - MIN(number_diagnoses), 2)
FROM diabetic_data WHERE number_diagnoses IS NOT NULL;


-- ============================================================
-- QUERY 8: High-Risk Patient Profile
-- Compares avg clinical stats: high risk vs not high risk
-- Validates the hypothesis directly in SQL
-- ============================================================
SELECT
    CASE WHEN readmitted = '<30' THEN 'HIGH RISK' ELSE 'Not High Risk' END  AS patient_group,
    COUNT(*)                                                                AS patient_count,
    ROUND(AVG(num_medications), 2)                                          AS avg_medications,
    ROUND(AVG(num_lab_procedures), 2)                                       AS avg_lab_procedures,
    ROUND(AVG(time_in_hospital), 2)                                         AS avg_days_in_hospital,
    ROUND(AVG(number_inpatient), 2)                                         AS avg_prior_inpatient,
    ROUND(AVG(number_diagnoses), 2)                                         AS avg_diagnoses
FROM diabetic_data
GROUP BY
    CASE WHEN readmitted = '<30' THEN 'HIGH RISK' ELSE 'Not High Risk' END
ORDER BY patient_group;


-- ============================================================
-- QUERY 9: Primary Diagnosis Category Distribution
-- Replicates your ICD-9 category bar chart in SQL
-- ============================================================
SELECT
    CASE
        WHEN diag_1 REGEXP '^[0-9]' AND CAST(diag_1 AS DECIMAL) BETWEEN 390 AND 459
            THEN 'Circulatory'
        WHEN diag_1 REGEXP '^[0-9]' AND CAST(diag_1 AS DECIMAL) BETWEEN 460 AND 519
            THEN 'Respiratory'
        WHEN diag_1 REGEXP '^[0-9]' AND CAST(diag_1 AS DECIMAL) BETWEEN 520 AND 579
            THEN 'Digestive'
        WHEN diag_1 REGEXP '^[0-9]' AND CAST(diag_1 AS DECIMAL) BETWEEN 250 AND 250.99
            THEN 'Diabetes'
        WHEN diag_1 REGEXP '^[0-9]' AND CAST(diag_1 AS DECIMAL) BETWEEN 800 AND 999
            THEN 'Injury / Poisoning'
        WHEN diag_1 REGEXP '^[0-9]' AND CAST(diag_1 AS DECIMAL) BETWEEN 710 AND 739
            THEN 'Musculoskeletal'
        WHEN diag_1 REGEXP '^[0-9]' AND CAST(diag_1 AS DECIMAL) BETWEEN 580 AND 629
            THEN 'Genitourinary'
        WHEN diag_1 REGEXP '^[0-9]' AND CAST(diag_1 AS DECIMAL) BETWEEN 140 AND 239
            THEN 'Neoplasms'
        WHEN diag_1 LIKE 'V%' OR diag_1 LIKE 'E%'
            THEN 'External / Supplemental'
        ELSE 'Other'
    END                                                         AS diagnosis_category,
    COUNT(*)                                                    AS encounter_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2)           AS pct_of_total,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct
FROM diabetic_data
WHERE diag_1 IS NOT NULL AND diag_1 != '?'
GROUP BY 1
ORDER BY encounter_count DESC;


-- ============================================================
-- QUERY 10: Admission Type vs Readmission Rate
-- Shows emergency admissions have higher readmission rates
-- ============================================================
SELECT
    CASE admission_type_id
        WHEN 1 THEN 'Emergency'
        WHEN 2 THEN 'Urgent'
        WHEN 3 THEN 'Elective'
        WHEN 4 THEN 'Newborn'
        ELSE 'Other / Unknown'
    END                                                         AS admission_type,
    COUNT(*)                                                    AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)           AS pct_of_total,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct
FROM diabetic_data
GROUP BY admission_type_id
ORDER BY total_patients DESC;


-- ============================================================
-- QUERY 11: Financial Impact Estimate
-- Puts a dollar figure on the high-risk patients
-- Based on $15,000 avg cost per readmission (AHRQ)
-- ============================================================
SELECT
    COUNT(*)                                                    AS total_encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 15000                                                 AS estimated_cost_usd,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 15000 * 0.20
    )                                                           AS savings_at_20pct_prevention,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 15000 * 0.30
    )                                                           AS savings_at_30pct_prevention
FROM diabetic_data;


-- ============================================================
-- QUERY 12: Missing Value Audit
-- Replicates your data cleaning analysis in SQL
-- Shows exactly what you found and why you excluded columns
-- ============================================================
SELECT
    'weight'            AS column_name,
    COUNT(*)            AS total_rows,
    SUM(CASE WHEN weight = '?' OR weight IS NULL THEN 1 ELSE 0 END)
                        AS missing_count,
    ROUND(
        SUM(CASE WHEN weight = '?' OR weight IS NULL THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                   AS missing_pct,
    'Excluded'          AS action_taken
FROM diabetic_data
UNION ALL
SELECT
    'payer_code',
    COUNT(*),
    SUM(CASE WHEN payer_code = '?' OR payer_code IS NULL THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN payer_code = '?' OR payer_code IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    'Excluded'
FROM diabetic_data
UNION ALL
SELECT
    'medical_specialty',
    COUNT(*),
    SUM(CASE WHEN medical_specialty = '?' OR medical_specialty IS NULL THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN medical_specialty = '?' OR medical_specialty IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    'Retained as NaN'
FROM diabetic_data
UNION ALL
SELECT
    'race',
    COUNT(*),
    SUM(CASE WHEN race = '?' OR race IS NULL THEN 1 ELSE 0 END),
    ROUND(SUM(CASE WHEN race = '?' OR race IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2),
    'Rows dropped'
FROM diabetic_data
ORDER BY missing_pct DESC;


-- ============================================================
-- QUERY 13: Gender Breakdown with Readmission Rates
-- Confirms near-identical rates (11.24% F vs 11.06% M)
-- ============================================================
SELECT
    gender,
    COUNT(*)                                                    AS total_patients,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1)           AS pct_of_total,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct
FROM diabetic_data
WHERE gender NOT IN ('Unknown/Invalid')
GROUP BY gender
ORDER BY total_patients DESC;


-- ============================================================
-- QUERY 14: Time in Hospital vs Readmission Risk
-- Buckets hospital stay length and shows risk by duration
-- ============================================================
SELECT
    CASE
        WHEN time_in_hospital BETWEEN 1 AND 2  THEN '1-2 days (short)'
        WHEN time_in_hospital BETWEEN 3 AND 5  THEN '3-5 days (average)'
        WHEN time_in_hospital BETWEEN 6 AND 9  THEN '6-9 days (extended)'
        WHEN time_in_hospital >= 10            THEN '10+ days (long)'
    END                                                         AS stay_length,
    COUNT(*)                                                    AS total_patients,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)         AS high_risk_count,
    ROUND(
        SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*), 2
    )                                                           AS high_risk_pct
FROM diabetic_data
GROUP BY 1
ORDER BY high_risk_pct DESC;


-- ============================================================
-- QUERY 15: Executive Summary — All Key Stats in One Query
-- Great for presenting — shows everything at a glance
-- ============================================================
SELECT 'Total patient encounters'          AS metric, COUNT(*)                                                                          AS value FROM diabetic_data
UNION ALL
SELECT 'High risk patients (<30 days)',     CAST(SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END) AS CHAR)                           FROM diabetic_data
UNION ALL
SELECT 'High risk rate (%)',               CAST(ROUND(SUM(CASE WHEN readmitted='<30' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS CHAR)      FROM diabetic_data
UNION ALL
SELECT 'Avg medications per patient',      CAST(ROUND(AVG(num_medications),2) AS CHAR)                                                  FROM diabetic_data
UNION ALL
SELECT 'Avg lab procedures per visit',     CAST(ROUND(AVG(num_lab_procedures),2) AS CHAR)                                               FROM diabetic_data
UNION ALL
SELECT 'Avg days in hospital',             CAST(ROUND(AVG(time_in_hospital),2) AS CHAR)                                                 FROM diabetic_data
UNION ALL
SELECT 'Avg diagnoses (comorbidities)',    CAST(ROUND(AVG(number_diagnoses),2) AS CHAR)                                                 FROM diabetic_data WHERE number_diagnoses IS NOT NULL
UNION ALL
SELECT 'Patients with medication change',  CAST(SUM(CASE WHEN `change`='Ch' THEN 1 ELSE 0 END) AS CHAR)                                FROM diabetic_data
UNION ALL
SELECT 'Medication change rate (%)',       CAST(ROUND(SUM(CASE WHEN `change`='Ch' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS CHAR)        FROM diabetic_data
UNION ALL
SELECT 'Estimated readmission cost ($)',   CAST(SUM(CASE WHEN readmitted='<30' THEN 15000 ELSE 0 END) AS CHAR)                         FROM diabetic_data;

-- ============================================================
-- END OF QUERIES
-- ============================================================