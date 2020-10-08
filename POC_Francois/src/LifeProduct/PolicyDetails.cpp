#include "PolicyDetails.h"

namespace QuantLib {
    PolicyDetails::PolicyDetails(const Handle<PolicyHolder>& policyHolder,
                                 const Handle<Quote>& annualPremium,
                                 const Handle<Quote>& sumAssured)
    : policyHolder_(policyHolder), annualPremium_(annualPremium), sumAssured_(sumAssured) {
        registerWith(policyHolder);
        registerWith(annualPremium);
        registerWith(sumAssured);
    }
}