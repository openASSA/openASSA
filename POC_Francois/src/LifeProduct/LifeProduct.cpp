#include <iomanip>
#include <iostream>

#include <ql/qldefines.hpp>
#ifdef BOOST_MSVC
#include <ql/auto_link.hpp>
#endif
#include <ql/math/interpolations/backwardflatinterpolation.hpp>
#include <ql/math/interpolations/forwardflatinterpolation.hpp>
#include <ql/math/interpolations/linearinterpolation.hpp>
#include <ql/termstructures/credit/interpolatedhazardratecurve.hpp>
#include <ql/termstructures/yield/zerocurve.hpp>
#include <ql/time/daycounters/simpledaycounter.hpp>

#include <AssuranceProduct.h>

using namespace QuantLib;

#define LENGTH(a) (sizeof(a) / sizeof(a[0]))

struct CalculationInputs {
    Calendar calendar = NullCalendar();
    DayCounter dc = SimpleDayCounter();
    Date valuationDate;

    std::map<Date, Real> yieldCurve;
    std::map<Integer, Real> mortalityTable;
    std::map<Integer, Real> lapseTable;

    CalculationInputs() {
        valuationDate = Date(30, Sep, 2020);

        Settings::instance().evaluationDate() = valuationDate;

        yieldCurve = YieldCurve(calendar, valuationDate);
        mortalityTable = MortalityTable(calendar, valuationDate);
        lapseTable = LapseTable(calendar, valuationDate);
    }

    std::map<Date, Real> YieldCurve(Calendar calendar, Date valuationDate) {
        std::map<Date, Real> yc;
        for (int i = 0; i < 120 * 12; i++) {
            Date curveDate = calendar.advance(valuationDate, i, Months, Unadjusted, true);
            yc[curveDate] = std::log(1 + 0.1);
        }

        return yc;
    }

    std::map<Integer, Real> MortalityTable(Calendar calendar, Date valuationDate) {
        std::map<Integer, Real> mt;

        mt[1] = 0.00189;
        mt[2] = 0.00189;
        mt[3] = 0.00189;
        mt[4] = 0.00189;
        mt[5] = 0.00189;
        mt[6] = 0.00189;
        mt[7] = 0.00189;
        mt[8] = 0.00189;
        mt[9] = 0.00189;
        mt[10] = 0.00189;
        mt[11] = 0.00189;
        mt[12] = 0.00189;
        mt[13] = 0.00189;
        mt[14] = 0.00189;
        mt[15] = 0.00189;
        mt[16] = 0.0024;
        mt[17] = 0.00295;
        mt[18] = 0.0033;
        mt[19] = 0.00335;
        mt[20] = 0.00302;
        mt[21] = 0.00283;
        mt[22] = 0.00318;
        mt[23] = 0.00337;
        mt[24] = 0.00337;
        mt[25] = 0.00315;
        mt[26] = 0.00299;
        mt[27] = 0.00292;
        mt[28] = 0.00287;
        mt[29] = 0.00285;
        mt[30] = 0.00286;
        mt[31] = 0.00289;
        mt[32] = 0.00295;
        mt[33] = 0.00303;
        mt[34] = 0.00313;
        mt[35] = 0.00324;
        mt[36] = 0.00337;
        mt[37] = 0.00351;
        mt[38] = 0.00367;
        mt[39] = 0.00383;
        mt[40] = 0.004;
        mt[41] = 0.00417;
        mt[42] = 0.00434;
        mt[43] = 0.00451;
        mt[44] = 0.00468;
        mt[45] = 0.00484;
        mt[46] = 0.00503;
        mt[47] = 0.0053;
        mt[48] = 0.00567;
        mt[49] = 0.00613;
        mt[50] = 0.00667;
        mt[51] = 0.00728;
        mt[52] = 0.00796;
        mt[53] = 0.0087;
        mt[54] = 0.00949;
        mt[55] = 0.01038;
        mt[56] = 0.01139;
        mt[57] = 0.0125;
        mt[58] = 0.01371;
        mt[59] = 0.01504;
        mt[60] = 0.01649;
        mt[61] = 0.01809;
        mt[62] = 0.01983;
        mt[63] = 0.02174;
        mt[64] = 0.02384;
        mt[65] = 0.02612;
        mt[66] = 0.02863;
        mt[67] = 0.03136;
        mt[68] = 0.03436;
        mt[69] = 0.03763;
        mt[70] = 0.04121;
        mt[71] = 0.04511;
        mt[72] = 0.04937;
        mt[73] = 0.05403;
        mt[74] = 0.0591;
        mt[75] = 0.06463;
        mt[76] = 0.07066;
        mt[77] = 0.07723;
        mt[78] = 0.08437;
        mt[79] = 0.09214;
        mt[80] = 0.10059;
        mt[81] = 0.14982;
        mt[82] = 0.16215;
        mt[83] = 0.17538;
        mt[84] = 0.18957;
        mt[85] = 0.20476;
        mt[86] = 0.22099;
        mt[87] = 0.2383;
        mt[88] = 0.25674;
        mt[89] = 0.27632;
        mt[90] = 0.29708;
        mt[91] = 0.31903;
        mt[92] = 0.34218;
        mt[93] = 0.36651;
        mt[94] = 0.39201;
        mt[95] = 0.41864;
        mt[96] = 0.44634;
        mt[97] = 0.47503;
        mt[98] = 0.50461;
        mt[99] = 0.53496;
        mt[100] = 0.56592;
        mt[101] = 0.59733;
        mt[102] = 0.59733;
        mt[103] = 0.59733;
        mt[104] = 0.59733;
        mt[105] = 0.59733;
        mt[106] = 0.59733;
        mt[107] = 0.59733;
        mt[108] = 0.59733;
        mt[109] = 0.59733;
        mt[110] = 0.59733;
        mt[111] = 0.59733;
        mt[112] = 0.59733;
        mt[113] = 0.59733;
        mt[114] = 0.59733;
        mt[115] = 0.59733;
        mt[116] = 0.59733;
        mt[117] = 0.59733;
        mt[118] = 0.59733;
        mt[119] = 0.59733;
        mt[120] = 0.59733;

        // std::map<Date, Real> mt2;
        // for (int i = 0; i <= 120; i++) {
        //    Date curveDate = calendar.advance(valuationDate, i, Years, Unadjusted, true);
        //    mt2[curveDate] = mt[i];
        //}

        return mt;
    }

    std::map<Integer, Real> LapseTable(Calendar calendar, Date valuationDate) {
        std::map<Integer, Real> lt;

        lt[0] = 0.1;
        lt[1] = 0.1;
        lt[2] = 0.09;
        lt[3] = 0.08;
        lt[4] = 0.07;
        lt[5] = 0.06;
        lt[6] = 0.05;
        lt[7] = 0.04;
        lt[8] = 0.03;
        lt[9] = 0.02;
        lt[10] = 0.01;

        return lt;
    }

    ext::shared_ptr<DefaultProbabilityTermStructure>
    MortalityHazardRateStructure(Integer age, Date dateOfBirth) {
        Date lastBirthday = calendar.advance(dateOfBirth, age, Years);

        std::vector<Date> dates;
        std::vector<Real> rates;

        for (std::map<Integer, Real>::iterator iter = mortalityTable.begin();
             iter != mortalityTable.end(); ++iter) {
            if (iter->first >= age) {
                Date birthday = calendar.advance(lastBirthday, iter->first - age, Years);
                dates.push_back(birthday);
                rates.push_back(iter->second);
            }
        }

        return ext::shared_ptr<DefaultProbabilityTermStructure>(
            new InterpolatedHazardRateCurve<ForwardFlat>(dates, rates, dc));
    }

    ext::shared_ptr<DefaultProbabilityTermStructure> LapseHazardRateStructure(Integer duration,
                                                                              Date inceptionDate) {
        Date lastBirthday = calendar.advance(inceptionDate, duration, Years);

        std::vector<Date> dates;
        std::vector<Real> rates;

        for (std::map<Integer, Real>::iterator iter = lapseTable.begin();
             iter != lapseTable.end(); ++iter) {
            if (iter->first >= duration) {
                Date birthday = calendar.advance(lastBirthday, iter->first - duration, Years);
                dates.push_back(birthday);
                rates.push_back(iter->second);
            }
        }

        return ext::shared_ptr<DefaultProbabilityTermStructure>(
            new InterpolatedHazardRateCurve<BackwardFlat>(dates, rates, dc));
    }
};

struct PolicyData {
    Date dateOfBirth;
    Date inceptionDate;
    Real annualPremium;
    Real sumAssured;
};

int main(int, char*[]) {
    try {
        CalculationInputs inputs;

        PolicyData policyData[] = {{Date(30, Sep, 1985), Date(30, Apr, 2020), 3600, 1000000},
                                   {Date(30, Sep, 1970), Date(30, Nov, 2019), 5000, 1000000},
                                   {Date(30, Sep, 1960), Date(31, Aug, 2018), 6000, 1000000},
                                   {Date(30, Sep, 1975), Date(30, June, 2019), 400, 1000000}};

        // SET UP YIELD CURVE
        std::vector<Date> dates;
        std::vector<Real> rates;

        for (std::map<Date, Real>::iterator iter = inputs.yieldCurve.begin();
             iter != inputs.yieldCurve.end(); ++iter) {
            dates.push_back(iter->first);
            rates.push_back(iter->second);
        }

        ext::shared_ptr<YieldTermStructure> yieldTermStructure =
            ext::shared_ptr<YieldTermStructure>(
                new InterpolatedZeroCurve<Linear>(dates, rates, inputs.dc));

        RelinkableHandle<YieldTermStructure> yieldHandle;
        yieldHandle.linkTo(yieldTermStructure);

        RelinkableHandle<PolicyHolder> policyHolderHandle(
            ext::shared_ptr<PolicyHolder>(new PolicyHolder(Date(), Date())));

        RelinkableHandle<Quote> annualPremium(ext::shared_ptr<Quote>(new SimpleQuote()));
        RelinkableHandle<Quote> sumAssured(ext::shared_ptr<Quote>(new SimpleQuote()));

        RelinkableHandle<PolicyDetails> policyDetailsHandle;
        policyDetailsHandle.linkTo(ext::shared_ptr<PolicyDetails>(
            new PolicyDetails(policyHolderHandle, annualPremium, sumAssured)));

        RelinkableHandle<DefaultProbabilityTermStructure> mortalityHandle(
            ext::shared_ptr<DefaultProbabilityTermStructure>(
                inputs.MortalityHazardRateStructure(0, inputs.valuationDate)));

        RelinkableHandle<DefaultProbabilityTermStructure> lapsesHandle(
            ext::shared_ptr<DefaultProbabilityTermStructure>(
                inputs.LapseHazardRateStructure(0, inputs.valuationDate)));

        AssuranceProduct product(policyDetailsHandle, yieldHandle, mortalityHandle, lapsesHandle);

        for (int j = 0; j < 1; j++) {
            for (Size i = 0; i < LENGTH(policyData); i++) {
                policyHolderHandle.linkTo(ext::shared_ptr<PolicyHolder>(
                    new PolicyHolder(policyData[i].dateOfBirth, policyData[i].inceptionDate)));

                annualPremium.linkTo(
                    ext::shared_ptr<Quote>(new SimpleQuote(policyData[i].annualPremium)));
                sumAssured.linkTo(
                    ext::shared_ptr<Quote>(new SimpleQuote(policyData[i].sumAssured)));

                // SET UP MORTALITY HAZARD RATE STRUCTURE
                mortalityHandle.linkTo(
                    inputs.MortalityHazardRateStructure(policyHolderHandle->age(), policyHolderHandle->dateOfBirth()));

                lapsesHandle.linkTo(inputs.LapseHazardRateStructure(
                    policyHolderHandle->duration(), policyHolderHandle->inceptionDate()));

                product.recalculate();
                // std::cout << "Premiums: " << product.premiumNPV() << std::endl;
                // std::cout << "Benefits: " << product.benefitNPV() << std::endl;
                std::cout << "Total: " << product.NPV() << std::endl;
            }
        }

        return 0;
    } catch (std::exception& e) {
        std::cerr << e.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "unknown error" << std::endl;
        return 1;
    }
}