/* stdarg.h - freestanding va_list macros for Haribote OS (modern gcc) */

#if !defined(STDARG_H)
#define STDARG_H 1

#if defined(__cplusplus)
extern "C" {
#endif

typedef __builtin_va_list va_list;

#define va_start(v,l)  __builtin_va_start(v,l)
#define va_end(v)      __builtin_va_end(v)
#define va_arg(v,l)    __builtin_va_arg(v,l)
#define va_copy(d,s)   __builtin_va_copy(d,s)

#if defined(__cplusplus)
}
#endif

#endif
