-- In this version labs for all the duration
-- Can easily modify script to modify for different hours

WITH labs_sample AS (
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
	lab_name,
	lab_sample_type,
	lab_sample_time,
	lab_result_value
FROM
	covidepisodes
	INNER JOIN lab_data ON covidepisodes.patient_site_uid = lab_data.patient_site_uid
	-- Can modulate time here to make sure the lab occured at a specific time from the onset of hospitalization i.e. first 24 hours
WHERE
	datetime (lab_sample_time) BETWEEN datetime (covidepisodes.episode_start_time, '-24 hour') 
	AND datetime (covidepisodes.episode_start_time, '+72 hour')
)

SELECT
	patient_site_uid, -- min(lab_result_value) AS lab_min
	-- *CBC**
	-- Hemoglobin
	min( CASE WHEN lab_name = 'hemoglobin' THEN
		lab_result_value
	ELSE
		NULL
	END) AS hemoglobin_min, max(
		CASE WHEN lab_name = 'hemoglobin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS hemoglobin_max, round(avg(
			CASE WHEN lab_name = 'hemoglobin' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS hemoglobin_mean,
	-- Platelet
	min(
		CASE WHEN lab_name = 'platelet_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS plt_min, max(
		CASE WHEN lab_name = 'platelet_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS plt_max, round(avg(
			CASE WHEN lab_name = 'platelet_count' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS plt_mean,
	-- WBC
	min(
		CASE WHEN lab_name = 'white_blood_cell_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS wbc_min, max(
		CASE WHEN lab_name = 'white_blood_cell_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS wbc_max, round(avg(
			CASE WHEN lab_name = 'white_blood_cell_count' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS wbc_mean,
	-- *CHEM*
	-- Albumin
	min(
		CASE WHEN lab_name = 'albumin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS albumin_min, max(
		CASE WHEN lab_name = 'albumin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS albumin_max, round(avg(
			CASE WHEN lab_name = 'albumin' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS albumin_mean,
	-- Globulins
	min(
		CASE WHEN lab_name = 'globulins' THEN
			lab_result_value
		ELSE
			NULL
		END) AS globulin_min, max(
		CASE WHEN lab_name = 'globulins' THEN
			lab_result_value
		ELSE
			NULL
		END) AS globulin_max, round(avg(
			CASE WHEN lab_name = 'globulins' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS globulin_mean,
	-- Total Protein
	min(
		CASE WHEN lab_name = 'total_protein' THEN
			lab_result_value
		ELSE
			NULL
		END) AS protein_min, max(
		CASE WHEN lab_name = 'total_protein' THEN
			lab_result_value
		ELSE
			NULL
		END) AS protein_max, round(avg(
			CASE WHEN lab_name = 'total_protein' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS protein_mean,
	-- Sodium
	min(
		CASE WHEN lab_name = 'sodium' THEN
			lab_result_value
		ELSE
			NULL
		END) AS sodium_min, max(
		CASE WHEN lab_name = 'sodium' THEN
			lab_result_value
		ELSE
			NULL
		END) AS sodium_max, round(avg(
			CASE WHEN lab_name = 'sodium' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS sodium_mean,
	-- Chloride
	min(
		CASE WHEN lab_name = 'chloride' THEN
			lab_result_value
		ELSE
			NULL
		END) AS chloride_min, max(
		CASE WHEN lab_name = 'chloride' THEN
			lab_result_value
		ELSE
			NULL
		END) AS chloride_max, round(avg(
			CASE WHEN lab_name = 'chloride' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS chloride_mean,
	-- Potassium
	min(
		CASE WHEN lab_name = 'potassium' THEN
			lab_result_value
		ELSE
			NULL
		END) AS potassium_min, max(
		CASE WHEN lab_name = 'potassium' THEN
			lab_result_value
		ELSE
			NULL
		END) AS potassium_max, round(avg(
			CASE WHEN lab_name = 'potassium' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS potassium_mean,
	-- Bicarbonate
	min(
		CASE WHEN lab_name = 'bicarbonate' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bicarbonate_min, max(
		CASE WHEN lab_name = 'bicarbonate' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bicarbonate_max, round(avg(
			CASE WHEN lab_name = 'bicarbonate' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS bicarbonate_mean,
	-- BUN
	min(
		CASE WHEN lab_name = 'urea' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bun_min, max(
		CASE WHEN lab_name = 'urea' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bun_max, round(avg(
			CASE WHEN lab_name = 'urea' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS bun_mean,
	-- Calcium
	min(
		CASE WHEN lab_name = 'calcium' THEN
			lab_result_value
		ELSE
			NULL
		END) AS calcium_min, max(
		CASE WHEN lab_name = 'calcium' THEN
			lab_result_value
		ELSE
			NULL
		END) AS calcium_max, round(avg(
			CASE WHEN lab_name = 'calcium' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS calcium_mean,
	-- Magnesium
	min(
		CASE WHEN lab_name = 'magnesium' THEN
			lab_result_value
		ELSE
			NULL
		END) AS magnesium_min, max(
		CASE WHEN lab_name = 'magnesium' THEN
			lab_result_value
		ELSE
			NULL
		END) AS magnesium_max, round(avg(
			CASE WHEN lab_name = 'magnesium' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS magnesium_mean,
	-- Total Phosphate
	min(
		CASE WHEN lab_name = 'phosphate' THEN
			lab_result_value
		ELSE
			NULL
		END) AS phosphate_min, max(
		CASE WHEN lab_name = 'phosphate' THEN
			lab_result_value
		ELSE
			NULL
		END) AS phosphate_max, round(avg(
			CASE WHEN lab_name = 'phosphate' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS phosphate_mean,
	-- Creatinine
	min(
		CASE WHEN lab_name = 'creatinine' THEN
			lab_result_value
		ELSE
			NULL
		END) AS creatinine_min, max(
		CASE WHEN lab_name = 'creatinine' THEN
			lab_result_value
		ELSE
			NULL
		END) AS creatinine_max, round(avg(
			CASE WHEN lab_name = 'creatinine' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS creatinine_mean,
	-- DFG
	min(
		CASE WHEN lab_name = 'estimated_gfr' THEN
			lab_result_value
		ELSE
			NULL
		END) AS gfr_min, max(
		CASE WHEN lab_name = 'estimated_gfr' THEN
			lab_result_value
		ELSE
			NULL
		END) AS gfr_max, round(avg(
			CASE WHEN lab_name = 'estimated_gfr' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS gfr_mean,
	-- Glucose
	min(
		CASE WHEN lab_name = 'glucose' THEN
			lab_result_value
		ELSE
			NULL
		END) AS glucose_min, max(
		CASE WHEN lab_name = 'glucose' THEN
			lab_result_value
		ELSE
			NULL
		END) AS glucose_max, round(avg(
			CASE WHEN lab_name = 'glucose' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS glucose_max,
	-- AnionGAP original
	min(
		CASE WHEN lab_name = 'anion_gap' THEN
			lab_result_value
		ELSE
			NULL
		END) AS anion_gap_min, max(
		CASE WHEN lab_name = 'anion_gap' THEN
			lab_result_value
		ELSE
			NULL
		END) AS anion_gap_min, round(avg(
			CASE WHEN lab_name = 'anion_gap' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS anion_gap_mean,
-- Total **DIFF**
	-- Eosinophils
	min(
		CASE WHEN lab_name = 'eosinophil_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS eos_min, max(
		CASE WHEN lab_name = 'eosinophil_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS eos_max, round(avg(
			CASE WHEN lab_name = 'eosinophil_count' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS eos_mean,
	-- Lymphocytes
	min(
		CASE WHEN lab_name = 'lymphocyte_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS lymph_min, max(
		CASE WHEN lab_name = 'lymphocyte_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS lymph_max, round(avg(
			CASE WHEN lab_name = 'lymphocyte_count' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS lymph_mean,
	-- Neutrophils
	min(
		CASE WHEN lab_name = 'neutrophil_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS neutrophil_min, max(
		CASE WHEN lab_name = 'neutrophil_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS neutrophil_max, round(avg(
			CASE WHEN lab_name = 'neutrophil_count' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS neutrophil_mean,
	-- Monocytes
	min(
		CASE WHEN lab_name = 'monocyte_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS mono_min, max(
		CASE WHEN lab_name = 'monocyte_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS mono_max, round(avg(
			CASE WHEN lab_name = 'monocyte_count' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS mono_mean,
	-- Basophils
	min(
		CASE WHEN lab_name = 'basophil_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS baso_min, max(
		CASE WHEN lab_name = 'basophil_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS baso_max, round(avg(
			CASE WHEN lab_name = 'basophil_count' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS baso_mean,
	-- Bands
	min(
		CASE WHEN lab_name = 'stab_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS stab_min, max(
		CASE WHEN lab_name = 'stab_count' THEN
			lab_result_value
		ELSE
			NULL
		END) AS stab_max, round(avg(
			CASE WHEN lab_name = 'stab_count' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS stab_mean,
	-- atypicals, bands, not available
	-- Total **COAG**
	-- PT
	min(
		CASE WHEN lab_name = 'thrombin_time' THEN
			lab_result_value
		ELSE
			NULL
		END) AS PT_min, max(
		CASE WHEN lab_name = 'thrombin_time' THEN
			lab_result_value
		ELSE
			NULL
		END) AS PT_max, round(avg(
			CASE WHEN lab_name = 'thrombin_time' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS PT_mean,
	-- PTT
	min(
		CASE WHEN lab_name = 'partial_thromboplastin_time' THEN
			lab_result_value
		ELSE
			NULL
		END) AS PTT_min, max(
		CASE WHEN lab_name = 'partial_thromboplastin_time' THEN
			lab_result_value
		ELSE
			NULL
		END) AS PTT_max, round(avg(
			CASE WHEN lab_name = 'partial_thromboplastin_time' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS PTT_mean,
	-- Fibrinogen
	min(
		CASE WHEN lab_name = 'fibrinogen' THEN
			lab_result_value
		ELSE
			NULL
		END) AS fibrinogen_min, max(
		CASE WHEN lab_name = 'fibrinogen' THEN
			lab_result_value
		ELSE
			NULL
		END) AS fibrinogen_max, round(avg(
			CASE WHEN lab_name = 'fibrinogen' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS fibrinogen_mean,
	-- DDimer
	min(
		CASE WHEN lab_name = 'd_dimer' THEN
			lab_result_value
		ELSE
			NULL
		END) AS d_dimer_min, max(
		CASE WHEN lab_name = 'd_dimer' THEN
			lab_result_value
		ELSE
			NULL
		END) AS d_dimer_max, round(avg(
			CASE WHEN lab_name = 'd_dimer' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS d_dimer_mean,
	-- Total **Enzymes**
	-- ALT
	min(
		CASE WHEN lab_name = 'alanine_aminotransferase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS alt_min, max(
		CASE WHEN lab_name = 'alanine_aminotransferase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS alt_max, round(avg(
			CASE WHEN lab_name = 'alanine_aminotransferase' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS alt_mean,
	-- AST
	min(
		CASE WHEN lab_name = 'ast' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ast_min, max(
		CASE WHEN lab_name = 'ast' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ast_max, round(avg(
			CASE WHEN lab_name = 'ast' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS ast_mean,
	-- PALC
	min(
		CASE WHEN lab_name = 'alkaline_phosphatase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS palc_min, max(
		CASE WHEN lab_name = 'alkaline_phosphatase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS palc_max, round(avg(
			CASE WHEN lab_name = 'alkaline_phosphatase' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS palc_mean,
	-- GGT
	min(
		CASE WHEN lab_name = 'gamma_glutamyl_transferase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ggt_min, max(
		CASE WHEN lab_name = 'gamma_glutamyl_transferase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ggt_max, round(avg(
			CASE WHEN lab_name = 'gamma_glutamyl_transferase' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS ggt_mean,
	-- Amylase
	min(
		CASE WHEN lab_name = 'amylase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS amylase_min, max(
		CASE WHEN lab_name = 'amylase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS amylase_max, round(avg(
			CASE WHEN lab_name = 'amylase' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS amylase_mean,
	-- Lipase
	min(
		CASE WHEN lab_name = 'lipase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS lipase_min, max(
		CASE WHEN lab_name = 'lipase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS lipase_max, round(avg(
			CASE WHEN lab_name = 'lipase' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS lipase_mean,
	-- Bili_total
	min(
		CASE WHEN lab_name = 'total_bilirubin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bili_tot_min, max(
		CASE WHEN lab_name = 'total_bilirubin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bili_tot_max, round(avg(
			CASE WHEN lab_name = 'total_bilirubin' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS bili_tot_mean,
	-- Bili_direct
	min(
		CASE WHEN lab_name = 'direct_bilirubin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bili_direct_min, max(
		CASE WHEN lab_name = 'direct_bilirubin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bili_direct_max, round(avg(
			CASE WHEN lab_name = 'direct_bilirubin' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS bili_direct_mean,
	-- Bili_indirect
	min(
		CASE WHEN lab_name = 'indirect_bilirubin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bili_indirect_min, max(
		CASE WHEN lab_name = 'indirect_bilirubin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bili_indirect_max, round(avg(
			CASE WHEN lab_name = 'indirect_bilirubin' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS bili_indirect_mean,
	-- Lipase
	min(
		CASE WHEN lab_name = 'lipase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS lipase_min, max(
		CASE WHEN lab_name = 'lipase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS lipase_max, round(avg(
			CASE WHEN lab_name = 'lipase' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS lipase_mean,
	-- CK
	min(
		CASE WHEN lab_name = 'creatine_kinase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ck_min, max(
		CASE WHEN lab_name = 'creatine_kinase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ck_max, round(avg(
			CASE WHEN lab_name = 'creatine_kinase' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS ck_mean,
	-- CK-MB
	min(
		CASE WHEN lab_name = 'ck_mb' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ckmb_min, max(
		CASE WHEN lab_name = 'ck_mb' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ckmb_max, round(avg(
			CASE WHEN lab_name = 'ck_mb' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS ckmb_mean,
	-- LDH
	min(
		CASE WHEN lab_name = 'lactate_dehydrogenase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ldh_min, max(
		CASE WHEN lab_name = 'lactate_dehydrogenase' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ldh_max, round(avg(
			CASE WHEN lab_name = 'lactate_dehydrogenase' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS ldh_mean,
	-- TROPOS
	min(
		CASE WHEN lab_name = 'hs_troponin_t' THEN
			lab_result_value
		ELSE
			NULL
		END) AS tropot_min, max(
		CASE WHEN lab_name = 'hs_troponin_t' THEN
			lab_result_value
		ELSE
			NULL
		END) AS tropot_max, round(avg(
			CASE WHEN lab_name = 'hs_troponin_t' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS tropot_mean,
	-- Lactate
	min(
		CASE WHEN lab_name = 'lactic_acid' THEN
			lab_result_value
		ELSE
			NULL
		END) AS lactate_min, max(
		CASE WHEN lab_name = 'lactic_acid' THEN
			lab_result_value
		ELSE
			NULL
		END) AS lactate_max, round(avg(
			CASE WHEN lab_name = 'lactic_acid' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS lactate_mean,
	-- Oxygenation
	-- O2 sat
	min(
		CASE WHEN lab_name = 'o2_sat' AND lab_sample_type = 'venous_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS svo2sat_min, max(
		CASE WHEN lab_name = 'o2_sat' AND lab_sample_type = 'venous_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS svo2sat_max, round(avg(
			CASE WHEN lab_name = 'o2_sat' AND lab_sample_type = 'venous_blood' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS svo2sat_max,
	-- PAO2
	min(
		CASE WHEN lab_name = 'po2' AND lab_sample_type = 'arterial_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS pao2_min, max(
		CASE WHEN lab_name = 'po2' AND lab_sample_type = 'arterial_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS pao2_max, round(avg(
			CASE WHEN lab_name = 'po2' AND lab_sample_type = 'arterial_blood' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS pao2_mean,
	-- PVO2
	min(
		CASE WHEN lab_name = 'po2' AND lab_sample_type = 'venous_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS pvo2_min, max(
		CASE WHEN lab_name = 'po2' AND lab_sample_type = 'venous_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS pvo2_max, round(avg(
			CASE WHEN lab_name = 'po2' AND lab_sample_type = 'venous_blood' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS pvo2_mean,
	-- PACO2
	min(
		CASE WHEN lab_name = 'pco2' AND lab_sample_type = 'venous_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS paco2_min, max(
		CASE WHEN lab_name = 'pco2' AND lab_sample_type = 'venous_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS paco2_max, round(avg(
			CASE WHEN lab_name = 'pco2' AND lab_sample_type = 'venous_blood' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS paco2_mean,
	-- PVCO2
	min(
		CASE WHEN lab_name = 'pco2' AND lab_sample_type = 'venous_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS pvco2_min, max(
		CASE WHEN lab_name = 'pco2' AND lab_sample_type = 'venous_blood' THEN
			lab_result_value
		ELSE
			NULL
		END) AS pvco2_max, round(avg(
			CASE WHEN lab_name = 'pco2' AND lab_sample_type = 'venous_blood' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS pvco2_mean,
	-- Total **Other**
	-- TSH
	min(
		CASE WHEN lab_name = 'thyroid_stimulating_hormone' THEN
			lab_result_value
		ELSE
			NULL
		END) AS tsh_min, max(
		CASE WHEN lab_name = 'thyroid_stimulating_hormone' THEN
			lab_result_value
		ELSE
			NULL
		END) AS tsh_max, round(avg(
			CASE WHEN lab_name = 'thyroid_stimulating_hormone' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS tsh_mean,
	-- Vitamin D
	min(
		CASE WHEN lab_name = '25_oh_vitamin_d' THEN
			lab_result_value
		ELSE
			NULL
		END) AS vitd_min, max(
		CASE WHEN lab_name = '25_oh_vitamin_d' THEN
			lab_result_value
		ELSE
			NULL
		END) AS vitd_max, round(avg(
			CASE WHEN lab_name = '25_oh_vitamin_d' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS vitd_mean,
	-- CRP
	min(
		CASE WHEN lab_name = 'c_reactive_protein' THEN
			lab_result_value
		ELSE
			NULL
		END) AS crp_min, max(
		CASE WHEN lab_name = 'c_reactive_protein' THEN
			lab_result_value
		ELSE
			NULL
		END) AS crp_max, round(avg(
			CASE WHEN lab_name = 'c_reactive_protein' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS crp_mean,
	-- Ferritin
	min(
		CASE WHEN lab_name = 'ferritin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ferritin_min, max(
		CASE WHEN lab_name = 'ferritin' THEN
			lab_result_value
		ELSE
			NULL
		END) AS ferritin_max, round(avg(
			CASE WHEN lab_name = 'ferritin' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS ferritin_mean,
	-- BNP
	min(
		CASE WHEN lab_name = 'nt_pro_bnp' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bnp_min, max(
		CASE WHEN lab_name = 'nt_pro_bnp' THEN
			lab_result_value
		ELSE
			NULL
		END) AS bnp_min, round(avg(
			CASE WHEN lab_name = 'nt_pro_bnp' THEN
				lab_result_value
			ELSE
				NULL
			END), 2) AS bnp_mean
	-- AnionGAP_calculated
	-- sodium_mean - bicarbonate_mean - chloride_mean AS anion_gap_calc,
FROM
	labs_sample
GROUP BY
	patient_site_uid