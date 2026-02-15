#include <hl.h>
#include <pcre2.h>
#include <stdint.h>

/*
 * Dummy implementations for PCRE2 JIT functions to satisfy the linker
 * when JIT is disabled.
 */

int pcre2_jit_compile_16(pcre2_code_16 *code, uint32_t options) {
    return PCRE2_ERROR_JIT_BADOPTION;
}

void pcre2_jit_free_16(pcre2_code_16 *code) {
    /* Do nothing */
}

int pcre2_jit_match_16(const pcre2_code_16 *code, PCRE2_SPTR16 subject, PCRE2_SIZE length,
                     PCRE2_SIZE startoffset, uint32_t options,
                     pcre2_match_data_16 *match_data, pcre2_match_context_16 *mcontext) {
    return PCRE2_ERROR_JIT_BADOPTION;
}

const uint8_t * pcre2_default_tables_16 = NULL;

/*
 * Create aliases for symbols that the linker expects with a leading underscore.
 */
void _pcre2_jit_free_16(pcre2_code_16 *code) __attribute__((alias("pcre2_jit_free_16")));
extern const uint8_t * _pcre2_default_tables_16 __attribute__((alias("pcre2_default_tables_16")));
