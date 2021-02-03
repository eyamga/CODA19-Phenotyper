-- In this version labs for the first 24 hours of the patient's admission

WITH vitals_sample AS (
-- In this script we are taking into consideration the ENTIRE COVID EPISODE AS ONE
SELECT
	icu_episodes.patient_site_uid,
	icu_episodes.episode_start_time,
	icu_episodes.episode_end_time,
	observation_name,
	observation_time,
	observation_value
FROM
	icu_episodes
	INNER JOIN observation_data ON icu_episodes.patient_site_uid = observation_data.patient_site_uid
	-- Can modulate time here to make sure the lab occured at a specific time from the onset of hospitalization i.e. first 24 hours
WHERE
	datetime (observation_data.observation_time) BETWEEN datetime (icu_episodes.episode_start_time, '-25 hour') AND datetime (icu_episodes.episode_start_time, '+25 hour')
	
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