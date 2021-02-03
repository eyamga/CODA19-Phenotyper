SELECT
	icu_episodes.patient_site_uid, intervention_start_time, intervention_end_time
FROM
	icu_episodes
	INNER JOIN intervention_data ON icu_episodes.patient_site_uid = intervention_data.patient_site_uid
WHERE
	datetime (intervention_start_time)  BETWEEN datetime (icu_episodes.episode_start_time, '-2 day') AND datetime (icu_episodes.episode_start_time, '+1 day')