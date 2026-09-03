/* FIFO */

#include "bootpack.h"

#define FLAGS_OVERRUN		0x0001

void fifo32_init(struct FIFO32 *fifo, int size, int *buf, struct TASK *task)
/* FIFO buffer initialization */
{
	fifo->size = size;
	fifo->buf = buf;
	fifo->free = size; /* empty */
	fifo->flags = 0;
	fifo->p = 0; /* write position */
	fifo->q = 0; /* read position */
	fifo->task = task; /* task to wake up when data is written */
	return;
}

int fifo32_put(struct FIFO32 *fifo, int data)
/* write data into the FIFO and accumulate it */
{
	if (fifo->free == 0) {
		/* no free space, overflow */
		fifo->flags |= FLAGS_OVERRUN;
		return -1;
	}
	fifo->buf[fifo->p] = data;
	fifo->p++;
	if (fifo->p == fifo->size) {
		fifo->p = 0;
	}
	fifo->free--;
	if (fifo->task != 0) {
		if (fifo->task->flags != 2) { /* if the task is sleeping */
			task_run(fifo->task, -1, 0); /* wake up the task */
		}
	}
	return 0;
}

int fifo32_get(struct FIFO32 *fifo)
/* get one data item from the FIFO */
{
	int data;
	if (fifo->free == fifo->size) {
	/* when the buffer is empty, return -1 */
		return -1;
	}
	data = fifo->buf[fifo->q];
	fifo->q++;
	if (fifo->q == fifo->size) {
		fifo->q = 0;
	}
	fifo->free++;
	return data;
}

int fifo32_status(struct FIFO32 *fifo)
/* report how much data is stored */
{
	return fifo->size - fifo->free;
}
