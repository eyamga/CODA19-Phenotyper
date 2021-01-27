-- In this version labs for the first 24 hours of the patient's admission

WITH vitals_sample AS (
-- In this script we are taking into consideration the ENTIRE COVID EPISODE AS ONE
WITH covidepisodes AS (
WITH mergedepisodes AS (
WITH episodes AS (
				SELECT
					episode_admission_uid,
					patient_site_uid,
					episode_start_time,
					episode_end_time,
					SUM(flag) OVER (PARTITION BY patient_site_uid ORDER BY episode_start_time) stayid
				FROM (
				SELECT
					*,
					strftime ('%s',
					episode_start_time) - strftime ('%s',
				LAG(episode_end_time,
				1,
				datetime (episode_start_time,
				'-1 hour')) OVER (PARTITION BY patient_site_uid ORDER BY episode_start_time)) > 12 * 3600 flag -- 12 hours delay considered as same single episode
		FROM
			episode_data))
SELECT
	patient_site_uid,
	min(episode_start_time) episode_start_time,
	max(episode_end_time) episode_end_time,
	stayid
FROM
	episodes
GROUP BY
	patient_site_uid,
	stayid
)
SELECT
	mergedepisodes.patient_site_uid,
	mergedepisodes.episode_start_time,
	mergedepisodes.episode_end_time
FROM
	mergedepisodes
	INNER JOIN patient_data ON mergedepisodes.patient_site_uid = patient_data.patient_site_uid
WHERE
	datetime (patient_data.pcr_sample_time) BETWEEN datetime (mergedepisodes.episode_start_time,
'-7 day') -- we consider a covid episode when positive test was done in the 7 days preceding the admission
	AND datetime (mergedepisodes.episode_end_time)
AND patient_data.patient_covid_status = 'positive'
)
SELECT
	covidepisodes.patient_site_uid,
	covidepisodes.episode_start_time,
	covidepisodes.episode_end_time,
	observation_name,
	observation_time,
	observation_value
FROM
	covidepisodes
	INNER JOIN observation_DATA ON covidepisodes.patient_site_uid = observation_data.patient_site_uid
	-- Can modulate time here to make sure the lab occured at a specific time from the onset of hospitalization i.e. first 24 hours
WHERE
	datetime (observation_time) BETWEEN datetime (covidepisodes.episode_start_time, '-25 hour') AND datetime (covidepisodes.episode_start_time, '+48 hour')
	
)
SELECT
	patient_site_uid,
	-- weight
	min( CASE WHEN observation_name = 'weight' THEN
		observation_value
	ELSE
		NULL
	END) AS weight_min, max(
		CASE WHEN observation_name = 'weight' THEN
			observation_value
		ELSE
			NULL
		END) AS weight_max, round(avg(
			CASE WHEN observation_name = 'weight' THEN
				observation_value
			ELSE
				NULL
			END), 2) AS weight_mean,
	-- systolic_blood_pressure
	min( CASE WHEN observation_name = 'systolic_blood_pressure' THEN
		observation_value
	ELSE
		NULL
	END) AS sbp_min, max(
		CASE WHEN observation_name = 'systolic_blood_pressure' THEN
			observation_value
		ELSE
			NULL
		END) AS sbp_max, round(avg(
			CASE WHEN observation_name = 'systolic_blood_pressure' THEN
				observation_value
			ELSE
				NULL
			END), 2) AS sbp_mean,
	-- weight
	min( CASE WHEN observation_name = 'diastolic_blood_pressure' THEN
		observation_value
	ELSE
		NULL
	END) AS dbp_min, max(
		CASE WHEN observation_name = 'diastolic_blood_pressure' THEN
			observation_value
		ELSE
			NULL
		END) AS dbp_max, round(avg(
			CASE WHEN observation_name = 'diastolic_blood_pressure' THEN
				observation_value
			ELSE
				NULL
			END), 2) AS dbp_mean,
	-- temperature
	min( CASE WHEN observation_name = 'temperature' THEN
		observation_value
	ELSE
		NULL
	END) AS temp_min, max(
		CASE WHEN observation_name = 'temperature' THEN
			observation_value
		ELSE
			NULL
		END) AS temp_max, round(avg(
			CASE WHEN observation_name = 'temperature' THEN
				observation_value
			ELSE
				NULL
			END), 2) AS temp_mean,
	-- so2
	min( CASE WHEN observation_name = 'oxygen_saturation' THEN
		observation_value
	ELSE
		NULL
	END) AS so2_min, max(
		CASE WHEN observation_name = 'oxygen_saturation' THEN
			observation_value
		ELSE
			NULL
		END) AS so2_max, round(avg(
			CASE WHEN observation_name = 'oxygen_saturation' THEN
				observation_value
			ELSE
				NULL
			END), 2) AS so2_mean,
	-- respiratory_rate
	min( CASE WHEN observation_name = 'respiratory_rate' THEN
		observation_value
	ELSE
		NULL
	END) AS rr_min, max(
		CASE WHEN observation_name = 'respiratory_rate' THEN
			observation_value
		ELSE
			NULL
		END) AS rr_max, round(avg(
			CASE WHEN observation_name = 'respiratory_rate' THEN
				observation_value
			ELSE
				NULL
			END), 2) AS rr_mean,
	-- oxygen flow
	min( CASE WHEN observation_name = 'oxygen_flow_rate' THEN
		observation_value
	ELSE
		NULL
	END) AS flow_min, max(
		CASE WHEN observation_name = 'oxygen_flow_rate' THEN
			observation_value
		ELSE
			NULL
		END) AS flow_max, round(avg(
			CASE WHEN observation_name = 'oxygen_flow_rate' THEN
				observation_value
			ELSE
				NULL
			END), 2) AS flow_mean,
	-- fi02
	min( CASE WHEN observation_name = 'fraction_inspired_oxygen' THEN
		observation_value
	ELSE
		NULL
	END) AS fio2_min, max(
		CASE WHEN observation_name = 'fraction_inspired_oxygen' THEN
			observation_value
		ELSE
			NULL
		END) AS fio2_max, round(avg(
			CASE WHEN observation_name = 'fraction_inspired_oxygen' THEN
				observation_value
			ELSE
				NULL
			END), 2) AS fio2_mean
FROM
	vitals_sample
GROUP BY
	patient_site_uid