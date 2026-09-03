/*
 * libc.c - Minimal C library for Haribote OS
 *
 * Replaces golibc.lib (proprietary, OSASKMP-compressed, unusable on Linux).
 * Provides freestanding implementations of string, memory, stdio, and stdlib
 * functions used by the kernel (bootpack.c) and applications (stdlib.c).
 *
 * All functions are compiled with gcc -m32 -ffreestanding -fno-builtin.
 * No external dependencies -- pure freestanding C.
 */

#include <stdarg.h>

/* ===== Memory functions ===== */

void *memset(void *s, int c, unsigned int n)
{
    unsigned char *p = (unsigned char *)s;
    while (n--)
        *p++ = (unsigned char)c;
    return s;
}

void *memcpy(void *dest, const void *src, unsigned int n)
{
    unsigned char *d = (unsigned char *)dest;
    const unsigned char *s = (const unsigned char *)src;
    while (n--)
        *d++ = *s++;
    return dest;
}

void *memmove(void *dest, const void *src, unsigned int n)
{
    unsigned char *d = (unsigned char *)dest;
    const unsigned char *s = (const unsigned char *)src;
    if (d < s) {
        while (n--)
            *d++ = *s++;
    } else {
        d += n;
        s += n;
        while (n--)
            *--d = *--s;
    }
    return dest;
}

int memcmp(const void *s1, const void *s2, unsigned int n)
{
    const unsigned char *p1 = (const unsigned char *)s1;
    const unsigned char *p2 = (const unsigned char *)s2;
    while (n--) {
        if (*p1 != *p2)
            return *p1 - *p2;
        p1++;
        p2++;
    }
    return 0;
}

void *memchr(const void *s, int c, unsigned int n)
{
    const unsigned char *p = (const unsigned char *)s;
    while (n--) {
        if (*p == (unsigned char)c)
            return (void *)p;
        p++;
    }
    return 0;
}

/* ===== String functions ===== */

unsigned int strlen(const char *s)
{
    const char *p = s;
    while (*p)
        p++;
    return p - s;
}

char *strcpy(char *dest, const char *src)
{
    char *d = dest;
    while ((*d++ = *src++))
        ;
    return dest;
}

char *strncpy(char *dest, const char *src, unsigned int n)
{
    unsigned int i;
    for (i = 0; i < n && src[i]; i++)
        dest[i] = src[i];
    for (; i < n; i++)
        dest[i] = '\0';
    return dest;
}

char *strcat(char *dest, const char *src)
{
    char *d = dest;
    while (*d)
        d++;
    while ((*d++ = *src++))
        ;
    return dest;
}

char *strncat(char *dest, const char *src, unsigned int n)
{
    char *d = dest;
    while (*d)
        d++;
    while (n-- && *src)
        *d++ = *src++;
    *d = '\0';
    return dest;
}

int strcmp(const char *s1, const char *s2)
{
    while (*s1 && *s1 == *s2) {
        s1++;
        s2++;
    }
    return (unsigned char)*s1 - (unsigned char)*s2;
}

int strncmp(const char *s1, const char *s2, unsigned int n)
{
    while (n && *s1 && *s1 == *s2) {
        s1++;
        s2++;
        n--;
    }
    if (n == 0)
        return 0;
    return (unsigned char)*s1 - (unsigned char)*s2;
}

char *strchr(const char *s, int c)
{
    while (*s) {
        if (*s == (char)c)
            return (char *)s;
        s++;
    }
    if ((char)c == '\0')
        return (char *)s;
    return 0;
}

char *strrchr(const char *s, int c)
{
    const char *last = 0;
    while (*s) {
        if (*s == (char)c)
            last = s;
        s++;
    }
    if ((char)c == '\0')
        return (char *)s;
    return (char *)last;
}

char *strstr(const char *haystack, const char *needle)
{
    unsigned int nlen = strlen(needle);
    if (nlen == 0)
        return (char *)haystack;
    while (*haystack) {
        if (strncmp(haystack, needle, nlen) == 0)
            return (char *)haystack;
        haystack++;
    }
    return 0;
}

unsigned int strspn(const char *s, const char *accept)
{
    const char *p = s;
    while (*p && strchr(accept, *p))
        p++;
    return p - s;
}

unsigned int strcspn(const char *s, const char *reject)
{
    const char *p = s;
    while (*p && !strchr(reject, *p))
        p++;
    return p - s;
}

char *strpbrk(const char *s, const char *accept)
{
    while (*s) {
        if (strchr(accept, *s))
            return (char *)s;
        s++;
    }
    return 0;
}

char *strdup(const char *s)
{
    unsigned int len = strlen(s) + 1;
    char *d = (char *)0; /* no malloc in libc; caller must provide */
    if (d) {
        memcpy(d, s, len);
    }
    return d;
}

/* ===== Stdlib functions ===== */

static unsigned long next = 1;

int rand(void)
{
    next = next * 1103515245 + 12345;
    return (unsigned int)(next / 65536) % 32768;
}

void srand(unsigned int seed)
{
    next = seed;
}

int atoi(const char *s)
{
    int sign = 1;
    int result = 0;

    while (*s == ' ' || *s == '\t')
        s++;

    if (*s == '-') {
        sign = -1;
        s++;
    } else if (*s == '+') {
        s++;
    }

    while (*s >= '0' && *s <= '9') {
        result = result * 10 + (*s - '0');
        s++;
    }

    return result * sign;
}

long strtol(const char *s, char **endptr, int base)
{
    long result = 0;
    int sign = 1;

    while (*s == ' ' || *s == '\t')
        s++;

    if (*s == '-') {
        sign = -1;
        s++;
    } else if (*s == '+') {
        s++;
    }

    if (base == 0) {
        if (*s == '0') {
            s++;
            if (*s == 'x' || *s == 'X') {
                s++;
                base = 16;
            } else {
                base = 8;
            }
        } else {
            base = 10;
        }
    } else if (base == 16 && *s == '0') {
        s++;
        if (*s == 'x' || *s == 'X')
            s++;
    }

    while (1) {
        int digit;
        if (*s >= '0' && *s <= '9')
            digit = *s - '0';
        else if (*s >= 'a' && *s <= 'z')
            digit = *s - 'a' + 10;
        else if (*s >= 'A' && *s <= 'Z')
            digit = *s - 'A' + 10;
        else
            break;

        if (digit >= base)
            break;

        result = result * base + digit;
        s++;
    }

    if (endptr)
        *endptr = (char *)s;

    return result * sign;
}

/* ===== sprintf / vsprintf ===== */

static char *write_char(char *buf, char c, int *count)
{
    if (buf) {
        *buf = c;
        return buf + 1;
    }
    (*count)++;
    return 0;
}

static char *write_str(char *buf, const char *s, int *count)
{
    while (*s) {
        buf = write_char(buf, *s, count);
        if (!buf)
            (*count)++;
        s++;
    }
    if (!buf)
        return 0;
    return buf;
}

static char *write_pad(char *buf, int n, char pad, int *count)
{
    while (n-- > 0) {
        buf = write_char(buf, pad, count);
        if (!buf)
            (*count)++;
    }
    if (!buf)
        return 0;
    return buf;
}

static char *write_num(char *buf, unsigned long val, int base, int upper,
                       int width, char pad, int *count)
{
    char digits[32];
    int pos = 0;
    const char *charset = upper
        ? "0123456789ABCDEF"
        : "0123456789abcdef";

    if (val == 0) {
        digits[pos++] = '0';
    } else {
        while (val > 0) {
            digits[pos++] = charset[val % base];
            val /= base;
        }
    }

    /* Pad to width */
    while (pos < width) {
        buf = write_char(buf, pad, count);
        if (!buf)
            return 0;
        width--;
    }

    /* Output digits in reverse */
    while (pos > 0) {
        buf = write_char(buf, digits[--pos], count);
        if (!buf)
            return 0;
    }

    return buf;
}

int vsprintf(char *buf, const char *fmt, va_list ap)
{
    char *start = buf;
    int count = 0;

    if (!buf) {
        /* Counting mode (for snprintf with NULL buffer) */
        start = 0;
    }

    while (*fmt) {
        if (*fmt != '%') {
            buf = write_char(buf, *fmt, &count);
            if (!buf) {
                count++;
            }
            fmt++;
            continue;
        }

        fmt++; /* skip '%' */

        /* Parse flags */
        char pad = ' ';
        int left_align = 0;
        while (*fmt == '0' || *fmt == '-' || *fmt == '+' || *fmt == ' ' || *fmt == '#') {
            if (*fmt == '0') pad = '0';
            if (*fmt == '-') left_align = 1;
            fmt++;
        }

        /* Parse width */
        int width = 0;
        while (*fmt >= '0' && *fmt <= '9') {
            width = width * 10 + (*fmt - '0');
            fmt++;
        }

        /* Parse precision (skip for now) */
        if (*fmt == '.') {
            fmt++;
            while (*fmt >= '0' && *fmt <= '9')
                fmt++;
        }

        /* Parse length modifiers */
        int is_long = 0;
        if (*fmt == 'l') {
            is_long = 1;
            fmt++;
            if (*fmt == 'l') {
                fmt++;
            }
        }

        /* Parse conversion */
        switch (*fmt) {
        case 'd':
        case 'i': {
            long val;
            if (is_long)
                val = va_arg(ap, long);
            else
                val = va_arg(ap, int);
            if (val < 0) {
                buf = write_char(buf, '-', &count);
                if (!buf) { count++; }
                val = -val;
                if (width > 0) width--;
            }
            buf = write_num(buf, (unsigned long)val, 10, 0, width, pad, &count);
            break;
        }
        case 'u': {
            unsigned long val;
            if (is_long)
                val = va_arg(ap, unsigned long);
            else
                val = va_arg(ap, unsigned int);
            buf = write_num(buf, val, 10, 0, width, pad, &count);
            break;
        }
        case 'x': {
            unsigned long val;
            if (is_long)
                val = va_arg(ap, unsigned long);
            else
                val = va_arg(ap, unsigned int);
            buf = write_num(buf, val, 16, 0, width, pad, &count);
            break;
        }
        case 'X': {
            unsigned long val;
            if (is_long)
                val = va_arg(ap, unsigned long);
            else
                val = va_arg(ap, unsigned int);
            buf = write_num(buf, val, 16, 1, width, pad, &count);
            break;
        }
        case 'o': {
            unsigned long val;
            if (is_long)
                val = va_arg(ap, unsigned long);
            else
                val = va_arg(ap, unsigned int);
            buf = write_num(buf, val, 8, 0, width, pad, &count);
            break;
        }
        case 'c': {
            char c = (char)va_arg(ap, int);
            buf = write_char(buf, c, &count);
            if (!buf) { count++; }
            break;
        }
        case 's': {
            char *s = va_arg(ap, char *);
            if (!s) s = "(null)";
            if (left_align) {
                buf = write_str(buf, s, &count);
                buf = write_pad(buf, width - (int)strlen(s), ' ', &count);
            } else {
                int slen = strlen(s);
                buf = write_pad(buf, width - slen, pad, &count);
                buf = write_str(buf, s, &count);
            }
            break;
        }
        case 'p': {
            unsigned int val = (unsigned int)va_arg(ap, unsigned int);
            buf = write_str(buf, "0x", &count);
            buf = write_num(buf, val, 16, 0, 8, '0', &count);
            break;
        }
        case '%':
            buf = write_char(buf, '%', &count);
            if (!buf) { count++; }
            break;
        default:
            buf = write_char(buf, '%', &count);
            if (!buf) { count++; }
            buf = write_char(buf, *fmt, &count);
            if (!buf) { count++; }
            break;
        }
        fmt++;
    }

    if (buf)
        *buf = '\0';
    else
        count++; /* for null terminator */

    return buf ? (buf - start) : count;
}

int sprintf(char *buf, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    int ret = vsprintf(buf, fmt, ap);
    va_end(ap);
    return ret;
}
