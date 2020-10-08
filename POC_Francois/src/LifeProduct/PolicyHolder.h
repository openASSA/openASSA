#ifndef quantlib_policy_holder_hpp
#define quantlib_policy_holder_hpp

#include <ql/patterns/observable.hpp>
#include <ql/settings.hpp>
#include <ql/time/date.hpp>
#include <ql/time/daycounter.hpp>
#include <ql/time/daycounters/simpledaycounter.hpp>

namespace QuantLib {
    class PolicyHolder : public Observable {
      public:
        PolicyHolder(const Date dateofBirth, const Date inceptionDate);

        Date dateOfBirth() const { return dateOfBirth_; }
        Date inceptionDate() const { return inceptionDate_; }

        Integer age() const {
            return (Integer)simpleDayCounter_.yearFraction(dateOfBirth_,
                                                           Settings::instance().evaluationDate());
        }

        Integer age(Date date) const {
            return (Integer)simpleDayCounter_.yearFraction(dateOfBirth_, date);
        }

        Integer duration() const {
            return (Integer)simpleDayCounter_.yearFraction(inceptionDate_,
                                                           Settings::instance().evaluationDate());
        }

        Integer duration(Date date) const {
            return (Integer)simpleDayCounter_.yearFraction(inceptionDate_, date) + 1;
        }

      private:
        DayCounter simpleDayCounter_ = SimpleDayCounter();

        // Inputs
        Date dateOfBirth_;
        Date inceptionDate_;
    };
}

#endif