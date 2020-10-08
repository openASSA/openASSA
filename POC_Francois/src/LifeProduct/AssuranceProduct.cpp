#include "AssuranceProduct.h"
#include <ql/event.hpp>
#include <ql/time/daycounters/simpledaycounter.hpp>
#include <ql/utilities/null_deleter.hpp>
#include <iostream>

namespace QuantLib {
    AssuranceProduct::AssuranceProduct(const Handle<PolicyDetails>& policyDetails,
                                       const Handle<YieldTermStructure>& yieldTS,
                                       const Handle<DefaultProbabilityTermStructure>& mortality,
                                       const Handle<DefaultProbabilityTermStructure>& lapses)
    : policyDetails_(policyDetails), yieldTS_(yieldTS), mortality_(mortality), lapses_(lapses) {
        registerWith(policyDetails_);
        registerWith(yieldTS_);
    }

    void AssuranceProduct::performCalculations() const {
        premiumNPV_ = 0.;
        benefitNPV_ = 0.;

        Real cumulativeSurvival = 1.0;

        Size maxMonths = (120 - policyDetails()->policyHolder()->age() + 1) * 12;

        for (Integer i = 1; i < maxMonths; i++) {
            Date projectionDate = calendar_.advance(Settings::instance().evaluationDate(), i,
                                                    Months, Unadjusted, true);

            Real discount = yieldTS_.currentLink()->discount(projectionDate, true);
            Real lapseRate = GetLapseRate(projectionDate);
            Real qx = GetMortalityRate(projectionDate);

            Real nrOfDeaths = cumulativeSurvival * qx * (1 - 0.5 * lapseRate);
            Real nrOfSurrenders = cumulativeSurvival * lapseRate * (1 - 0.5 * qx);

            cumulativeSurvival -= nrOfDeaths;
            cumulativeSurvival -= nrOfSurrenders;

            premiumNPV_ +=
                policyDetails()->annualPremium()->value() / 12 * cumulativeSurvival * discount;
            benefitNPV_ += -policyDetails()->sumAssured()->value() * nrOfDeaths * discount;

  /*          std::cout << projectionDate.dayOfMonth() << " " << projectionDate.month() << " "
                      << projectionDate.year() << "\t"
                      << policyDetails()->annualPremium()->value() / 12 * cumulativeSurvival *
                             discount
                      << std::endl;*/
        }

        NPV_ = premiumNPV_ + benefitNPV_;
    }

    Real AssuranceProduct::GetMortalityRate(const Date projectionDate) const {
        return mortality_->hazardRate(projectionDate, true) / 12;
    }

    Real AssuranceProduct::GetLapseRate(const Date projectionDate) const {
        return lapses_->hazardRate(projectionDate, true) / 12;
    }
}