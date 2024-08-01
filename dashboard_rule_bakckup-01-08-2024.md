
**High Risk Pregnancy (pregnancy program):**

```js
'use strict';
({params, imports}) => {

const _ = imports.lodash;
  const moment = imports.moment;
    const isHighRisk = (enrolment) => {
        const isGeoHighRisk =_.includes(enrolment.getObservationReadableValue('Pregnancy geographically high risk'), 'Yes');
        const isClinicHighRisk = _.includes(enrolment.getObservationReadableValue('Clinically high risk'), 'Yes');
        return isGeoHighRisk || isClinicHighRisk;
    };

    let lst = params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Pregnancy' and $enrolment.programExitDateTime = null and $enrolment.voided = false).@count > 0`)
        .filter((individual) => individual.voided === false && _.some(individual.enrolments, enrolment => enrolment.program.name === 'Pregnancy' && isHighRisk(enrolment)));


    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");
        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            let addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
            if (addressValue.length > 0) {
                lst = lst.filter(ind => _.includes(addressValue, ind.lowestAddressLevel.name));
            }
        }
    }
    return lst;
};
```

```js
'use strict';
({params, imports}) => {
    let addressValue = null;
    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");

        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
            console.log(addressValue, addressValue)
        }
    }
    const addFil = addressValue != null?addressValue.map(name => `lowestAddressLevel.name = '${name}'`).join(' OR '):'voided=false';
    let list = params.db.objects('Individual')
        .filtered(`voided==false and SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Pregnancy' and $enrolment.programExitDateTime = null and $enrolment.voided = false and SUBQUERY( $enrolment.observations, $observation, ($observation.concept.uuid = '96b167e1-2d98-40b9-af04-8e4f64f9999a' and $observation.valueJSON CONTAINS '8ebbf088-f292-483e-9084-7de919ce67b7') or ($observation.concept.uuid = '3e21a6f4-6727-44b3-9b7e-148ce9ad77fd' and $observation.valueJSON CONTAINS '8ebbf088-f292-483e-9084-7de919ce67b7')).@count > 0).@count > 0 `)
        .filtered(`${addFil}`)


    return list;
};
```



### Child with age more than 5 years



```js
// Documentation - https://docs.mongodb.com/realm-legacy/docs/javascript/latest/index.html#queries
'use strict';
({params, imports}) => {

const _ = imports.lodash;
  const moment = imports.moment;

    let lst = params.db.objects('Individual')
    .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.programExitDateTime = null and $enrolment.program.name = 'Child' and $enrolment.voided = false).@count > 0`)
    .filter((individual) => individual.voided === false && individual.getAgeInYears() >= 5 && _.some(individual.enrolments, enrolment => enrolment.program.name === 'Child'))
           if(params.ruleInput){

              let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");
              if(addressFilter.length>0 && addressFilter[0].filterValue){

                 let addressValue = addressFilter[0].filterValue.filter((add)=> add.type =="Village/Hamlet").map(add=>add.name);
                 if(addressValue.length>0){
                   lst = lst.filter(ind=>_.includes(addressValue,_.get(ind,"lowestAddressLevel.name")));
                 }
              }
        }

    return lst;
};
```


```js
// Documentation - https://docs.mongodb.com/realm-legacy/docs/javascript/latest/index.html#queries
'use strict';
({params, imports}) => {
    const _ = imports.lodash;
    var date = new Date();
    date.setFullYear(date.getFullYear() - 5);
    let addressValue = null;

    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");

        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
        }
    }

    const addFilter = addressValue != null?addressValue.map(name => `programEnrolment.individual.lowestAddressLevel.name = '${name}'`).join(' OR '):'voided=false';



    return  params.db.objects('Individual')
        .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.programExitDateTime = null and $enrolment.program.name = 'Child' and $enrolment.voided = false).@count > 0 AND dateOfBirth <= $0`,date)
        .filtered(`${addFilter}`)

};
```


### Total AWC Profiles Registered


```js
'use strict';
({params, imports}) => {

  const _ = imports.lodash;
  const moment = imports.moment;

    let lst = params.db.objects('Individual')
            .filter((individual) => individual.voided === false && individual.subjectType.name === 'AWC Profile');

               if(params.ruleInput){
      let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");
      if(addressFilter.length>0 && addressFilter[0].filterValue){
         //console.log("rules==============>address filter set");
         //console.log("rules===========>",JSON.stringify(addressFilter[0].filterValue));
         let addressValue = addressFilter[0].filterValue.filter((add)=> add.type =="AWC").map(add=>add.name);
         if(addressValue.length>0 ){
          lst =lst.filter(ind=>_.includes(addressValue,ind.lowestAddressLevel.name));
         //console.log(lst);
         }
      }
    }


     return lst;
};
```


```js
'use strict';
({params, imports}) => {

    let addressValue = null;

    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");

        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
        }
    }

    const addFilter = addressValue != null?addressValue.map(name => `programEnrolment.individual.lowestAddressLevel.name = '${name}'`).join(' OR '):'voided=false';


    let lst = params.db.objects('Individual')
            .filtered(`voided = false AND subjectType.name = 'AWC Profile'`)
            .filtered(`${addFilter}`);

     return lst;
};
```



### Total Village Profiles Registered

```js
'use strict';
({params, imports}) => {

const _ = imports.lodash;
  const moment = imports.moment;

    let lst = params.db.objects('Individual').filter((individual) => individual.voided === false && individual.subjectType.name === 'Village Profile');

                if(params.ruleInput){

              let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");
              if(addressFilter.length>0 && addressFilter[0].filterValue){
                 //console.log("rules==============>address filter set");
                 //console.log("rules===========>",JSON.stringify(addressFilter[0].filterValue));
                 let addressValue = addressFilter[0].filterValue.filter((add)=> add.type =="Village/Hamlet").map(add=>add.name);
                 if(addressValue.length>0){
                   lst = lst.filter(ind=>_.includes(addressValue,ind.lowestAddressLevel.name));
                 //console.log(lst);
                 }
              }
        }

    return lst;
};
```



```js
'use strict';
({params, imports}) => {

    let addressValue = null;

    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");

        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
        }
    }

    const addFilter = addressValue != null?addressValue.map(name => `programEnrolment.individual.lowestAddressLevel.name = '${name}'`).join(' OR '):'voided=false';


    let lst = params.db.objects('Individual')
            .filtered(`voided = false AND subjectType.name = 'Village Profile'`)
            .filtered(`${addFilter}`);

     return lst;
};
```


### Total children enrolled in CMAM program


```js
'use strict';

({params, imports}) => {

  const _ = imports.lodash;
  const moment = imports.moment;
    let lst = params.db.objects('ProgramEnrolment')
        .filtered(`voided = false and  programExitDateTime = null and individual.voided = false and program.name='Child'`)
        .filter((enrolment)=> enrolment.getObservationReadableValueInEntireEnrolment("Is the child enrolled in the CMAM program?")=='Yes')
        .map((enrolment) => enrolment.individual);

    if (params.ruleInput) {

        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");
        if (addressFilter.length > 0 && addressFilter[0].filterValue) {

            let addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
            if (addressValue.length > 0) {
                lst = lst.filter(ind => _.includes(addressValue, _.get(ind, "lowestAddressLevel.name")));
            }
        }
    }



    return lst;
};

```


```js
'use strict';

({params, imports}) => {

    let addressValue = null;

    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");

        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
        }
    }

    const addFilter = addressValue != null?addressValue.map(name => `programEnrolment.individual.lowestAddressLevel.name = '${name}'`).join(' OR '):'voided=false';

    // $encounter.encounterDateTime = MAX($enrolment.encounters.encounterDateTime) AND
    let list = params.db.objects('Individual')
        .filtered(`voided=false and SUBQUERY(enrolments, $enrolment, $enrolment.program.name = 'Child' and $enrolment.programExitDateTime = null and $enrolment.voided = false and
        SUBQUERY($enrolment.encounters,$encounter,
            $encounter.voided = false AND
            $encounter.encounterType.name = 'Growth Monitoring' AND
            SUBQUERY($encounter.observations,$observation,
                $observation.concept.uuid = '001b3307-731e-4606-a8f4-9aaa1e264000' AND
                $observation.valueJSON CONTAINS '8ebbf088-f292-483e-9084-7de919ce67b7'
                ).@count>0
            ).@count > 0
        ).@count > 0 `)
        .filtered(`${addFilter}`)


    return list;
};
```



### Total enrolments in child program


```js
// Documentation - https://docs.mongodb.com/realm-legacy/docs/javascript/latest/index.html#queries
'use strict';
({params, imports}) => {
  const _ = imports.lodash;
  const moment = imports.moment;
    let lst = params.db.objects('Individual')
    .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.programExitDateTime = null and $enrolment.program.name = 'Child' and $enrolment.voided = false).@count > 0`)
    .filter((individual) => individual.voided === false && _.some(individual.enrolments, enrolment => enrolment.program.name === 'Child'))
           if(params.ruleInput){

              let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");
              if(addressFilter.length>0 && addressFilter[0].filterValue){

                 let addressValue = addressFilter[0].filterValue.filter((add)=> add.type =="Village/Hamlet").map(add=>add.name);
                 if(addressValue.length>0){
                   lst = lst.filter(ind=>_.includes(addressValue,_.get(ind,"lowestAddressLevel.name")));
                 }
              }
        }

    return lst;
};
```


```js
'use strict';
({params, imports}) => {

    let addressValue = null;

    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");

        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
        }
    }

    const addFilter = addressValue != null?addressValue.map(name => `programEnrolment.individual.lowestAddressLevel.name = '${name}'`).join(' OR '):'voided=false';


    let lst = params.db.objects('Individual')
            .filtered(`voided = false AND subjectType.name = 'Individual' AND
            SUBQUERY(enrolments, $enrolment, $enrolment.programExitDateTime = null and $enrolment.program.name = 'Child' and $enrolment.voided = false).@count > 0
            `)
            .filtered(`${addFilter}`);

     return lst;
};
```


### Total enrolments in pregnancy program

```js
// Documentation - https://docs.mongodb.com/realm-legacy/docs/javascript/latest/index.html#queries
'use strict';
({params, imports}) => {

const _ = imports.lodash;
  const moment = imports.moment;

    let lst = params.db.objects('Individual')
    .filtered(`SUBQUERY(enrolments, $enrolment, $enrolment.programExitDateTime = null and $enrolment.program.name = 'Pregnancy' and $enrolment.voided = false).@count > 0`)
    .filter((individual) => individual.voided === false && _.some(individual.enrolments, enrolment => enrolment.program.name === 'Pregnancy'));

         if(params.ruleInput){
              let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");
              if(addressFilter.length>0 && addressFilter[0].filterValue){
                 let addressValue = addressFilter[0].filterValue.filter((add)=> add.type =="Village/Hamlet").map(add=>add.name);
                 if(addressValue.length>0){
                   lst = lst.filter(ind=>_.includes(addressValue,ind.lowestAddressLevel.name));
                 }
              }
        }


    return lst;
};
```



```js
'use strict';
({params, imports}) => {

    let addressValue = null;

    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");

        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
        }
    }

    const addFilter = addressValue != null?addressValue.map(name => `programEnrolment.individual.lowestAddressLevel.name = '${name}'`).join(' OR '):'voided=false';


    let lst = params.db.objects('Individual')
            .filtered(`voided = false AND subjectType.name = 'Individual' AND
            SUBQUERY(enrolments, $enrolment, $enrolment.programExitDateTime = null and $enrolment.program.name = 'Pregnancy' and $enrolment.voided = false).@count > 0
            `)
            .filtered(`${addFilter}`);

     return lst;
};
```


### Total households registered

```js
'use strict';
({params, imports}) => {

  const _ = imports.lodash;
  const moment = imports.moment;

        /*
        const lineListFunction = function () {
          return params.db.objects('Individual')
            .filter((individual) => individual.voided === false && individual.subjectType.name === 'Household');
      };
      const totalStudentsRegistered = (params, imports) =>  {
        return params.db.objects('Individual')
            .filter((individual) => individual.voided === false && individual.subjectType.name === 'Household').length;

    };
        return {
        primaryValue: totalStudentsRegistered(params, imports),
        lineListFunction
    };
    */
        let lst  = params.db.objects('Individual').filter((individual) => individual.voided === false && individual.subjectType.name === 'Household');

           if(params.ruleInput){
      let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");
      if(addressFilter.length>0 && addressFilter[0].filterValue){
         //console.log("rules==============>address filter set");
         //console.log("rules===========>",JSON.stringify(addressFilter[0].filterValue));
         let addressValue = addressFilter[0].filterValue.filter((add)=> add.type =="Village/Hamlet").map(add=>add.name);
         if(addressValue.length>0){
          lst =lst.filter(ind=>_.includes(addressValue,ind.lowestAddressLevel.name));
         //console.log(lst);
         }
      }
    }
      return lst;
};
```


```js

'use strict';
({params, imports}) => {

    let addressValue = null;

    if (params.ruleInput) {
        let addressFilter = params.ruleInput.filter(rule => rule.type === "Address");

        if (addressFilter.length > 0 && addressFilter[0].filterValue) {
            addressValue = addressFilter[0].filterValue.filter((add) => add.type == "Village/Hamlet").map(add => add.name);
        }
    }

    const addFilter = addressValue != null?addressValue.map(name => `programEnrolment.individual.lowestAddressLevel.name = '${name}'`).join(' OR '):'voided=false';


    let lst = params.db.objects('Individual')
            .filtered(`voided = false AND subjectType.name = 'Household'`)
            .filtered(`${addFilter}`);

     return lst;
};

```
