-- 1. set all individual observation and sync_concept_1_value as no

--    for pregnancy 
-- 2. set program_enrolment observation and sync_concept_1_value based on high risk condition
-- 3. set individual observation and sync_concept_1_value based on program_enrolment
-- 4. set program_encounter observation and sync_concept_1_value based on high risk condition
-- 5. set individual observation and sync_concept_1_value based on latest encounter
-- 6. set program_enrolment observation and sync_concept_1_value based on individual
-- 7. set program_encounter observation and sync_concept_1_value based on program_enrolment

--    for child
-- 8. set program_enrollment observation and sync_concept_1 value as no
-- 9. set program_encounter observation and sync_concept_1_value based on high risk condition
-- 10. set program_enrolment observation and sync_concept_1_value based on lastest encounter
-- 11. set individual observation and sync_concept_1_value based on lastest encounter
-- 12. set program_encounter observation and  sync_concept_1_value based on program_enrollment

-- 13. set group_subject table sync_concept_1_value based on memeber

-- 1. set all individual observation and sync_concept_1_value as no
-- High risk as "No" for all individual subject types on registration
update individual
set observations            = observations ||
                              '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}', -- No
    sync_concept_1_value    = 'a77bd700-1409-4d52-93bc-9fe32c0e169b',                                              -- No
    last_modified_date_time = current_timestamp + interval '1 millisecond',
    last_modified_by_id     = (select id from users where username = 'beulah@apfodishauat'),
    manual_update_history   = 'High risk as "No" for all individual subject types on registration'
where organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and subject_type_id = (select id from public.subject_type st where  name = 'Individual' );

select
    id,
    observations->>'be0ab05f-b0f3-43ec-b598-fdde0679104a',
    sync_concept_1_value,   
    last_modified_date_time, 
    last_modified_by_id,     
    manual_update_history   
from public.individual ind
where organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and subject_type_id = (select id from public.subject_type st where  name = 'Individual' )
  and observations->>'be0ab05f-b0f3-43ec-b598-fdde0679104a' notnull and sync_concept_1_value notnull;


-- 2. set program_enrolment observation and sync_concept_1_value based on high risk condition
-- High risk as "Yes/No" for all the program enrolments(Pregnancy program) based on the checkpoint(MCP red flag)
update public.program_enrolment
set observations          =
        case
            when observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' = '8ebbf088-f292-483e-9084-7de919ce67b7'-- Red Flag (refer MCP card) - yes -> high risk - yes
                then observations ||
                     '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["b9b4ac92-2aea-43d0-9d1c-bc7fd5026c44"]}'
            end,
    sync_concept_1_value  =
        case
            when observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' = '8ebbf088-f292-483e-9084-7de919ce67b7'
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            else 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            end,
    last_modified_by_id   = (select id from public.users where username = 'beulah@apfodishauat'),
    manual_update_history = 'updating program_enrolment table based on checkpoint(MCP red flag)'
where organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and program_id = (select id from public."program" p where name = 'Pregnancy');
 
 
select id,
observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' as Red_Flag,
observations ->> '9a7f284b-251d-459b-97d9-929ed280b3d3' as High_risk_condition,
sync_concept_1_value 
from public.program_enrolment pe 
where organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and program_id = (select id from public."program" p where name = 'Pregnancy');


-- 3. set individual observation and sync_concept_1_value based on program_enrolment
-- High risk as "Yes/No" for all the individual subjects based on the conditions if any high risk condition exist on its corresponding program enrolment (Pregnancy program)

update public.individual ind
set observations          =
        case
            when pe.observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' = '8ebbf088-f292-483e-9084-7de919ce67b7'
                then observations ||
                     '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'
            else observations ||
                 '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
            end,
    sync_concept_1_value  =
        case
            when pe.observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' = '8ebbf088-f292-483e-9084-7de919ce67b7'
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            else 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            end,
    last_modified_by_id   = (select id from users where username = 'beulah@apfodishauat'),
    manual_update_history = 'updating individual table based on checkpoint(MCP red flag) of pregnancy program'
from public.program_enrolment pe
where pe.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and program_id = (select id from public."program" p where name = 'Pregnancy')
  and pe.individual_id = ind.id;
 
 
select
    ind.id,
    ind.observations->>'be0ab05f-b0f3-43ec-b598-fdde0679104a' as high_risk,
    pe.observations->>'9a7f284b-251d-459b-97d9-929ed280b3d3'as high_risk_condition,
    ind.sync_concept_1_value,
    pe.sync_concept_1_value,
    ind.manual_update_history   
from public.individual ind
join public.program_enrolment pe on pe.individual_id = ind.id
where ind.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and subject_type_id = (select id from public.subject_type st where  name = 'Individual' );


-- 4. set program_encounter observation and sync_concept_1_value based on high risk condition
-- High risk as "Yes/No" for all program_encounter (Pregnancy program) based on checkpoints (Weight is less than 37kg, Height is less than 147cm, Red flag as per MCP card, Gravida is more than or equal to 4, Age is greater than 35 years, HB is less than 7 g/dL, Geographical high risk, High risk condition exist)
update program_encounter enc
set observations          =
        case
            when (enc.observations ->> '3981ddb0-30a3-43d2-9564-16ae9cc0e25e')::numeric < 37        -- weight of women  in encounter
                then enc.observations ||
                     '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["ee723b88-6094-40b2-8db2-16368ae66f4c"]}'
            when (enl.observations ->> 'a0059121-6bd2-414b-bcdc-a64bf27bc364')::numeric < 148        -- height of women in enrolment
                then enc.observations ||
                     '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["3f36ab23-e475-48d9-9bf9-556cab575303"]}'
            when enl.observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' = '8ebbf088-f292-483e-9084-7de919ce67b7'     -- Red Flag (refer MCP card) in enrolment
                then enc.observations ||
                     '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["b9b4ac92-2aea-43d0-9d1c-bc7fd5026c44"]}' 
            when (enl.observations ->> 'c49442e4-539f-4d73-9590-0deb8c8dd3b9')::numeric >= 4  -- Gravida (the number of pregnancies the woman has had) in enrolment
                then enc.observations ||
                     '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["5a33dde5-f5f4-49ff-acc1-3d7ede26dc52"]}'
            when ind.age >= 35                                                                   -- age grater than 35
                then enc.observations ||
                     '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["ad71b3c0-4d95-4f2b-892c-75ab40cf6442"]}'
            when (enc.observations ->> '68bc6e51-eb49-4816-b78b-2427bbab8d92')::numeric < 7   -- HB in encounter
                then enc.observations ||
                     '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["6e277f82-5822-4ac3-8a5a-d1ad21a79c00"]}'
            when enc.observations ->> '96b167e1-2d98-40b9-af04-8e4f64f9999a' = '8ebbf088-f292-483e-9084-7de919ce67b7' -- Pregnancy geographically high risk in encounter
                then enc.observations ||
                     '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["3e21a6f4-6727-44b3-9b7e-148ce9ad77fd"]}'
            -- else enc.observations ||
            --      '{"9a7f284b-251d-459b-97d9-929ed280b3d3":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
            end,
    sync_concept_1_value  =
        case
            when (enc.observations ->> '3981ddb0-30a3-43d2-9564-16ae9cc0e25e')::numeric < 37
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            when (enl.observations ->> 'a0059121-6bd2-414b-bcdc-a64bf27bc364')::numeric < 148
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            when enl.observations ->> '72f8785c-f064-4549-ab45-47defa40f5fb' = '8ebbf088-f292-483e-9084-7de919ce67b7'
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            when (enl.observations ->> 'c49442e4-539f-4d73-9590-0deb8c8dd3b9')::numeric >= 4
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            when ind.age >= 35
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            when (enc.observations ->> '68bc6e51-eb49-4816-b78b-2427bbab8d92')::numeric < 7
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            when enc.observations ->> '96b167e1-2d98-40b9-af04-8e4f64f9999a' = '8ebbf088-f292-483e-9084-7de919ce67b7'
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            when jsonb_exists(enc.observations, '9a7f284b-251d-459b-97d9-929ed280b3d3')
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            else 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            end,
    last_modified_by_id   = (select id from users where username = 'beulah@apfodishauat'),
    manual_update_history = 'updating program_encounter table based on checkpoints (Weight is less than 37kg, Height is less than 147cm, Red flag as per MCP card, Gravida is more than or equal to 4, Age is greater than 35 years, HB is less than 7 g/dL, Geographical high risk, High risk condition exist)'
from program_enrolment enl
join public.individual on ind.id = enc.individual_id 
where enl.individual_id = enc.individual_id
  and enc.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and encounter_type_id = (select id from public.encounter_type et where name = 'ANC' and organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1) );
  

select enc.id,enc.observations->>'9a7f284b-251d-459b-97d9-929ed280b3d3' as High_risk_condition, 
     enc.sync_concept_1_value   
from public.program_encounter enc 
join public.program_enrolment enl on enc.program_enrolment_id = enl.id 
join public.individual ind on ind.id  = enl.individual_id 
where enc.encounter_type_id  = (select id from public.encounter_type et where name = 'ANC' and organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1) )
and enc.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1); -- 1124


-- 5. set individual observation and sync_concept_1_value based on latest encounter
-- High risk as "Yes/No" for all the individual subjects(Pregnancy program) based on checkpoints (Weight is less than 37kg, Height is less than 147cm, Red flag as per MCP card, Gravida is more than or equal to 4, Age is greater than 35 years, HB is less than 7 g/dL, Geographical high risk, High risk condition exist)
with encountering as (select pe.individual_id,
                             row_number()
                             over (partition by pe.individual_id order by pe.encounter_date_time desc nulls last) visit,
                             pe.program_enrolment_id,
                             pe.observations -> '9a7f284b-251d-459b-97d9-929ed280b3d3'                           obsvalue,
                             sync_concept_1_value
                      from program_encounter pe
                      where pe.encounter_type_id = (select id from public.encounter_type et where name = 'ANC' and organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1) )
                        and pe.organisation_id =(select id from public.organisation o where name = 'APF Odisha UAT' limit 1)  )
update individual ind
set observations          = case when jsonb_array_length(obsvalue) > 0   
                                    then  observations ||
                                        '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'
                                    else  observations ||
                                        '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
    sync_concept_1_value  = enc.sync_concept_1_value,
    manual_update_history = 'updating individual table based on checkpoints (Weight is less than 37kg, Height is less than 147cm, Red flag as per MCP card, Gravida is more than or equal to 4, Age is greater than 35 years, HB is less than 7 g/dL, Geographical high risk, High risk condition exist)',
    last_modified_by_id   = (select id from users where username = 'beulah@apfodishauat')
from encountering enc
where ind.id = enc.individual_id
  and ind.subject_type_id = (select id from public.subject_type st where  name = 'Individual' )
  and ind.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and visit = 1;


 
with encountering as (select pe.individual_id,
                             row_number()
                             over (partition by pe.individual_id order by pe.encounter_date_time desc nulls last) visit,
                             pe.program_enrolment_id,
                             pe.observations -> '9a7f284b-251d-459b-97d9-929ed280b3d3'                           obsvalue,
                             sync_concept_1_value
                      from program_encounter pe
                      where pe.encounter_type_id = (select id from public.encounter_type et where name = 'ANC' and organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1) )
                        and pe.organisation_id =(select id from public.organisation o where name = 'APF Odisha UAT' limit 1)  )
select ind.id,
       ind.observations->>'be0ab05f-b0f3-43ec-b598-fdde0679104a',
       obsvalue,
       ind.sync_concept_1_value,
       ind.manual_update_history,
       ind.last_modified_date_time 
from public.individual ind
join encountering enc
on ind.id = enc.individual_id
where ind.subject_type_id = (select id from public.subject_type st where  name = 'Individual' )
  and ind.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and visit = 1;


-- 6. set program_enrolment observation and sync_concept_1_value based on individual
update public.program_enrolment pe 
set 
    -- observations = JSONB_SET(pe.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', ind.observations->>'be0ab05f-b0f3-43ec-b598-fdde0679104a'::jsonb),
    sync_concept_1_value = ind.sync_concept_1_value
    last_modified_date_time = current_timestamp + interval '1 millisecond',
    last_modified_by_id     = (select id from users where username = 'beulah@apfodishauat'), 
    manual_update_history = 'changed observation and sync_concept_1_value based on individuals',
from public.individual ind
where 
    pe.individual_id = ind.id
and pe.program_id = (select id from public."program" p where name = 'Pregnancy')
and pe.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)

select * from public.program_enrolment pe 
join public.individual i
where i.id = pe.individual_id 
and pe.program_id = (select id from public."program" p where name = 'Pregnancy')
and pe.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)



-- 7. set program_encounter observation and sync_concept_1_value based on program_enrolment
update public.program_encounter  enc 
set 
    -- observations = JSONB_SET(enc.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', enl.observations->>'be0ab05f-b0f3-43ec-b598-fdde0679104a'::jsonb),
    sync_concept_1_value = enl.sync_concept_1_value,
    last_modified_date_time = current_timestamp + interval '1 millisecond',
    last_modified_by_id     = (select id from users where username = 'beulah@apfodishauat'), 
    manual_update_history = 'changed observation and sync_concept_1_value based on individuals',
from public.program_enrolment enl
where 
    enl.id = enc.program_enrolment_id 
and enl.program_id = (select id from public."program" p where name = 'Pregnancy')
and enc.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)

select * from public.program_encounter  enc
join public.program_enrolment enl 
on enc.program_enrolment_id  = enl.id
where enl.program_id = (select id from public."program" p where name = 'Pregnancy')
and enc.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)


-- child
-- 8. set program_enrollment observation and sync_concept_1 value as no
update public.program_enrolment
set 
    -- observations          = observations ||
    --                         '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}', -- No
    sync_concept_1_value  = 'a77bd700-1409-4d52-93bc-9fe32c0e169b',                                              -- No
    manual_update_history = 'High risk as "No" for all program enrolments (child program)',
    last_modified_by_id   = (select id from users where username = 'beulah@apfodishauat')
where program_id = (select id from public."program" p where name = 'Child')
  and organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1);  

 
select * from public.program_enrolment pe 
where program_id = (select id from public."program" p where name = 'Child')
  and organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1);  


-- 9. set program_encounter observation and sync_concept_1_value based on high risk condition
update program_encounter pe
set observations          =
        case
            when pe.observations ->> 'efeb0a0b-aea4-4af1-9bc4-37d86bc865a1' = '["4b855734-921c-4796-a752-39b3ede1c66c"]' -- Weight for age Status
                then observations ||
                     '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'
            when pe.observations ->> '2a2027c1-cec9-4237-a53a-80d6b1047979' = '["7d0229c1-e69e-4cac-8937-cdd48c8ed9dd"]'  -- Weight for Height Status
                then observations ||
                     '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'
            else observations ||
                 '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
            end,
    sync_concept_1_value  =
        case
            when pe.observations ->> 'efeb0a0b-aea4-4af1-9bc4-37d86bc865a1' = '["4b855734-921c-4796-a752-39b3ede1c66c"]'
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            when pe.observations ->> '2a2027c1-cec9-4237-a53a-80d6b1047979' = '["7d0229c1-e69e-4cac-8937-cdd48c8ed9dd"]'
                then '8ebbf088-f292-483e-9084-7de919ce67b7'
            else 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            end,
    last_modified_by_id   = (select id from users where username = 'beulah@apfodishauat'),
    manual_update_history = 'updating program_encounter table based on checkpoint(Weight for Height Status, Weight for age Status)'
where organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1); 
  
 
select pe.id,
pe.observations->>'efeb0a0b-aea4-4af1-9bc4-37d86bc865a1' as Weight_for_age_Status,
pe.observations->> '2a2027c1-cec9-4237-a53a-80d6b1047979'as Weight_for_Height_Status,
pe.observations->>'be0ab05f-b0f3-43ec-b598-fdde0679104a' as high_risk,
pe.sync_concept_1_value
from program_encounter pe
where organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
  and observations->>'efeb0a0b-aea4-4af1-9bc4-37d86bc865a1'= '["422604be-5776-4050-a779-9221935d6f7c"]'; 



-- 10. set program_enrolment observation and sync_concept_1_value based on lastest encounter
with encountering as (select pe.individual_id,
                             row_number()
                             over (partition by pe.individual_id order by pe.encounter_date_time desc nulls last) visit,
                             pe.program_enrolment_id,
                             pe.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a'                           obsvalue,
                             sync_concept_1_value
                      from program_encounter pe
                      where pe.encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
                        and pe.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1))
update program_enrolment enl
set observations          = JSONB_SET(enl.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', obsvalue::jsonb),
    sync_concept_1_value  = enc.sync_concept_1_value,
    manual_update_history = 'updating program_enrolment table based on checkpoints (Weight for Height Status, Weight for age Status)',
    last_modified_by_id   = (select id from users where username = 'beulah@apfodishauat')
from encountering enc
where enl.id = enc.program_enrolment_id
  and enl.program_id = (select id from public."program" p where name = 'Child')
  and enl.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and visit = 1;
 
with encountering as (select pe.individual_id,
                             row_number()
                             over (partition by pe.individual_id order by pe.encounter_date_time desc nulls last) visit,
                             pe.program_enrolment_id,
                             pe.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a'                           obsvalue,
                             sync_concept_1_value
                      from public.program_encounter pe
                      where pe.encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
                        and pe.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1))
select 
    enl.id, 
    enl.observations,          
    enl.sync_concept_1_value,
    enc.sync_concept_1_value,
    enl.manual_update_history, 
    enl.last_modified_by_id
from public.program_enrolment enl
join encountering enc on enl.id = enc.program_enrolment_id
where enl.program_id = (select id from public."program" p where name = 'Child')
  and enl.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and visit = 1;


-- 11. set individual observation and sync_concept_1_value based on lastest encounter
with encountering as (select pe.individual_id,
                             row_number()
                             over (partition by pe.individual_id order by pe.encounter_date_time desc nulls last) visit,
                             pe.program_enrolment_id,
                             pe.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a'                           obsvalue,
                             sync_concept_1_value
                      from program_encounter pe
                      where pe.encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
                        and pe.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1))
update public.individual  ind
set observations          = JSONB_SET(ind.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', obsvalue::jsonb),
    sync_concept_1_value  = enc.sync_concept_1_value,
    manual_update_history = 'updating program_enrolment table based on checkpoints (Weight for Height Status, Weight for age Status)',
    last_modified_by_id   = (select id from users where username = 'beulah@apfodishauat')
from encountering enc
where ind.id = enc.individual_id
  and ind.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and visit = 1;
 
with encountering as (select pe.individual_id,
                             row_number()
                             over (partition by pe.individual_id order by pe.encounter_date_time desc nulls last) visit,
                             pe.program_enrolment_id,
                             pe.observations ->> 'be0ab05f-b0f3-43ec-b598-fdde0679104a'                           obsvalue,
                             sync_concept_1_value
                      from public.program_encounter pe
                      where pe.encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
                        and pe.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1))
select 
    ind.id, 
    ind.observations,          
    ind.sync_concept_1_value,
    enc.sync_concept_1_value,
    ind.manual_update_history, 
    ind.last_modified_by_id
from public.individual ind
join encountering enc on ind.id = enc.individual_id
where ind.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
  and visit = 1;


-- 12. set program_encounter observation and  sync_concept_1_value based on program_enrollment
update public.program_encounter  enc 
set observations = JSONB_SET(enc.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', enl.observations->>'be0ab05f-b0f3-43ec-b598-fdde0679104a'::jsonb),
    sync_concept_1_value = enl.sync_concept_1_value
    last_modified_date_time = current_timestamp + interval '1 millisecond',
    last_modified_by_id     = (select id from users where username = 'beulah@apfodishauat'), 
    manual_update_history = 'changed observation and sync_concept_1_value based on individuals',
from public.program_enrolment enl
where 
    enl.id = enc.program_enrolment_id 
and enl.program_id = (select id from public."program" p where name = 'Child')
and enc.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)

select * from public.program_encounter  enc
join public.program_enrolment enl 
on enc.program_enrolment_id  = enl.id
where enl.program_id = (select id from public."program" p where name = 'Child')
and enc.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)



-- 13. set group_subject table sync_concept_1_value based on memeber
update public.group_subject gs
set group_subject_sync_concept_1_value = ind.sync_concept_1_value,
    last_modified_by_id  =   (select id from users where username = 'beulah@apfodishauat')
from public.individual ind
where gs.member_subject_id = ind.id 
and gs.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
and ind.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1);


select gs.id,gs.member_subject_id,ind.id,ind.sync_concept_1_value,gs.group_subject_sync_concept_1_value from public.group_subject gs
join public.individual ind on ind.id = gs.member_subject_id  
where gs.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1)
and ind.organisation_id = (select id from public.organisation o where name = 'APF Odisha UAT' limit 1);
