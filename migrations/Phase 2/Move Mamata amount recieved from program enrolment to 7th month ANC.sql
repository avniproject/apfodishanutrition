-- 5c3712c1-f570-4ce6-b5ed-c91e9088ef98 move this from program enrolment to 7th month ANC -->
-- "Have you received first installment of Mamata scheme amount? "a1012f45-fb96-4bd0-94cb-2714065e4367

set role apfodisha;

begin transaction;

with anc_data as (SELECT pe.id,
                         pe.program_enrolment_id,
                         pe.observations,
                         pe.earliest_visit_date_time,
                         ROW_NUMBER()
                         OVER (PARTITION BY pe.program_enrolment_id ORDER BY pe.earliest_visit_date_time asc NULLS LAST) AS visit_number
                  FROM public.program_encounter pe
                           left join program_enrolment p on pe.program_enrolment_id = p.id
                  WHERE pe.encounter_type_id = (SELECT id
                                                FROM encounter_type et
                                                WHERE et.name = 'ANC'
                                                  AND et.is_voided = false)
                    and EXTRACT(MONTH FROM (p.observations ->> '2664c7be-7467-4304-811f-d9d20dcd7eae')::date +
                                           INTERVAL '6 months') = EXTRACT(MONTH FROM pe.earliest_visit_date_time)
                    and pe.encounter_date_time IS NOT NULL)

update public.program_encounter anc
set observations = anc.observations || jsonb_build_object('a1012f45-fb96-4bd0-94cb-2714065e4367',
                                                              p.observations ->
                                                              '5c3712c1-f570-4ce6-b5ed-c91e9088ef98'),
    last_modified_date_time = current_timestamp + (random() * 5000 * (interval '1 millisecond')),
	  last_modified_by_id = (select id from users where username = 'nupoork@apfodisha'),
	  manual_update_history = append_manual_update_history(pnc.manual_update_history, 'Data migration from program enrolment to 7th Month ANC')
  
from public.program_enrolment as p
         left join anc_data on anc_data.id = anc.id
where anc_data.visit_number = 1
  and anc.program_enrolment_id = p.id
  and p.program_id = (select id from program where name = 'Pregnancy')
  and (p.observations -> '5c3712c1-f570-4ce6-b5ed-c91e9088ef98') is not null;

rollback;
-- commit;
