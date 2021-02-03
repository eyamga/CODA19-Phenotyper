SELECT
	patient_site_uid,
	patient_age,
	patient_sex
FROM
	patient_data
WHERE
	patient_data.patient_covid_status = 'positive'