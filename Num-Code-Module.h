#ifndef NUM_CODE_EXTERNAL_MODULE_H
#define NUM_CODE_EXTERNAL_MODULE_H

#include <stdint.h>

#if defined(_WIN32)
#define NUM_CODE_EXPORT __declspec(dllexport)
#else
#define NUM_CODE_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

NUM_CODE_EXPORT uint32_t num_code_module_call(
    uint32_t function_id,
    uint32_t argument_count,
    uint32_t argument0,
    uint32_t argument1,
    uint32_t *status
);

#ifdef __cplusplus
}
#endif

#endif
