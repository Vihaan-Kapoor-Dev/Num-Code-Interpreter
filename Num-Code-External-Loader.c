#include <stdint.h>
#include <stddef.h>

#if defined(_WIN32)
#include <windows.h>
typedef HMODULE num_code_library_handle;
#else
#include <dlfcn.h>
typedef void *num_code_library_handle;
#endif

typedef uint32_t (*num_code_module_call_fn)(
    uint32_t function_id,
    uint32_t argument_count,
    uint32_t argument0,
    uint32_t argument1,
    uint32_t *status
);

static num_code_library_handle module_handles[256];
static num_code_module_call_fn module_calls[256];

static char *append_text(char *out, const char *text) {
    while (*text != '\0') {
        *out++ = *text++;
    }
    return out;
}

static char *append_u32(char *out, uint32_t value) {
    char digits[10];
    uint32_t count = 0;
    do {
        digits[count++] = (char)('0' + (value % 10u));
        value /= 10u;
    } while (value != 0u);
    while (count != 0u) {
        *out++ = digits[--count];
    }
    return out;
}

static void make_module_path(uint32_t module_id, char path[64]) {
    char *out = path;
#if defined(_WIN32)
    out = append_text(out, "modules/Num-Code-Module-");
    out = append_u32(out, module_id);
    out = append_text(out, ".dll");
#elif defined(__APPLE__)
    out = append_text(out, "./modules/Num-Code-Module-");
    out = append_u32(out, module_id);
    out = append_text(out, ".dylib");
#else
    out = append_text(out, "./modules/Num-Code-Module-");
    out = append_u32(out, module_id);
    out = append_text(out, ".so");
#endif
    *out = '\0';
}

static num_code_module_call_fn load_call_symbol(num_code_library_handle handle) {
#if defined(_WIN32)
    FARPROC symbol = GetProcAddress(handle, "num_code_module_call");
    num_code_module_call_fn function = 0;
    unsigned char *destination = (unsigned char *)&function;
    const unsigned char *source = (const unsigned char *)&symbol;
    size_t i;
    for (i = 0; i < sizeof(function) && i < sizeof(symbol); ++i) {
        destination[i] = source[i];
    }
    return function;
#else
    void *symbol = dlsym(handle, "num_code_module_call");
    num_code_module_call_fn function = 0;
    unsigned char *destination = (unsigned char *)&function;
    const unsigned char *source = (const unsigned char *)&symbol;
    size_t i;
    for (i = 0; i < sizeof(function) && i < sizeof(symbol); ++i) {
        destination[i] = source[i];
    }
    return function;
#endif
}

uint32_t num_code_external_import(uint32_t module_id) {
    char path[64];
    num_code_library_handle handle;
    num_code_module_call_fn function;

    if (module_id < 128u || module_id > 254u) {
        return 1u;
    }
    if (module_calls[module_id] != 0) {
        return 0u;
    }

    make_module_path(module_id, path);
#if defined(_WIN32)
    handle = LoadLibraryA(path);
#else
    handle = dlopen(path, RTLD_NOW | RTLD_LOCAL);
#endif
    if (handle == 0) {
        return 2u;
    }

    function = load_call_symbol(handle);
    if (function == 0) {
#if defined(_WIN32)
        FreeLibrary(handle);
#else
        dlclose(handle);
#endif
        return 3u;
    }

    module_handles[module_id] = handle;
    module_calls[module_id] = function;
    return 0u;
}

static uint64_t pack_result(uint32_t result, uint32_t status) {
    return ((uint64_t)status << 32) | (uint64_t)result;
}

static uint64_t call_external(
    uint32_t module_id,
    uint32_t function_id,
    uint32_t argument_count,
    uint32_t argument0,
    uint32_t argument1
) {
    uint32_t module_status = 0u;
    uint32_t result;
    num_code_module_call_fn function;

    if (module_id < 128u || module_id > 254u) {
        return pack_result(0u, 1u);
    }
    function = module_calls[module_id];
    if (function == 0) {
        return pack_result(0u, 4u);
    }

    result = function(function_id, argument_count, argument0, argument1, &module_status);
    if (module_status != 0u) {
        return pack_result(result, 5u);
    }
    return pack_result(result, 0u);
}

uint64_t num_code_external_call0(uint32_t module_id, uint32_t function_id) {
    return call_external(module_id, function_id, 0u, 0u, 0u);
}

uint64_t num_code_external_call1(uint32_t module_id, uint32_t function_id, uint32_t argument0) {
    return call_external(module_id, function_id, 1u, argument0, 0u);
}

uint64_t num_code_external_call2(
    uint32_t module_id,
    uint32_t function_id,
    uint32_t argument0,
    uint32_t argument1
) {
    return call_external(module_id, function_id, 2u, argument0, argument1);
}
