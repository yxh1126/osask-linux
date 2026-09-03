/* stdlib.h - freestanding stdlib declarations for Haribote OS */

#if !defined(STDLIB_H)
#define STDLIB_H 1

#if !defined(NULL)
#define NULL ((void *)0)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

int putchar(int c);
void exit(int status);
int printf(char *format, ...);
void *malloc(int size);
void free(void *p);

int rand(void);
void srand(unsigned int seed);
int atoi(const char *s);
long strtol(const char *s, char **endptr, int base);

#if defined(__cplusplus)
}
#endif

#endif
