/************************************************************************
Copyright 2020 Observational Health Data Sciences and Informatics

This file is part of Covid19HcqSccs

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
************************************************************************/
{DEFAULT @cdm_database_schema = "CDM_JMDC_V1106.dbo"}
{DEFAULT @cohort_database_schema = "scratch.dbo"}
{DEFAULT @cohort_table = "mschuemi_covid19sccs_jmdc"}
{DEFAULT @exposure_id = 85}
{DEFAULT @outcome_id = 7382}
{DEFAULT @washout_days = 365}

IF OBJECT_ID('tempdb..#study_period', 'U') IS NOT NULL
  DROP TABLE #study_period;
  
  IF OBJECT_ID('tempdb..#at_risk_cohort', 'U') IS NOT NULL
  DROP TABLE #at_risk_cohort;

SELECT cohort_definition_id AS outcome_id,
	person_id,
	DATEADD(DAY, @washout_days, observation_period_start_date) AS study_period_start_date,
	observation_period_end_date AS study_period_end_date
INTO #study_period
FROM @cohort_database_schema.@cohort_table
INNER JOIN @cdm_database_schema.observation_period
	ON subject_id = person_id
		AND DATEADD(DAY, @washout_days, observation_period_start_date) <= cohort_end_date
		AND observation_period_end_date >= cohort_start_date
WHERE cohort_definition_id = @outcome_id;
		
SELECT subject_id,
	cohort_definition_id,
	cohort_start_date,
	cohort_end_date
INTO #at_risk_cohort
FROM (
	SELECT subject_id,
		cohort_definition_id,
		CASE 
			WHEN cohort_start_date < study_period_start_date
				THEN study_period_start_date
			ELSE cohort_start_date
			END AS cohort_start_date,
		cohort_end_date,
		ROW_NUMBER() OVER (
			PARTITION BY subject_id ORDER BY cohort_start_date
			) AS rn
	FROM @cohort_database_schema.@cohort_table
	INNER JOIN #study_period
		ON subject_id = person_id
			AND study_period_start_date <= cohort_end_date
			AND study_period_end_date >= cohort_start_date
	WHERE cohort_definition_id = @exposure_id
	) exposure_start
WHERE rn = 1;

TRUNCATE TABLE #study_period;

DROP TABLE #study_period;


