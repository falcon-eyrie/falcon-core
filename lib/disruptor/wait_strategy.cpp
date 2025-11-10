#include "wait_strategy.h"

namespace disruptor {

WaitStrategyInterface *CreateWaitStrategy(WaitStrategyOption wait_option) {
    switch (wait_option) {
    case kBlockingStrategy:
        return new BlockingStrategy();
    case kSleepingStrategy:
        return new SleepingStrategy();
    case kYieldingStrategy:
        return new YieldingStrategy();
    case kBusySpinStrategy:
        return new BusySpinStrategy();
    default:
        return NULL;
    }
}

}; // namespace disruptor
