------------------------------------------------------------------- Encounter updates --------------------------------------------------------------------------------
set role apfodisha;

SELECT count(*)
FROM public.program_encounter
WHERE observations::text NOT LIKE '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
  AND encounter_type_id IN (1656)
  AND encounter_date_time NOTNULL; --8183 encounters

SELECT *
FROM encounter_type;
-- 1653,ANC
-- 1655,Delivery
-- 1656,Child followup

-- ANCs whose delivery is done
SELECT count(pe1.id)
FROM program_encounter pe1
         LEFT JOIN program_encounter pe2 ON pe1.individual_id = pe2.individual_id
WHERE pe2.encounter_type_id = 1655
  AND pe1.encounter_type_id = 1653 and pe2.encounter_date_time is not null;
-- 25408

select count(*)
from program_encounter where encounter_type_id = 1653;


SELECT count(id)
FROM public.program_encounter
WHERE observations::text NOT LIKE '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
  AND encounter_type_id IN (1653, 1655)
  AND encounter_date_time IS NOT NULL;
-- 7211

-- Query to update ANC & Delivery encounter:
-- If the delivery form is filled, then set "High risk" to "No".
-- If the delivery form is not filled and there is any data for the 'ANC' encounter related to the concept "High risk Conditions",
-- then set "High risk" to "Yes".
-- If neither of the above conditions are met, set "High risk" to "No".
WITH anc_whose_delivery_done AS (SELECT pe1.id
                                 FROM program_encounter pe1
                                          LEFT JOIN program_encounter pe2 ON pe1.individual_id = pe2.individual_id
                                 WHERE pe2.encounter_type_id = 1655
                                   AND pe1.encounter_type_id = 1653 and pe2.encounter_date_time is not null)
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
    last_modified_date_time = current_timestamp + ( (id * 11) * interval '1 millisecond'),
    last_modified_by_id = (select id from users where username ='nupoork@apfodisha'),
    manual_update_history = 'Fixing missing high risk sync attributes'
WHERE pe.id IN (SELECT id
                FROM public.program_encounter
                WHERE observations::text NOT LIKE '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
                  AND encounter_type_id IN (1653, 1655)
                  AND encounter_date_time IS NOT NULL);
-- 7211 rows affected


-- Query to update child follow-up encounter:
-- If a child's 'Weight for Height Status' is 'SAM' (OR) their 'Weight for Age Status' is 'Severely Underweight',
-- then record an observation for 'High risk' as 'Yes'. Otherwise, record 'High risk' as 'No'.
SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

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
    last_modified_date_time = current_timestamp + ( (id * 11) * interval '1 millisecond'),
    last_modified_by_id = (select id from users where username ='nupoork@apfodisha'),
    manual_update_history = 'Fixing missing high risk sync attributes'
WHERE pe.id IN (SELECT id
                FROM public.program_encounter
                WHERE observations::text NOT LIKE '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
                  AND encounter_type_id = 1656
                  AND encounter_date_time IS NOT NULL);

-- 972

------------------------------------------------------------------- Encounter updates end--------------------------------------------------------------------------------




------------------------------------------------------------------- Enrolment updates --------------------------------------------------------------------------------

set role apfodisha;


-- Observations that don't have high risk status in enrolments.
select count(*)
from public.program_enrolment
where observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%' and program_id = 489;
-- pregnancy 93
-- child 223

select * from program;
-- 489 Child
-- 488 Pregnancy

-- Query to update Pregnancy enrolment:

WITH LatestEncounter AS (SELECT enl.id,
                                coalesce(pe.observations -> 'be0ab05f-b0f3-43ec-b598-fdde0679104a',
                                         null)                                                                                                AS high_risk_value,
                                ROW_NUMBER()
                                OVER (PARTITION BY enl.id ORDER BY coalesce(pe.encounter_date_time, enl.enrolment_date_time) DESC NULLS LAST) AS rn
                         FROM public.program_enrolment enl
                                  left join program_encounter pe
                                            on enl.id = pe.program_enrolment_id and pe.encounter_type_id = 1653
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
    last_modified_by_id     = (select id from users where username = 'nupoork@apfodisha'),
    manual_update_history   = 'Fixing missing high risk sync attributes'
FROM LatestEncounter le
WHERE enl.id = le.id
  AND le.rn = 1
  AND enl.observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
  and program_id =488;

-- 93 rows affected

set role apfodisha;

-- Query to update Child enrolment:
WITH LatestEncounter AS (SELECT pe.program_enrolment_id,
                                pe.observations -> 'be0ab05f-b0f3-43ec-b598-fdde0679104a'                                   AS high_risk_value,
                                ROW_NUMBER()
                                OVER (PARTITION BY pe.program_enrolment_id ORDER BY pe.encounter_date_time DESC NULLS LAST) AS rn
                         FROM public.program_encounter pe
                         WHERE pe.encounter_type_id = 1656)
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
    last_modified_by_id = (select id from users where username ='nupoork@apfodisha'),
    manual_update_history = 'Fixing missing high risk sync attributes'
FROM LatestEncounter le
WHERE enl.id = le.program_enrolment_id
  AND le.rn = 1
  AND enl.observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
  and program_id =489;
-- 220

------------------------------------------------------------------- Enrolment update end --------------------------------------------------------------------------------

------------------------------------------------------------------- Individual update --------------------------------------------------------------------------------

set role apfodisha;

select count(*)
from public.individual
join program_enrolment pe on individual.id = pe.individual_id
where subject_type_id = 672
AND individual.observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%'
;
-- 199
-- 188

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
    last_modified_by_id = (select id from users where username ='nupoork@apfodisha'),
    manual_update_history = 'Fixing missing high risk sync attributes'
FROM public.program_enrolment pe
WHERE ind.id = pe.individual_id
  AND subject_type_id = 672
  AND ind.observations::text not like '%be0ab05f-b0f3-43ec-b598-fdde0679104a%';
-- 187

------------------------------------------------------------------- Individual update end--------------------------------------------------------------------------------

------------------------------------------------------------------- Sync concpet1 value update --------------------------------------------------------------------------------


set role apfodisha;

select i.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a',pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a',pe.individual_id,pe.created_date_time,enc.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a',enc.created_date_time,enc.encounter_date_time
from public.individual i
join program_enrolment pe on i.id = pe.individual_id
join program_encounter enc on i.id = enc.individual_id
where i.sync_concept_1_value isnull and subject_type_id = 672 ;


select id,observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' ,sync_concept_1_value
from public.individual
WHERE subject_type_id = 672
and id in(
1431508,
1429614,
1429807,
1430067,
1430078
    )
;
-- 208





-- Query to update sync_concept_1_value column in the individual table
UPDATE public.individual
SET sync_concept_1_value =
        CASE
            WHEN observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '["a77bd700-1409-4d52-93bc-9fe32c0e169b"]'
                THEN 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            WHEN observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '["8ebbf088-f292-483e-9084-7de919ce67b7"]'
                THEN '8ebbf088-f292-483e-9084-7de919ce67b7'
            END,
    last_modified_date_time = now(),
    last_modified_by_id = (select id from users where username ='nupoork@apfodisha'),
    manual_update_history = 'Fixing missing high risk sync attributes'
WHERE subject_type_id = 672
  and sync_concept_1_value isnull;
--   AND observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' IS NOT NULL;
-- 187

set role apfodisha;

select observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a', '["' || sync_concept_1_value || '"]'
from public.program_enrolment
where
 observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' <> '["' || sync_concept_1_value || '"]'
 ;

select observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a',sync_concept_1_value
from public.individual
where subject_type_id = 672
and sync_concept_1_value isnull
and observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' is not null
;
-- 187

set role apfodisha;


select sync_concept_1_value
from program_enrolment
where
id in (
288602,
292580,
292285,
283626,
312886
    )
-- 734


set role apfodisha;
-- Query to update sync_concept_1_value column in the program enrolment table
UPDATE public.program_enrolment e
SET sync_concept_1_value = i.sync_concept_1_value,
    last_modified_date_time = current_timestamp + ( (e.id * 11) * interval '1 millisecond'),
    last_modified_by_id = (select id from users where username ='nupoork@apfodisha'),
    manual_update_history = 'Fixing missing high risk sync attributes'
FROM public.individual i
WHERE i.id = e.individual_id
  and subject_type_id = 672
  and e.sync_concept_1_value isnull
;
-- 546

-- 2,400
set role apfodisha;

select count(*)
from public.program_encounter pe
         join public.individual i on pe.individual_id = i.id and i.subject_type_id = 672
where pe.sync_concept_1_value isnull
;
-- 42,852

select count(*)
from public.program_encounter pe
where  pe.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a'  <> '["' || sync_concept_1_value || '"]'
;
-- 42,852

set role apfodisha;


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

select id,e.sync_concept_1_value, i.sync_concept_1_value
from program_encounter e
join public.individual i on e.individual_id = i.id
where e.sync_concept_1_value ;
-- 366



-- Query to update sync_concept_1_value column in the program encounter table
UPDATE public.program_encounter enc
SET sync_concept_1_value = i.sync_concept_1_value,
    last_modified_date_time = current_timestamp + ( (enc.id * 11) * interval '1 millisecond'),
    last_modified_by_id = (select id from users where username ='nupoork@apfodisha'),
    manual_update_history = 'Fixing missing high risk sync attributes'
FROM public.individual i
WHERE i.id = enc.individual_id
  and subject_type_id = 672
  and enc.sync_concept_1_value isnull
;
-- 366


select e.sync_concept_1_value,i.sync_concept_1_value
from program_encounter e
join public.individual i on e.individual_id = i.id
where i.subject_type_id = 672
and e.id in (
1686464,
2597864,
2597871,
2597179,
2597789
    )
;








------------------------------------------------------------------- Sync concpet1 value update end--------------------------------------------------------------------------------
