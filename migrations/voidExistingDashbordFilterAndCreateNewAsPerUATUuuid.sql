set role apfodisha;
update dashboard_filter
set is_voided= true,
    last_modified_date_time= now()
where id in (4, 26);--2 will update



--Dashboard
INSERT INTO dashboard_filter (dashboard_id, filter_config, uuid, organisation_id, is_voided, version, created_by_id,
                              last_modified_by_id, created_date_time, last_modified_date_time, name)
VALUES (181, '{
  "type": "Address",
  "widget": null,
  "subjectTypeUUID": null
}', 'd84cddb5-3156-4117-be70-9c3fa557f96a', 272, false, 0, (select id from users where username = 'sachink@apfodisha'),
        (select id from users where username = 'sachink@apfodisha'), now(), now(), 'Location');


--QRT Dashboard

INSERT INTO dashboard_filter (dashboard_id, filter_config, uuid, organisation_id, is_voided, version, created_by_id,
                              last_modified_by_id, created_date_time, last_modified_date_time, name)
VALUES (408, '{
  "type": "Address",
  "widget": null,
  "subjectTypeUUID": null
}', '46a9ab9f-1d72-49cb-b4b3-98616a386517', 272, false, 0, (select id from users where username = 'sachink@apfodisha'),
        (select id from users where username = 'sachink@apfodisha'), now(), now(), 'Location');

--QRT pregnancy due and overdue visits

INSERT INTO dashboard_filter (dashboard_id, filter_config, uuid, organisation_id, is_voided, version, created_by_id,
                              last_modified_by_id, created_date_time, last_modified_date_time, name)
VALUES (409, '{
  "type": "Address",
  "widget": null,
  "subjectTypeUUID": null
}', 'fe104d88-0b4d-4f14-ac79-7ab93ed1ce7e', 272, true, 0, (select id from users where username = 'sachink@apfodisha'),
        (select id from users where username = 'sachink@apfodisha'), now(), now(), 'Location');


--Pregnancy due and overdue visits

INSERT INTO dashboard_filter (dashboard_id, filter_config, uuid, organisation_id, is_voided, version, created_by_id,
                              last_modified_by_id, created_date_time, last_modified_date_time, name)
VALUES (230, '{
  "type": "Address",
  "widget": null,
  "subjectTypeUUID": null
}', '38e47080-3fe9-4ad5-b455-bce682e0861f', 272, false, 0, (select id from users where username = 'sachink@apfodisha'),
        (select id from users where username = 'sachink@apfodisha'), now(), now(), 'Location');


