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





