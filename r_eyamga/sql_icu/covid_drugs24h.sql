WITH drugs_sample AS (
	-- In this script we are taking into consideration the ENTIRE COVID EPISODE AS ONE WITH covidepisodes AS (
SELECT
	icu_episodes.patient_site_uid,
	icu_episodes.episode_start_time,
	icu_episodes.episode_end_time,
	drug_name,
	drug_start_time
FROM
	icu_episodes
	INNER JOIN drug_data ON icu_episodes.patient_site_uid = drug_data.patient_site_uid
	-- Can modulate time here to make sure the lab occured at a specific time from the onset of hospitalization i.e. first 24 hours
WHERE
	datetime (drug_start_time) BETWEEN datetime (icu_episodes.episode_start_time, '-72 hour') AND datetime (icu_episodes.episode_start_time, '+25 hour')
)
SELECT
	patient_site_uid,
	drug_name,
	drug_start_time
FROM
	drugs_sample
GROUP BY
	patient_site_uid, drug_name