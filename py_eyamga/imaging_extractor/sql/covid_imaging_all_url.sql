-- In this version drugs for the first 24h of stay
-- Can easily modify script to modify for different hours
WITH imaging_timed AS (
WITH imaging_sample AS (
	-- In this script we are taking into consideration the ENTIRE COVID EPISODE AS ONE WITH covidepisodes AS (
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
	imaging_data.patient_site_uid,
	imaging_accession_uid,
	imaging_acquisition_time,
	imaging_body_site,
	imaging_modality
FROM
	covidepisodes
	INNER JOIN imaging_data ON covidepisodes.patient_site_uid = imaging_data.patient_site_uid
	-- Can modulate time here to make sure the lab occured at a specific time from the onset of hospitalization i.e. first 24 hours
WHERE
	datetime (imaging_acquisition_time) BETWEEN datetime (covidepisodes.episode_start_time, '-24 hour') AND datetime (covidepisodes.episode_start_time, '+72 hour')
)
SELECT-- In this version drugs for the first 24h of stay
-- Can easily modify script to modify for different hours
WITH imaging_timed AS (
WITH imaging_sample AS (
	-- In this script we are taking into consideration the ENTIRE COVID EPISODE AS ONE WITH covidepisodes AS (
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
	imaging_data.patient_site_uid,
	imaging_accession_uid,
	imaging_acquisition_time,
	imaging_body_site,
	imaging_modality
FROM
	covidepisodes
	INNER JOIN imaging_data ON covidepisodes.patient_site_uid = imaging_data.patient_site_uid
	-- Can modulate time here to make sure the lab occured at a specific time from the onset of hospitalization i.e. first 24 hours
WHERE
	datetime (imaging_acquisition_time) BETWEEN datetime (covidepisodes.episode_start_time, '-24 hour') AND datetime (covidepisodes.episode_start_time, '+72 hour')
)
SELECT
	patient_site_uid,
	min(datetime(imaging_acquisition_time)) AS imaging_acquisition_time, -- This assures to retrieve the first image for each patient
	imaging_accession_uid
FROM
	imaging_sample
GROUP BY -- Grouping by PID allows to retain only the first image per patient
	patient_site_uid -- if adding, imaging_accession_uid we ensure to grab all first 72 hour images but this is not the goal here
)
SELECT imaging_timed.patient_site_uid, imaging_timed.imaging_accession_uid, slice_data_uri, slice_view_position
FROM imaging_timed
INNER JOIN slice_data ON imaging_timed.imaging_accession_uid = slice_data.imaging_accession_uid
-- In this script, all duplicates are from patients having had multiple sequences of the same acquisition

	patient_site_uid,
	min(datetime(imaging_acquisition_time)) AS imaging_acquisition_time, -- This assures to retrieve the first image for each patient
	imaging_accession_uid
FROM
	imaging_sample
GROUP BY -- Grouping by PID allows to retain only the first image per patient
	patient_site_uid -- if adding, imaging_accession_uid we ensure to grab all first 72 hour images but this is not the goal here
)
SELECT imaging_timed.patient_site_uid, imaging_timed.imaging_accession_uid, slice_data_uri, slice_view_position
FROM imaging_timed
INNER JOIN slice_data ON imaging_timed.imaging_accession_uid = slice_data.imaging_accession_uid
-- In this script, all duplicates are from patients having had multiple sequences of the same acquisition
