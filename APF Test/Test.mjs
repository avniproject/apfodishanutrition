export const funcToCheckANCScheduling = (GeographicHighRisk, ClinicallyHighRisk, ANMRecommended, MedicalFacilityIntervention, SevereAnameic, ANCNumber, currentlyActiveInProgram, isDeliveryEncounterIncomplete) => {
    let result = '';
    const qrtEligibility = SevereAnameic || ANMRecommended || MedicalFacilityIntervention;

    if (currentlyActiveInProgram && isDeliveryEncounterIncomplete) {
        result = result + 'ANC - 1st of the next month';
    } else {
        result = result + 'ANC Visit - No';
    }

    if (qrtEligibility) {
        // noQrtEncountersScheduled
        result = result + ' : QRT PW Visit - Immediately';
        result = result + ' : PW Home Visit - No';
    } else if (ClinicallyHighRisk && !MedicalFacilityIntervention && !ANMRecommended) {
        //     !isEditScenario
        result = result + ' : QRT PW Visit - No';
        result = result + ' : PW Home Visit - 1st of next month from encounter date'
    } else {
        result = result + ' : QRT PW Visit - No';
        result = result + ' : PW Home Visit - No';
    }
    return result;
}

export const funcToCheckGrwothMonitoringScheduling = (childAgeInYears, isSAM, isGF1, isTreatmentAtHome ) => {
    let result = '';
    // && !isEditScenario
    if(childAgeInYears < 5 && isTreatmentAtHome == undefined){
        result = result + 'Growth Monitoring - 1st of next month from current visit\'s scheduled date';
        result = result + ' : QRT Child - No';
        result = result + ' : Child Home Visit - No';
    }else if (childAgeInYears < 5 && (!isTreatmentAtHome || isSAM)) {
        result = result + 'Growth Monitoring - 1st of next month from current visit\'s scheduled date';
        result = result + ' : QRT Child - Scheduled date of Growth Monitoring, Overdue - Last day of the month';
        result = result + ' : Child Home Visit - No';
    } else if (childAgeInYears < 5 && (isTreatmentAtHome || isGF1) && !isSAM) {
        result = result + 'Growth Monitoring - 1st of next month from current visit\'s scheduled date';
        result = result + ' : QRT Child - No';
        result = result + ' : Child Home Visit - Completion date of Growth Monitoring + 15 days, Overdue - Schedule + 7 days';
    } else {
        result = result + 'Growth Monitoring - No';
        result = result + ' : QRT Child - No';
        result = result + ' : Child Home Visit - No';
    }
    return result;
}





