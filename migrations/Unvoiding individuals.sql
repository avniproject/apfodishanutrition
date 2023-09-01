set role apfodisha; 

select * from users where username = 'taqi@apfodisha';

select * from subject_type st where name = 'Individual';

select * from virtual_catchment_address_mapping_table vcamt where catchment_id = 9999;

update individual 
set is_voided = false,
last_modified_by_id = 6664,
last_modified_date_time = now()
where id in (
select id
from individual i 
where is_voided = true
and address_id in (331109,
331116,
331121,
331367,
331375,
331379)
);