set role apfodisha;

-- 1. Program encounters - If there is a non-empty array on encounter type 'ANC' for concept ""High risk" Conditions", then add an observation ""High risk"" = "yes". If not, add ""High risk"" = no.
--                         If for child Weight for Height Status == "SAM" or  Weight for age Status == "Severely Underweight", then add an observation ""High risk"" = "yes". If not, add ""High risk"" = no.

-- for pregnancy
update public.program_encounter pe
set observations =
           case when pe.observations->'9a7f284b-251d-459b-97d9-929ed280b3d3' notnull and pe.observations->'9a7f284b-251d-459b-97d9-929ed280b3d3' != '[]' then              -- high risk condition
             observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'   -- high risk  yes
           else
             observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'   -- high risk no
           end,
     manual_update_history = 'set high risk based on high risk conition'
where pe.encounter_type_id = (select id from public.encounter_type et where name = 'ANC' limit 1)
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and pe.encounter_date_time is not null;
-- 13,816

select count(*),count(*) filter(where pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '["8ebbf088-f292-483e-9084-7de919ce67b7"]')
from public.program_encounter pe
where pe.encounter_type_id = (select id from public.encounter_type et where name = 'ANC' limit 1)
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and pe.observations->'9a7f284b-251d-459b-97d9-929ed280b3d3' notnull and pe.observations->'9a7f284b-251d-459b-97d9-929ed280b3d3' != '[]'
and pe.encounter_date_time is not null;
-- 5623


select count(*) filter(where pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '["a77bd700-1409-4d52-93bc-9fe32c0e169b"]')
from public.program_encounter pe
where pe.encounter_type_id = (select id from public.encounter_type et where name = 'ANC' limit 1)
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and pe.encounter_date_time is not null
;
-- 8193

-- for child

update public.program_encounter pe
set observations =
           case
           	  when pe.observations->'efeb0a0b-aea4-4af1-9bc4-37d86bc865a1'  = '["4b855734-921c-4796-a752-39b3ede1c66c"]'or   -- Weight for age Status as Severely Underweight
           	       pe.observations->'2a2027c1-cec9-4237-a53a-80d6b1047979' = '["7d0229c1-e69e-4cac-8937-cdd48c8ed9dd"]'  -- Weight for Height Status as SAM
           	  then
           	      observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'
              else
                  observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
           end,
     manual_update_history = 'set high risk based on Weight for Height Status and Weight for age Status'
where pe.encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and pe.encounter_date_time is not null;


select count(*) 
from public.program_encounter pe
where pe.encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and (pe.observations->'efeb0a0b-aea4-4af1-9bc4-37d86bc865a1'  = '["4b855734-921c-4796-a752-39b3ede1c66c"]'
or  pe.observations->'2a2027c1-cec9-4237-a53a-80d6b1047979' = '["7d0229c1-e69e-4cac-8937-cdd48c8ed9dd"]')
and pe.encounter_date_time is not null;
-- 12,758

select count(*),count(*)filter(where pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '["a77bd700-1409-4d52-93bc-9fe32c0e169b"]') as "No",
count(*)filter(where pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '["8ebbf088-f292-483e-9084-7de919ce67b7"]')  as "Yes"
from public.program_encounter pe
where pe.encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and pe.encounter_date_time is not null;
-- 186130

-- 2. Program enrolment - Populate the latest (by encounter date time) value of "High risk" in program encounters of type ANC to the program enrolment
--                        for child take child Followup

-- for pregnancy and for child
with encounters as(
	select
	    pe.observations,
	    pe.program_enrolment_id,
	    row_number() over (partition by pe.individual_id order by pe.encounter_date_time desc nulls last) visit
	from public.program_encounter pe
	where pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
	and pe.encounter_type_id = (select id from public.encounter_type et where name = 'ANC' limit 1)
	and pe.encounter_date_time is not null
)
update public.program_enrolment enl
set observations = enl.observations || JSONB_SET(enl.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', enc.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a'),
    manual_update_history = 'set high risk based on program encounter'
from encounters enc
where enl.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and visit = 1
and enc.program_enrolment_id = enl.id ;
-- 51288, 6974


with encounters as(
	select
	    pe.observations,
	    pe.program_enrolment_id,
	    row_number() over (partition by pe.individual_id order by pe.encounter_date_time desc nulls last) visit
	from public.program_encounter pe
	where pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
	and pe.encounter_type_id = (select id from public.encounter_type et where name = 'Child followup' limit 1)
	and pe.encounter_date_time is not null
)
update public.program_enrolment enl
set observations = enl.observations || JSONB_SET(enl.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', enc.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a'),
    manual_update_history = 'set high risk based on program encounter'
from encounters enc
where enl.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and visit = 1
and enc.program_enrolment_id = enl.id ;



select * from public.program_enrolment pe
where pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' notnull
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and (pe.program_id =(select id from public."program" p where name = 'Child' limit 1)
     or pe.program_id =(select id from public."program" p where name = 'Pregnancy' limit 1) );



-- 3. Program enrolment - If "High risk" not set for it then set as "High risk" no by default

-- for child
update public.program_enrolment pe
set observations = pe.observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
where pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and (pe.observations-> 'be0ab05f-b0f3-43ec-b598-fdde0679104a' is null or pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '[]'   ) 
and pe.program_id =(select id from public."program" p where name = 'Child')
and pe.enrolment_date_time is not null;
-- 214


-- for pregnancy
update public.program_enrolment pe
set observations = pe.observations ||  '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'   
where pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
 and  pe.program_id =(select id from public."program" p where name = 'Pregnancy')
 and  (observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' is null and observations->'9a7f284b-251d-459b-97d9-929ed280b3d3' = '["b9b4ac92-2aea-43d0-9d1c-bc7fd5026c44"]')
 and pe.enrolment_date_time is not null ; -- red flag per mcp card


update public.program_enrolment pe
set observations = pe.observations ||  '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
where pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
 and  pe.program_id =(select id from public."program" p where name = 'Pregnancy')
 and  observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' is null 
 and pe.enrolment_date_time is not null;



--update public.program_enrolment pe
--set observations =
--       case when observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' is null and observations->'9a7f284b-251d-459b-97d9-929ed280b3d3' = '["b9b4ac92-2aea-43d0-9d1c-bc7fd5026c44"]' then
--             	 pe.observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["8ebbf088-f292-483e-9084-7de919ce67b7"]}'
--            when observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' is null then
--                 pe.observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}'
--        end,
--        manual_update_history = 'set default high risk as no'
--where pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
--and  pe.program_id =(select id from public."program" p where name = 'Pregnancy') ;
-- 6979



select count(*) from public.program_enrolment pe
where (pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' is  null or pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '[]')
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and  pe.program_id =(select id from public."program" p where name = 'Child' limit 1)
and pe.enrolment_date_time is not null
;


select count(*) from public.program_enrolment pe
where (pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' is  null or pe.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '[]')
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and  pe.program_id =(select id from public."program" p where name = 'Pregnancy' limit 1)
and pe.enrolment_date_time is not null
;






-- 214


-- 4. Individual - Populate the latest (by enrolment date time) value of "High risk" from program enrolment into observations of registration

with enrolment as(
	select pe.individual_id,
	       pe.observations,
	       row_number() over (partition by pe.individual_id order by pe.enrolment_date_time  desc nulls last) visit
	from public.program_enrolment pe
    where
	     pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
		and pe.program_id =(select id from public."program" p where name = 'Child')
		and pe.enrolment_date_time is not null    
)
update public.individual ind
set observations = ind.observations || JSONB_SET(ind.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', enl.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a'),
    manual_update_history = 'set high risk based on enrolment'
from enrolment enl
where enl.individual_id = ind.id
and ind.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and visit = 1;
-- 58444



with enrolment as(
	select pe.individual_id,
	       pe.observations,
	       row_number() over (partition by pe.individual_id order by pe.enrolment_date_time  desc nulls last) visit
	from public.program_enrolment pe
    where
	     pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
		and pe.program_id =(select id from public."program" p where name = 'Pregnancy')
		and pe.enrolment_date_time is not null    
)
update public.individual ind
set observations = ind.observations || JSONB_SET(ind.observations, '{"be0ab05f-b0f3-43ec-b598-fdde0679104a"}', enl.observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a'),
    manual_update_history = 'set high risk based on enrolment'
from enrolment enl
where enl.individual_id = ind.id
and ind.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and visit = 1;





-- 5. Individual - If "High risk" not available then set as "High risk" no

update public.individual
set observations =        observations || '{"be0ab05f-b0f3-43ec-b598-fdde0679104a":["a77bd700-1409-4d52-93bc-9fe32c0e169b"]}',
    manual_update_history = 'set default high risk as no'
where organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and subject_type_id = (select id from public.subject_type st where name = 'Individual' limit 1)
  and (observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' is null or observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' = '[]');
-- 12130

select count(*)
from public.individual
where organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and subject_type_id = (select id from public.subject_type st where name = 'Individual' limit 1)
  and observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' is null;


-- 6. Sync attributes - Populate sync attributes of all individual, program_enrolment and program_encounter tables with the "High risk" observation on individual. Here, do not limit to specific programs or encounter types or voided

--  for individual
update public.individual
set sync_concept_1_value =
       case when observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a' =  '["a77bd700-1409-4d52-93bc-9fe32c0e169b"]'
            then 'a77bd700-1409-4d52-93bc-9fe32c0e169b'
            when observations->'be0ab05f-b0f3-43ec-b598-fdde0679104a'=   '["8ebbf088-f292-483e-9084-7de919ce67b7"]'
            then '8ebbf088-f292-483e-9084-7de919ce67b7'
        end,
        manual_update_history = 'sync_concept_1_value added based on high risk',
        last_modified_date_time = current_timestamp + ((random() * 10 + 1) * interval '1 millisecond'),
        last_modified_by_id     = (select id from users where username = 'AchalaB@apfodisha' limit 1)
where organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and subject_type_id = (select id from public.subject_type st where name = 'Individual' limit 1);


select *
from public.individual
where organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and subject_type_id = (select id from public.subject_type st where name = 'Individual' limit 1)
  and sync_concept_1_value  is null
  and subject_type_id = (select id from public.subject_type st where name = 'Individual' limit 1);
-- 71 169


-- for enrolment
update public.program_enrolment enl
set sync_concept_1_value =  ind.sync_concept_1_value ,
    manual_update_history = 'sync_concept_1_value added based on high risk',
    last_modified_date_time = current_timestamp + ((random() * 10 + 1) * interval '1 millisecond'),
    last_modified_by_id     = (select id from users where username = 'AchalaB@apfodisha')
from public.individual ind
where ind.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and enl.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and ind.subject_type_id = (select id from public.subject_type st where name = 'Individual' limit 1)
  and ind.id = enl.individual_id ;
-- 58481

select *
from public.program_enrolment pe
where pe.sync_concept_1_value is null
and pe.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
and (pe.program_id =(select id from public."program" p where name = 'Child')
     or pe.program_id =(select id from public."program" p where name = 'Pregnancy') )
;

set role apfodisha;

-- for encounter
update public.program_encounter  enc
set sync_concept_1_value =  ind.sync_concept_1_value ,
    manual_update_history = 'sync_concept_1_value added based on high risk',
    last_modified_date_time = current_timestamp + ((random() * 10 + 1) * interval '1 millisecond'),
    last_modified_by_id     = 6678
from public.individual ind
join public.program_enrolment enl on enl.individual_id  = ind.id
where ind.organisation_id = 272
  and enc.organisation_id = 272
  and ind.subject_type_id = 672
  and ind.id = enc.individual_id 
  and enl.program_id = 489     -- need to change
  and enc.program_enrolment_id = enl.id;

 -- 26,975 pregnancy
 
 

--set role apfodisha; 
--select * from public."program" p ;  -- 489 Child 488 Pregnancy 
--select id from users where username = 'AchalaB@apfodisha';  -- 6678
--select id from organisation o where "name" = 'APF Odisha' limit 1; -- 272
--select id from public.subject_type st where name = 'Individual' limit 1; -- 672

select count(*)
from public.program_encounter enc
join public.individual ind on ind.id = enc.individual_id
where ind.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and enc.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and ind.subject_type_id = (select id from public.subject_type st where name = 'Individual' limit 1)
  and enc.sync_concept_1_value is null;




select *
from public.individual ind
join public.program_enrolment enl on enl.individual_id = ind.id
join public.program_encounter enc on enc.individual_id = ind.id
where ind.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and enl.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and enc.organisation_id = (select id from organisation o where "name" = 'APF Odisha' limit 1)
  and ind.subject_type_id = (select id from public.subject_type st where name = 'Individual' limit 1)
  and ind.sync_concept_1_value != enl.sync_concept_1_value
  and enl.sync_concept_1_value != enc.sync_concept_1_value
  and ind.sync_concept_1_value != enc.sync_concept_1_value 
  and enl.program_id = 489   -- need to change;

