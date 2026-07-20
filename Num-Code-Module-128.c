#include "../Num-Code-Module.h"

NUM_CODE_EXPORT uint32_t num_code_module_call(
    uint32_t function_id,
    uint32_t argument_count,
    uint32_t argument0,
    uint32_t argument1,
    uint32_t *status
) {
    *status = 0u;

    if (function_id == 1u) {
        if (argument_count != 1u) {
            *status = 2u;
            return 0u;
        }
        return argument0 * 2u;
    }

    if (function_id == 2u) {
        if (argument_count != 2u) {
            *status = 2u;
            return 0u;
        }
        return argument0 + argument1;
    }

    if (function_id == 3u) {
        if (argument_count != 0u) {
            *status = 2u;
            return 0u;
        }
        return 42u;
    }

    *status = 1u;
    return 0u;
}
