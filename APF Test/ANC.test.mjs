import {expect} from 'chai';
import {funcToCheckANCScheduling} from './Test.mjs';

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
});
