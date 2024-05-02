set role apfodisha;
with pnc_data as (SELECT id,
                         program_enrolment_id,
                         observations,
                         ROW_NUMBER()
                         OVER (PARTITION BY pe.individual_id ORDER BY pe.earliest_visit_date_time asc NULLS LAST) AS visit_number
                  FROM public.program_encounter pe
                  WHERE pe.encounter_type_id = (SELECT id
                                                FROM encounter_type et
                                                WHERE et.name = 'PNC'
                                                  AND et.is_voided = false)
                    AND pe.encounter_date_time IS NOT NULL)
update public.program_encounter as pnc
SET pnc.observations = pnc.observations || jsonb_build_object('3b6e00e3-b931-40aa-8af1-4416f7336650',
                                                              delivery.observations ->
                                                              '3b6e00e3-b931-40aa-8af1-4416f7336650'),
    manual_update_history = 'Data migration from Delivery form to 2nd PNC #Phase 2'
from public.program_encounter as delivery
         join pnc_data on pnc_data.id = pnc.id
where pnc_data.visit_number = 2
  and pnc.program_enrolment_id = delivery.program_enrolment_id
  and delivery.encounter_type_id = (select id from encounter_type where name = 'Delivery')
  and (delivery.observations -> '3b6e00e3-b931-40aa-8af1-4416f7336650') is not null;
