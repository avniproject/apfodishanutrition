--------------------------------------------------------------------
-- 1. Removing Duplicate Supervisor Child Home visit
-- Select Query

SET ROLE apfodisha;

WITH duplicate_encounters AS (
	SELECT
		pe.id,
		pe.individual_id, 
		pe.program_enrolment_id,
		pe.created_date_time,
		ROW_NUMBER() OVER(PARTITION BY pe.individual_id, pe.program_enrolment_id, pe.encounter_type_id ORDER BY pe.created_date_time DESC NULLS LAST) AS latest
	FROM
		program_encounter pe
	JOIN program_enrolment pe2 ON 
		pe2.id = pe.program_enrolment_id 
		AND pe.is_voided IS FALSE 
	JOIN program p ON 
		p.id = pe2.program_id 
		AND p.is_voided IS FALSE
		AND p.name = 'Child'
	JOIN encounter_type et ON 
		et.id = pe.encounter_type_id 
		AND et.name = 'Supervisor Child Home visit'
	WHERE
		pe.encounter_date_time IS NULL
		AND pe.cancel_date_time IS NULL
		AND pe.is_voided IS FALSE
)
SELECT
	*
FROM 
	duplicate_encounters de
WHERE 
	de.latest > 1
	
-----------------------------------------------------------------------------	
--Update Query 
	
BEGIN TRANSACTION;

SET ROLE apfodisha;

WITH duplicate_encounters AS (
	SELECT
		pe.id,
		pe.individual_id, 
		pe.program_enrolment_id,
		pe.created_date_time,
		ROW_NUMBER() OVER(PARTITION BY pe.individual_id, pe.program_enrolment_id, pe.encounter_type_id ORDER BY pe.created_date_time DESC NULLS LAST) AS latest
	FROM
		program_encounter pe
	JOIN program_enrolment pe2 ON 
		pe2.id = pe.program_enrolment_id 
		AND pe.is_voided IS FALSE 
	JOIN program p ON 
		p.id = pe2.program_id 
		AND p.is_voided IS FALSE
		AND p.name = 'Child'
	JOIN encounter_type et ON 
		et.id = pe.encounter_type_id 
		AND et.name = 'Supervisor Child Home visit'
	WHERE
		pe.encounter_date_time IS NULL
		AND pe.cancel_date_time IS NULL
		AND pe.is_voided IS FALSE
)
UPDATE
	program_encounter pe
SET
	is_voided = TRUE,
	manual_update_history = append_manual_update_history(pe.manual_update_history, 'Voiding the duplicated visit as per support ticket #7075'),
	last_modified_date_time = current_timestamp + (random() * 5000 * (interval '1 millisecond')),
	last_modified_by_id = 10917
FROM
	duplicate_encounters de
WHERE
	pe.id = de.id
	AND de.latest > 1;
	
--COMMIT;
ROLLBACK ;

--------------------------------------------------------------------







-- 1. Removing Duplicate Supervisor Child Home visit
-- Select Query

SET ROLE apfodisha;

WITH duplicate_encounters AS (
	SELECT
		pe.id,
		pe.individual_id, 
		pe.program_enrolment_id,
		pe.created_date_time,
		ROW_NUMBER() OVER(PARTITION BY pe.individual_id, pe.program_enrolment_id, pe.encounter_type_id ORDER BY pe.created_date_time DESC NULLS LAST) AS latest
	FROM
		program_encounter pe
	JOIN program_enrolment pe2 ON 
		pe2.id = pe.program_enrolment_id 
		AND pe.is_voided IS FALSE 
	JOIN program p ON 
		p.id = pe2.program_id 
		AND p.is_voided IS FALSE
		AND p.name = 'Pregnancy'
	JOIN encounter_type et ON 
		et.id = pe.encounter_type_id 
		AND et.name = 'Supervisor PW Home Visit'
	WHERE
		pe.encounter_date_time IS NULL
		AND pe.cancel_date_time IS NULL
		AND pe.is_voided IS FALSE
)
SELECT
	*
FROM 
	duplicate_encounters de
WHERE 
	de.latest > 1
	
-----------------------------------------------------------------------------	
--Update Query 
	
BEGIN TRANSACTION;

SET ROLE apfodisha;

WITH duplicate_encounters AS (
	SELECT
		pe.id,
		pe.individual_id, 
		pe.program_enrolment_id,
		pe.created_date_time,
		ROW_NUMBER() OVER(PARTITION BY pe.individual_id, pe.program_enrolment_id, pe.encounter_type_id ORDER BY pe.created_date_time DESC NULLS LAST) AS latest
	FROM
		program_encounter pe
	JOIN program_enrolment pe2 ON 
		pe2.id = pe.program_enrolment_id 
		AND pe.is_voided IS FALSE 
	JOIN program p ON 
		p.id = pe2.program_id 
		AND p.is_voided IS FALSE
		AND p.name = 'Pregnancy'
	JOIN encounter_type et ON 
		et.id = pe.encounter_type_id 
		AND et.name = 'Supervisor PW Home Visit'
	WHERE
		pe.encounter_date_time IS NULL
		AND pe.cancel_date_time IS NULL
		AND pe.is_voided IS FALSE
)
UPDATE
	program_encounter pe
SET
	is_voided = TRUE,
	manual_update_history = append_manual_update_history(pe.manual_update_history, 'Voiding the duplicated visit as per support ticket #7075'),
	last_modified_date_time = current_timestamp + (random() * 5000 * (interval '1 millisecond')),
	last_modified_by_id = 10917
FROM
	duplicate_encounters de
WHERE
	pe.id = de.id
	AND de.latest > 1;
	
--COMMIT;
ROLLBACK ;
--------------------------------------------------------------------------------------------
