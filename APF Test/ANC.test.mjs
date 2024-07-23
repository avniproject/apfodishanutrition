import {expect} from 'chai';
import {funcToCheckANCScheduling} from './Test.mjs';
import {funcToCheckGrwothMonitoringScheduling} from './Test.mjs';

describe('Scheduling', () => {

    // Case 1
    it('Scheduling post ANC', () => {
        expect(funcToCheckANCScheduling(false, false, false, false, false, 1, true, true)).to.equal('ANC - 1st of the next month : QRT PW Visit - No : PW Home Visit - No');
    });
    // Case 2
    it('Scheduling post ANC', () => {
        expect(funcToCheckANCScheduling(false, true, false, false, false, 1, true, true)).to.equal('ANC - 1st of the next month : QRT PW Visit - No : PW Home Visit - 1st of next month from encounter date');
    });
    // Case 3
    it('Scheduling post ANC', () => {
        expect(funcToCheckANCScheduling(false, true, false, true, true, 1, true, true)).to.equal('ANC - 1st of the next month : QRT PW Visit - Immediately : PW Home Visit - No');
    });
    // Case 4
    it('Scheduling post ANC', () => {
        expect(funcToCheckANCScheduling(false, true, false, false, true, 1, true, true)).to.equal('ANC - 1st of the next month : QRT PW Visit - Immediately : PW Home Visit - No');
    });
    // Case 5
    it('Scheduling post ANC', () => {
        expect(funcToCheckANCScheduling(true, true, true, true, true, 1, true, true)).to.equal('ANC - 1st of the next month : QRT PW Visit - Immediately : PW Home Visit - No');
    });
    // Case 6
    it('Scheduling post ANC', () => {
        expect(funcToCheckANCScheduling(true, false, true, false, false, 1, true, true)).to.equal('ANC - 1st of the next month : QRT PW Visit - Immediately : PW Home Visit - No');
    });
    // Case 7
    it('Scheduling post ANC', () => {
        expect(funcToCheckANCScheduling(true, true, false, false, false, 1, true, true)).to.equal('ANC - 1st of the next month : QRT PW Visit - No : PW Home Visit - 1st of next month from encounter date');
    });
    // Case 8
    it('Scheduling post ANC', () => {
        expect(funcToCheckANCScheduling(true, true, true, false, true, 1, true, true)).to.equal('ANC - 1st of the next month : QRT PW Visit - Immediately : PW Home Visit - No');
    });

    // Growth Monitoring
    // Case 1
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(2, true, true, true)).to.equal('Growth Monitoring - 1st of next month from current visit\'s scheduled date : QRT Child - Scheduled date of Growth Monitoring, Overdue - Last day of the month : Child Home Visit - No');
    });

    // Case 2
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(5.1, true, true, true)).to.equal('Growth Monitoring - No : QRT Child - No : Child Home Visit - No');
    });

    // Case 3
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(2, true, false, true)).to.equal('Growth Monitoring - 1st of next month from current visit\'s scheduled date : QRT Child - Scheduled date of Growth Monitoring, Overdue - Last day of the month : Child Home Visit - No');
    });

    // Case 4
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(2, false, false, false)).to.equal('Growth Monitoring - 1st of next month from current visit\'s scheduled date : QRT Child - Scheduled date of Growth Monitoring, Overdue - Last day of the month : Child Home Visit - No');
    });

    // Case 5
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(2, false, false, true)).to.equal('Growth Monitoring - 1st of next month from current visit\'s scheduled date : QRT Child - No : Child Home Visit - Completion date of Growth Monitoring + 15 days, Overdue - Schedule + 7 days');
    });

    // Case 6
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(2, false, true, false)).to.equal('Growth Monitoring - 1st of next month from current visit\'s scheduled date : QRT Child - Scheduled date of Growth Monitoring, Overdue - Last day of the month : Child Home Visit - No');
    });

    // Case 7
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(2, false, true, true)).to.equal('Growth Monitoring - 1st of next month from current visit\'s scheduled date : QRT Child - No : Child Home Visit - Completion date of Growth Monitoring + 15 days, Overdue - Schedule + 7 days');
    });

    // Case 8
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(2, false, true, true)).to.equal('Growth Monitoring - 1st of next month from current visit\'s scheduled date : QRT Child - No : Child Home Visit - Completion date of Growth Monitoring + 15 days, Overdue - Schedule + 7 days');
    });

    // Case 8
    it('Scheduling post Growth Monitoring', () => {
        expect(funcToCheckGrwothMonitoringScheduling(2, false, false, undefined)).to.equal('Growth Monitoring - 1st of next month from current visit\'s scheduled date : QRT Child - No : Child Home Visit - No');
    });

});
