#include "PolicyHolder.h"

namespace QuantLib {
    PolicyHolder::PolicyHolder(const Date dateOfBirth, const Date inceptionDate)
    : dateOfBirth_(dateOfBirth), inceptionDate_(inceptionDate) {}
}