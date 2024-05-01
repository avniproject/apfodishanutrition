Data of two questions needs to be migrated from individual registration form to Pregnancy Enrolment Form. In case a women is enrolled multiple times into the Pregnancy Program, we need to take the latest data of the women for migration.

2 Questions concept name with uuid's:
which trimster -> 'faa2d09f-6dd8-45ca-99ae-57fb2685abdd'
Is the beneficiary registered in the AWC? -> '8d8a4d13-515a-4f3c-ac7e-04d22fd4782a'

Note: Change the last_modified_by_id before 

---------------------------------------------------------------------------------------------------------------------------------------------------------------------

set role apfodisha;

with pregnancy_enrolments as (
    select 
        pe.id as pe_id,
        pe.individual_id,
        i.observations as ind_observation,
        pe.observations as pe_obs,
        pe.enrolment_date_time,
        row_number() over (partition by pe.individual_id order by pe.enrolment_date_time desc) as latest_enrolment
    from 
        individual i 
    join program_enrolment pe on 
        pe.individual_id = i.id 
        and pe.program_exit_date_time is null 
        and pe.is_voided = false
    join "program" p on 
        p.id = pe.program_id 
        and p.name = 'Pregnancy' 
        and p.is_voided = false
    where 
        i.is_voided = false
)
update program_enrolment pe
set observations = pe.observations || jsonb_build_object('faa2d09f-6dd8-45ca-99ae-57fb2685abdd', preg_enrol.ind_observation -> 'faa2d09f-6dd8-45ca-99ae-57fb2685abdd') || jsonb_build_object('8d8a4d13-515a-4f3c-ac7e-04d22fd4782a', preg_enrol.ind_observation -> '8d8a4d13-515a-4f3c-ac7e-04d22fd4782a'),
	last_modified_date_time = current_timestamp + ((pe.id % 1000) * interval '1 millisecond'),
	last_modified_by_id = 10917,
	manual_update_history = append_manual_update_history(pe.manual_update_history, ' Migrating which trimester and Is the beneficiary registered in the AWC? from registration to pregnancy enrollment as per card #245')
from pregnancy_enrolments preg_enrol
where
    preg_enrol.pe_id = pe.id
    and preg_enrol.latest_enrolment = 1;