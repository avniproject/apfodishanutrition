export const funcToCheckANCScheduling = (GeographicHighRisk, ClinicallyHighRisk, ANMRecommended, MedicalFacilityIntervention, SevereAnameic, ANCNumber, currentlyActiveInProgram, isDeliveryEncounterIncomplete ) => {
    let result = '';
    const qrtEligibility = SevereAnameic || ANMRecommended || MedicalFacilityIntervention ;

    if(currentlyActiveInProgram && isDeliveryEncounterIncomplete){
        result = result + 'ANC - 1st of the next month';
    }else {
        result = result + 'ANC Visit - No';
    }

    if(qrtEligibility) {
        // noQrtEncountersScheduled
        result = result + ' : QRT PW Visit - Immediately';
        result = result + ' : PW Home Visit - No';
    } else if( ClinicallyHighRisk && !MedicalFacilityIntervention && !ANMRecommended){
    //     !isEditScenario
        result = result + ' : QRT PW Visit - No';
        result = result + ' : PW Home Visit - 1st of next month from encounter date'
    } else {
        result = result + ' : QRT PW Visit - No';
        result = result + ' : PW Home Visit - No';
    }
    return result;
}




