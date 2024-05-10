-- Data of new field  "Eligible for JSY Scheme?" to be added in the Delivery form based on already exisitng field in the encounter "JSY money received" as "Yes"
-- exisitng field in Delivery to be moved to 2nd PNC uuid "3b6e00e3-b931-40aa-8af1-4416f7336650" "JSY money received"
-- new field uuid in Delivery "1289b352-f8af-4fc8-bc55-f30681c08a60" "Eligible for JSY Scheme?"

set role apfodisha;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

select count(id)
from public.program_encounter
where encounter_type_id = (select id from encounter_type where name = 'Delivery')
  and (observations ->> '3b6e00e3-b931-40aa-8af1-4416f7336650')::text = '8ebbf088-f292-483e-9084-7de919ce67b7';

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- update query

begin transaction;

update public.program_encounter as delivery
SET observations = delivery.observations || jsonb_build_object('1289b352-f8af-4fc8-bc55-f30681c08a60',
                                                               delivery.observations ->
                                                               '3b6e00e3-b931-40aa-8af1-4416f7336650'),
    last_modified_date_time = current_timestamp + (random() * 5000 * (interval '1 millisecond')),
    last_modified_by_id = (select id from users where username = 'nupoork@apfodisha'),
    manual_update_history = append_manual_update_history(delivery.manual_update_history, 'Data migration from Delivery to Delivery for "Eligible for JSY Scheme?" based on "JSY money received" as "Yes"')

where  encounter_type_id = (select id from encounter_type where name = 'Delivery')
  and (observations ->> '3b6e00e3-b931-40aa-8af1-4416f7336650')::text = '8ebbf088-f292-483e-9084-7de919ce67b7'
  and is_voided = false;

rollback;
-- commit;



-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Data of field “JSY money received?” needs to be moved from Delivery form to the 2nd PNC
-- uuid "3b6e00e3-b931-40aa-8af1-4416f7336650"

set role apfodisha;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Select query to get the count of 2nd PNC which will be updated from the script
with pnc_data as (SELECT id,
                         program_enrolment_id,
                         observations,
                         ROW_NUMBER()
                         OVER (PARTITION BY pe.program_enrolment_id ORDER BY pe.earliest_visit_date_time asc NULLS LAST) AS visit_number
                  FROM public.program_encounter pe
                  WHERE pe.encounter_type_id = (SELECT id
                                                FROM encounter_type et
                                                WHERE et.name = 'PNC'
                                                  AND et.is_voided = false)
                    AND pe.encounter_date_time IS NOT NULL)
select count(pnc.id)
from public.program_encounter as pnc
         join public.program_encounter as delivery on pnc.program_enrolment_id = delivery.program_enrolment_id
         join pnc_data on pnc_data.id = pnc.id
where pnc_data.visit_number = 2
  and pnc.program_enrolment_id = delivery.program_enrolment_id
  and delivery.encounter_type_id = (select id from encounter_type where name = 'Delivery')
  and (delivery.observations -> '3b6e00e3-b931-40aa-8af1-4416f7336650') is not null;

-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- update query

begin transaction;

with pnc_data as (SELECT id,
                         program_enrolment_id,
                         observations,
                         ROW_NUMBER()
                         OVER (PARTITION BY pe.program_enrolment_id ORDER BY pe.earliest_visit_date_time asc NULLS LAST) AS visit_number
                  FROM public.program_encounter pe
                  WHERE pe.encounter_type_id = (SELECT id
                                                FROM encounter_type et
                                                WHERE et.name = 'PNC'
                                                  AND et.is_voided = false)
                    AND pe.encounter_date_time IS NOT NULL)
update public.program_encounter as pnc
SET observations = pnc.observations || jsonb_build_object('3b6e00e3-b931-40aa-8af1-4416f7336650',
                                                          delivery.observations ->
                                                          '3b6e00e3-b931-40aa-8af1-4416f7336650'),
    last_modified_date_time = current_timestamp + (random() * 5000 * (interval '1 millisecond')),
    last_modified_by_id = (select id from users where username = 'nupoork@apfodisha'),
    manual_update_history = append_manual_update_history(pnc.manual_update_history, 'Data migration from Delivery form to 2nd PNC #Phase 2')
from public.program_encounter as delivery
         join pnc_data on pnc_data.program_enrolment_id = delivery.program_enrolment_id
where pnc_data.visit_number = 2
  and pnc.id = pnc_data.id
  and delivery.encounter_type_id = (select id from encounter_type where name = 'Delivery')
  and (delivery.observations -> '3b6e00e3-b931-40aa-8af1-4416f7336650') is not null;


rollback;
-- commit;
