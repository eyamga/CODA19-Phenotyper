WITH imaging_timed AS (
WITH imaging_sample AS (
	-- In this script we are taking into consideration the ENTIRE COVID EPISODE AS ONE WITH covidepisodes AS (
SELECT
	icu_episodes.patient_site_uid,
	icu_episodes.episode_start_time,
	icu_episodes.episode_end_time,
	imaging_data.patient_site_uid,
	imaging_accession_uid,
	imaging_acquisition_time,
	imaging_body_site,
	imaging_modality
FROM
	icu_episodes
	INNER JOIN imaging_data ON icu_episodes.patient_site_uid = imaging_data.patient_site_uid
	-- Can modulate time here to make sure the lab occured at a specific time from the onset of hospitalization i.e. first 24 hours
WHERE
	datetime (imaging_acquisition_time) BETWEEN datetime (icu_episodes.episode_start_time, '-24 hour') AND datetime (icu_episodes.episode_start_time, '+72 hour')
)
SELECT
	patient_site_uid,
	min(datetime(imaging_acquisition_time)) AS imaging_acquisition_time, -- This assures to retrieve the first image for each patient
	imaging_accession_uid
FROM
	imaging_sample
GROUP BY -- Grouping by PID allows to retain only the first image per patient
	patient_site_uid -- if we were to add imaging_accession_uid to the group we would ensure to grab all first 72 hour images but this is not the goal here, as we only want the first)
)
SELECT imaging_timed.patient_site_uid, imaging_timed.imaging_accession_uid, slice_data_uri, slice_view_position
FROM imaging_timed
INNER JOIN slice_data ON imaging_timed.imaging_accession_uid = slice_data.imaging_accession_uid
-- In this script, all duplicates are from patients having had multiple sequences of the same acquisition
