------------------------------------------------------------------- Encounter updates --------------------------------------------------------------------------------
set role apfodishauat;

SELECT *
FROM public.program_encounter
WHERE observations::text NOT LIKE '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
  AND encounter_type_id IN (1398, 1399, 1400)
  AND encounter_date_time NOTNULL; --305 encounters

SELECT *
FROM encounter_type;
-- 1398,ANC
-- 1399,Delivery
-- 1400,Child followup

-- ANCs whose delivery is done
SELECT count(pe1.id)
FROM program_encounter pe1
         LEFT JOIN program_encounter pe2 ON pe1.individual_id = pe2.individual_id
WHERE pe2.encounter_type_id = 1399
  AND pe1.encounter_type_id = 1398 and pe2.encounter_date_time is not null;
-- 671

SELECT count(id)
FROM public.program_encounter
WHERE observations::text NOT LIKE '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
  AND encounter_type_id IN (1398, 1399)
  AND encounter_date_time IS NOT NULL;
-- 292

-- Query to update ANC & Delivery encounter:
-- If the delivery form is filled, then set "High risk" to "No".
-- If the delivery form is not filled and there is any data for the 'ANC' encounter related to the concept "High risk Conditions",
-- then set "High risk" to "Yes".
-- If neither of the above conditions are met, set "High risk" to "No".
WITH anc_whose_delivery_done AS (SELECT pe1.id
                                 FROM program_encounter pe1
                                          LEFT JOIN program_encounter pe2 ON pe1.individual_id = pe2.individual_id
                                 WHERE pe2.encounter_type_id = 1399
                                   AND pe1.encounter_type_id = 1398 and pe2.encounter_date_time is not null)
UPDATE public.program_encounter pe
SET observations = CASE
                       WHEN pe.id IN (SELECT id FROM anc_whose_delivery_done) THEN
                               observations ||
                               '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}' -- high risk no
                       WHEN  pe.observations -> '9a7f284b-251d-459b-97d9-929ed280b3d3' IS NOT NULL THEN
                               observations ||
                               '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}' -- high risk yes
                       ELSE
                               observations ||
                               '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["aa77bd700-1409-4d52-93bc-9fe32c0e169b"]}' -- high risk no
    END,
    last_modified_date_time = now(),
    last_modified_by_id = (select id from users where username ='nupoork@apfodishauat'),
    manual_update_history = 'Fixing missing high risk sync attributes'
WHERE pe.id IN (SELECT id
                FROM public.program_encounter
                WHERE observations::text NOT LIKE '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
                  AND encounter_type_id IN (1398, 1399)
                  AND encounter_date_time IS NOT NULL);
-- 292 rows affected


-- Query to update child follow-up encounter:
-- If a child's 'Weight for Height Status' is 'SAM' (OR) their 'Weight for Age Status' is 'Severely Underweight',
-- then record an observation for 'High risk' as 'Yes'. Otherwise, record 'High risk' as 'No'.
UPDATE public.program_encounter AS pe
SET observations = CASE
                       WHEN pe.observations -> 'efeb0a0b-aea4-4af1-9bc4-37d86bc865a1' =
                            '["4b855734-921c-4796-a752-39b3ede1c66c"]'
                           OR pe.observations -> '2a2027c1-cec9-4237-a53a-80d6b1047979' =
                              '["7d0229c1-e69e-4cac-8937-cdd48c8ed9dd"]'
                           THEN
                               observations ||
                               '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'
                       ELSE
                               observations ||
                               '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
    END,
    last_modified_date_time = now(),
    last_modified_by_id = (select id from users where username ='nupoork@apfodishauat'),
    manual_update_history = 'Fixing missing high risk sync attributes'
WHERE pe.id IN (SELECT id
                FROM public.program_encounter
                WHERE observations::text NOT LIKE '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
                  AND encounter_type_id = 1400
                  AND encounter_date_time IS NOT NULL);

-- 13

------------------------------------------------------------------- Encounter updates end--------------------------------------------------------------------------------




------------------------------------------------------------------- Enrolment updates --------------------------------------------------------------------------------

set role apfodishauat;

-- Observations that don't have high risk status in enrolments.
select count(*)
from public.program_enrolment
where observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'; -- 1665 enrolments

select * from program;
-- 341 Child
-- 340 Pregnancy

-- Query to update Pregnancy enrolment:

WITH LatestEncounter AS (SELECT enl.id,
                                coalesce(pe.observations -> 'be0ab05f-b0f3-43ec-b598-fdde0679104a',
                                         null)                                                                                                AS high_risk_value,
                                ROW_NUMBER()
                                OVER (PARTITION BY enl.id ORDER BY coalesce(pe.encounter_date_time, enl.enrolment_date_time) DESC NULLS LAST) AS rn
                         FROM public.program_enrolment enl
                                  left join program_encounter pe
                                            on enl.id = pe.program_enrolment_id and pe.encounter_type_id = 1398
)
UPDATE public.program_enrolment enl
SET observations            =
        CASE
            -- If there's a corresponding ANC encounter, use its High risk value
            WHEN le.high_risk_value IS NOT NULL THEN
                    enl.observations ||
                    JSONB_SET(enl.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', high_risk_value)
            -- If there's no ANC but there's a Red Flag in enrolment, set High risk to what is there in Red Flag observation
            WHEN enl.observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' IS NOT NULL
                and enl.observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' = '"8ebbf088-f292-483e-9084-7de919ce67b7"'
                then
                    enl.observations ||
                    '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'
            -- Otherwise, set High risk to no
            ELSE
                    enl.observations ||
                    '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
            END,
    last_modified_date_time = now(),
    last_modified_by_id     = (select id from users where username = 'nupoork@apfodishauat'),
    manual_update_history   = 'Fixing missing high risk sync attributes'
FROM LatestEncounter le
WHERE enl.id = le.id
  AND le.rn = 1
  AND enl.observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
  and program_id =340;

-- 1,665 rows affected


-- Query to update Child enrolment:
WITH LatestEncounter AS (SELECT pe.program_enrolment_id,
                                pe.observations -> 'be0ab05f-b0f3-43ec-b598-fdde0679104a'                                   AS high_risk_value,
                                ROW_NUMBER()
                                OVER (PARTITION BY pe.program_enrolment_id ORDER BY pe.encounter_date_time DESC NULLS LAST) AS rn
                         FROM public.program_encounter pe
                         WHERE pe.encounter_type_id = 1400)
UPDATE public.program_enrolment enl
SET observations =
        CASE
            -- If there's a corresponding child followup encounter, use its High risk value
            WHEN le.high_risk_value IS NOT NULL THEN
                    enl.observations ||
                    JSONB_SET(enl.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', high_risk_value)
            -- Otherwise, set High risk to no
            ELSE
                    enl.observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
            END,
    last_modified_date_time = now(),
    last_modified_by_id = (select id from users where username ='nupoork@apfodishauat'),
    manual_update_history = 'Fixing missing high risk sync attributes'
FROM LatestEncounter le
WHERE enl.id = le.program_enrolment_id
  AND le.rn = 1
  AND enl.observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
  and program_id =341;

------------------------------------------------------------------- Enrolment update end --------------------------------------------------------------------------------

------------------------------------------------------------------- Individual update --------------------------------------------------------------------------------

set role apfodishauat;

-- Query to update individual table:
UPDATE public.individual AS ind
SET observations =
        CASE
            -- If there's a corresponding program enrolment, use its High risk value
            WHEN pe.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' IS NOT NULL THEN
                    ind.observations || JSONB_SET(ind.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}',
                                                  pe.observations -> 'be0ab05f-b0f3-43ec-b598-fdde0679104a')
            -- If there's no program enrolment, set High risk to no
            ELSE
                    ind.observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
            END,
    last_modified_date_time = now(),
    last_modified_by_id = (select id from users where username ='nupoork@apfodishauat'),
    manual_update_history = 'Fixing missing high risk sync attributes'
FROM public.program_enrolment pe
WHERE ind.id = pe.individual_id
  AND subject_type_id = 557
  AND ind.observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%';

------------------------------------------------------------------- Individual update end--------------------------------------------------------------------------------

------------------------------------------------------------------- Sync concpet1 value update --------------------------------------------------------------------------------


set role apfodishauat;

-- Query to update sync_concept_1_value column in the individual table
UPDATE public.individual
SET sync_concept_1_value =
        CASE
            WHEN observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' = 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
                THEN 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            WHEN observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '8ebbf088-f292-483e-9084-7de919ce67b7'
                THEN '8ebbf088-f292-483e-9084-7de919ce67b7'
            END,
    last_modified_date_time = now(),
    last_modified_by_id = (select id from users where username ='nupoork@apfodishauat'),
    manual_update_history = 'Fixing missing high risk sync attributes'
WHERE subject_type_id = 557
  AND observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' IS NOT NULL;

-- 4772

-- Query to update sync_concept_1_value column in the program enrolment table
UPDATE public.program_enrolment e
SET sync_concept_1_value =
        CASE
            WHEN i.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' = 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
                THEN 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            WHEN i.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '8ebbf088-f292-483e-9084-7de919ce67b7'
                THEN '8ebbf088-f292-483e-9084-7de919ce67b7'
            END,
    last_modified_date_time = now(),
    last_modified_by_id = (select id from users where username ='nupoork@apfodishauat'),
    manual_update_history = 'Fixing missing high risk sync attributes'
FROM public.individual i
WHERE i.id = e.individual_id
  and subject_type_id = 557
  AND i.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' IS NOT NULL;

-- 2,400

-- Query to update sync_concept_1_value column in the program encounter table
UPDATE public.program_encounter enc
SET sync_concept_1_value =
        CASE
            WHEN i.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' = 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
                THEN 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            WHEN i.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '8ebbf088-f292-483e-9084-7de919ce67b7'
                THEN '8ebbf088-f292-483e-9084-7de919ce67b7'
            END,
    last_modified_date_time = now(),
    last_modified_by_id = (select id from users where username ='nupoork@apfodishauat'),
    manual_update_history = 'Fixing missing high risk sync attributes'
FROM public.individual i
WHERE i.id = enc.individual_id
  and subject_type_id = 557
  AND i.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' IS NOT NULL;

-- 5526



------------------------------------------------------------------- Sync concpet1 value update end--------------------------------------------------------------------------------







