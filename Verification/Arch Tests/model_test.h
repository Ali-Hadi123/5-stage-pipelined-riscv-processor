// model_test.h
//
// DUT-side glue header. riscv-arch-test source files (across both the
// old RISCOF-era layout and the newer ACT4 layout) pull in a DUT-specific
// header with this name from the DUT's config/port directory to get the
// RVMODEL_* macros used by test_macros.h / arch_test.h.
//
// Check the version of riscv-arch-test you actually clone - if it expects
// a different filename or extra hooks (e.g. XLEN, RVTEST_CASE handling),
// add them here rather than editing the upstream test sources.

#ifndef MODEL_TEST_H
#define MODEL_TEST_H

#include "rvmodel_macros.h"

#endif // MODEL_TEST_H
