
#include "claim_strategy.h"

namespace disruptor {

ClaimStrategyInterface *CreateClaimStrategy(ClaimStrategyOption option,
                                            const int &buffer_size) {
    switch (option) {
    case kSingleThreadedStrategy:
        return new SingleThreadedStrategy(buffer_size);
    // case kMultiThreadedStrategy:
    //     return new MultiThreadedStrategy(buffer_size);
    default:
        return NULL;
    }
};

}; // namespace disruptor
