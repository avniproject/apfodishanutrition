set role apfodisha;


update subject_type
set sync_registration_concept_1 = 'be0ab05f-b0f3-43ec-b598-fdde0679104a',
    sync_registration_concept_1_usable = true,
    last_modified_date_time = current_timestamp,
    last_modified_by_id = (select id from users where username = 'vedantr@apfodisha')
where name = 'Individual';


update public.users u
set sync_settings = sync_settings || '{"subjectTypeSyncSettings": [{"syncConcept1": "be0ab05f-b0f3-43ec-b598-fdde0679104a", "syncConcept2": null, "subjectTypeUUID": "ec69af69-8fd2-40b3-b429-025504c18a01", "syncConcept1Values": ["8ebbf088-f292-483e-9084-7de919ce67b7"], "syncConcept2Values": []}]}',
    last_modified_date_time = now() ,
    last_modified_by_id = (select id from users where username = 'vedantr@apfodisha')
from public.user_group ug
where ug.user_id = u.id
  and ug.group_id  = (select id from public."groups" where name = 'QRT users' limit 1);

select u.id,username,sync_settings
from users u
         join public.user_group ug on ug.user_id = u.id
where ug.group_id  = (select id from public."groups" where name = 'QRT users' limit 1);



update public.users u
set sync_settings = sync_settings || '{"subjectTypeSyncSettings": [{"syncConcept1": "be0ab05f-b0f3-43ec-b598-fdde0679104a", "syncConcept2": null, "subjectTypeUUID": "ec69af69-8fd2-40b3-b429-025504c18a01", "syncConcept1Values": ["8ebbf088-f292-483e-9084-7de919ce67b7","a77bd700-1409-4d52-93bc-9fe32c0e169b"], "syncConcept2Values": []}]}',
    last_modified_date_time = now() ,
    last_modified_by_id = (select id from users where username = 'vedantr@apfodisha')
from public.user_group ug
where ug.user_id = u.id
  and ug.group_id  = (select id from public."groups" where name = 'Poshan Sathi' limit 1);

select u.id,username,sync_settings
from users u
         join public.user_group ug on ug.user_id = u.id
where ug.group_id  = (select id from public."groups" where name = 'Poshan Sathi' limit 1);



update public.users u
set sync_settings = sync_settings || '{"subjectTypeSyncSettings": [{"syncConcept1": "be0ab05f-b0f3-43ec-b598-fdde0679104a", "syncConcept2": null, "subjectTypeUUID": "ec69af69-8fd2-40b3-b429-025504c18a01", "syncConcept1Values": ["8ebbf088-f292-483e-9084-7de919ce67b7","a77bd700-1409-4d52-93bc-9fe32c0e169b"], "syncConcept2Values": []}]}',
    last_modified_date_time = now() ,
    last_modified_by_id = (select id from users where username = 'vedantr@apfodisha')
from public.user_group ug
where ug.user_id = u.id
  and ug.group_id  = (select id from public."groups" where name = 'PMU' limit 1);

select u.id,username,sync_settings
from users u
         join public.user_group ug on ug.user_id = u.id
where ug.group_id  = (select id from public."groups" where name = 'PMU' limit 1);