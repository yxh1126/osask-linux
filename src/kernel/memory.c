/* memory management */

#include "bootpack.h"

#define EFLAGS_AC_BIT		0x00040000
#define CR0_CACHE_DISABLE	0x60000000

unsigned int memtest(unsigned int start, unsigned int end)
{
	char flg486 = 0;
	unsigned int eflg, cr0, i;

	/* confirm whether the CPU is 386 or 486+ */
	eflg = io_load_eflags();
	eflg |= EFLAGS_AC_BIT; /* AC-bit = 1 */
	io_store_eflags(eflg);
	eflg = io_load_eflags();
	if ((eflg & EFLAGS_AC_BIT) != 0) {
		/* if it is a 386, even if AC is set to 1, the AC value will automatically return to 0 */
		flg486 = 1;
	}

	eflg &= ~EFLAGS_AC_BIT; /* AC-bit = 0 */
	io_store_eflags(eflg);

	if (flg486 != 0) {
		cr0 = load_cr0();
		cr0 |= CR0_CACHE_DISABLE; /* disable cache */
		store_cr0(cr0);
	}

	i = memtest_sub(start, end);

	if (flg486 != 0) {
		cr0 = load_cr0();
		cr0 &= ~CR0_CACHE_DISABLE; /* enable cache */
		store_cr0(cr0);
	}

	return i;
}

void memman_init(struct MEMMAN *man)
{
	man->frees = 0;    /* number of available items */
	man->maxfrees = 0; /* for observing availability: maximum value of frees */
	man->lostsize = 0; /* total size of memory that failed to be freed */
	man->losts = 0;    /* number of failed frees */
	return;
}

unsigned int memman_total(struct MEMMAN *man)
/* report the total amount of free memory */
{
	unsigned int t = 0;
	int i;
	for (i = 0; i < man->frees; i++) {
		t += man->free[i].size;
	}
	return t;
}

unsigned int memman_alloc(struct MEMMAN *man, unsigned int size)
/* allocate */
{
	unsigned int a;
	int i;
	for (i = 0; i < man->frees; i++) {
		if (man->free[i].size >= size) {
			/* found memory large enough */
			a = man->free[i].addr;
			man->free[i].addr += size;
			man->free[i].size -= size;
			if (man->free[i].size == 0) {
				/* if free[i] becomes 0, remove one available item */
				man->frees--;
				for (; i < man->frees; i++) {
					man->free[i] = man->free[i + 1]; /* struct assignment */
				}
			}
			return a;
		}
	}
	return 0; /* no available space */
}

int memman_free(struct MEMMAN *man, unsigned int addr, unsigned int size)
/* free */
{
	int i, j;
	/* to consolidate memory, free[] is sorted by addr */
	/* so first decide where it should be placed */
	for (i = 0; i < man->frees; i++) {
		if (man->free[i].addr > addr) {
			break;
		}
	}
	/* free[i - 1].addr < addr < free[i].addr */
	if (i > 0) {
		/* there is available memory before */
		if (man->free[i - 1].addr + man->free[i - 1].size == addr) {
			/* can be merged with the previous available memory */
			man->free[i - 1].size += size;
			if (i < man->frees) {
				/* there is also memory after */
				if (addr + size == man->free[i].addr) {
					/* can also be merged with the following available memory */
					man->free[i - 1].size += man->free[i].size;
					/* delete man->free[i] */
					/* after free[i] becomes 0, merge it into the previous one */
					man->frees--;
					for (; i < man->frees; i++) {
						man->free[i] = man->free[i + 1]; /* struct assignment */
					}
				}
			}
			return 0; /* success */
		}
	}
	/* cannot be merged with the previous available memory */
	if (i < man->frees) {
		/* there is more after */
		if (addr + size == man->free[i].addr) {
			/* can be merged with the following */
			man->free[i].addr = addr;
			man->free[i].size += size;
			return 0; /* success */
		}
	}
	/* can be merged with neither the previous nor the following */
	if (man->frees < MEMMAN_FREES) {
		/* move free[i] and after backward to free up some available space */
		for (j = man->frees; j > i; j--) {
			man->free[j] = man->free[j - 1];
		}
		man->frees++;
		if (man->maxfrees < man->frees) {
			man->maxfrees = man->frees; /* update maximum value */
		}
		man->free[i].addr = addr;
		man->free[i].size = size;
		return 0; /* success */
	}
	/* cannot move backward */
	man->losts++;
	man->lostsize += size;
	return -1; /* failure */
}

unsigned int memman_alloc_4k(struct MEMMAN *man, unsigned int size)
{
	unsigned int a;
	size = (size + 0xfff) & 0xfffff000;
	a = memman_alloc(man, size);
	return a;
}

int memman_free_4k(struct MEMMAN *man, unsigned int addr, unsigned int size)
{
	int i;
	size = (size + 0xfff) & 0xfffff000;
	i = memman_free(man, addr, size);
	return i;
}
