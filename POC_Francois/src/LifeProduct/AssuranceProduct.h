#ifndef quantlib_assurance_product_hpp
#define quantlib_assurance_product_hpp

#include <ql/instrument.hpp>
#include <ql/termstructures/credit/defaultprobabilityhelpers.hpp>
#include <ql/termstructures/defaulttermstructure.hpp>
#include <ql/termstructures/yieldtermstructure.hpp>
#include <ql/time/schedule.hpp>

#include <PolicyDetails.h>

namespace QuantLib {
    class AssuranceProduct : public Instrument {
      public:
        AssuranceProduct(const Handle<PolicyDetails>& policyDetails,
                         const Handle<YieldTermStructure>& yieldTS,
                         const Handle<DefaultProbabilityTermStructure>& mortality,
                         const Handle<DefaultProbabilityTermStructure>& lapses);

        Handle<PolicyDetails> policyDetails() const { return policyDetails_; }

        Real premiumNPV() const {
            calculate();
            return premiumNPV_;
        }

        Real benefitNPV() const {
            calculate();
            return benefitNPV_;
        }

      private:
        Calendar calendar_ = NullCalendar();
        bool isExpired() const { return false; }
        void performCalculations() const;

        Real GetLapseRate(const Date projectionDate) const;
        Real GetMortalityRate(const Date projectionDate) const;

        mutable Real premiumNPV_;
        mutable Real benefitNPV_;

        // calculated values
        // mutable Real npv_;

        // Inputs
        Handle<PolicyDetails> policyDetails_;

        Handle<YieldTermStructure> yieldTS_;
        Handle<DefaultProbabilityTermStructure> mortality_;
        Handle<DefaultProbabilityTermStructure> lapses_;
    };
}

#endif