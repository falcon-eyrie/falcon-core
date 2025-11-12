#include "sequence.h"

namespace disruptor {

int64_t GetMinimumSequence(const std::vector<Sequence *> &sequences) {
    int64_t minimum = LONG_MAX;

    for (Sequence *sequence_ : sequences) {
        int64_t sequence = sequence_->sequence();
        minimum = minimum < sequence ? minimum : sequence;
    }

    return minimum;
};

}; // namespace disruptor
