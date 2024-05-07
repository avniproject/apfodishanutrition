-- QRT Child: One question needs to be changed and the data needs to be migrated to newly added advice question. 
-- The question " Reffered to NRC?" is removed and a new question is added "Advice" . 
-- So all the "Yes" option selected in the "Refer to NRC" question, now needs to be shown as " Refered to NRC" under the Advice question

-- Concepts:
-- Reffered to NRC (referred by govt facility)-> '45113644-225c-43e9-8e31-b103732ea671'
-- Yes -> '8ebbf088-f292-483e-9084-7de919ce67b7'
-- Referral advice/ Advice given -> '4e04b445-61ff-45de-a48a-3b2fb362e2a6'
-- Referred to NRC -> 'a5e087e8-7ffa-4a0a-a4c0-d42579612e9c' ---- New Option

--Note: 
--1. Change the last_modified_by_id before running the script
--2. Change the program_id and encounter_type_id since they were taken from prerelease.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Select Query
set role apfodisha;

select id from program p where p.name = 'Child' and p.is_voided = false; -- 489

select id from encounter_type et where et.name = 'QRT Child' and et.is_voided = false; -- 1660

select
	* 
from 
	program_encounter prog_enc
where 
	prog_enc.cancel_date_time is null
	and prog_enc.is_voided = false 
	and prog_enc.encounter_date_time is not null
	and prog_enc.encounter_type_id = 1660
	and (prog_enc.observations -> '45113644-225c-43e9-8e31-b103732ea671')::TEXT = '"8ebbf088-f292-483e-9084-7de919ce67b7"';


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Update Query
begin transaction;

set role apfodisha;

select id from program p where p.name = 'Child' and p.is_voided = false; -- 489

select id from encounter_type et where et.name = 'QRT Child' and et.is_voided = false; -- 1660

update program_encounter prog_enc
set observations = prog_enc.observations || jsonb_build_object('4e04b445-61ff-45de-a48a-3b2fb362e2a6', 'a5e087e8-7ffa-4a0a-a4c0-d42579612e9c'),
	last_modified_date_time = current_timestamp + (random() * 5000 * (interval '1 millisecond')),
	last_modified_by_id = 10917,
	manual_update_history = append_manual_update_history(prog_enc.manual_update_history, ' Migrating newly added advice as per card #249')
where prog_enc.cancel_date_time is null
	and prog_enc.is_voided = false 
	and prog_enc.encounter_date_time is not null
	and prog_enc.encounter_type_id = 1660
	and (prog_enc.observations -> '45113644-225c-43e9-8e31-b103732ea671')::TEXT = '"8ebbf088-f292-483e-9084-7de919ce67b7"';

rollback;
-- commit;
