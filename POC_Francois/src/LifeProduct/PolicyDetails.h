#ifndef quantlib_policy_details_hpp
#define quantlib_policy_details_hpp

#include <ql/patterns/lazyobject.hpp>
#include <ql/quote.hpp>
#include <ql/settings.hpp>
#include <ql/time/date.hpp>
#include <ql/time/daycounter.hpp>

#include <PolicyHolder.h>

namespace QuantLib {
    class PolicyDetails : public LazyObject {
      public:
        PolicyDetails(const Handle<PolicyHolder>& policyHolder,
                      const Handle<Quote>& annualPremium,
                      const Handle<Quote>& sumAssured);

        Handle<PolicyHolder> policyHolder() const { return policyHolder_; }
        Handle<Quote> annualPremium() const { return annualPremium_; }
        Handle<Quote> sumAssured() const { return sumAssured_; }

        void performCalculations() const {}

      private:
        // Inputs
        Handle<PolicyHolder> policyHolder_;
        Handle<Quote> annualPremium_;
        Handle<Quote> sumAssured_;
    };
}

#endif