/* timer */

#include "bootpack.h"

#define PIT_CTRL	0x0043
#define PIT_CNT0	0x0040

struct TIMERCTL timerctl;

#define TIMER_FLAGS_ALLOC 1 /* allocated */
#define TIMER_FLAGS_USING 2 /* timer running */

void init_pit(void)
{
	int i;
	struct TIMER *t;
	io_out8(PIT_CTRL, 0x34);
	io_out8(PIT_CNT0, 0x9c);
	io_out8(PIT_CNT0, 0x2e);
	timerctl.count = 0;
	for (i = 0; i < MAX_TIMER; i++) {
		timerctl.timers0[i].flags = 0; /* unused */
	}
	t = timer_alloc(); /* get one */
	t->timeout = 0xffffffff;
	t->flags = TIMER_FLAGS_USING;
	t->next = 0; /* end */
	timerctl.t0 = t; /* right now there is only the sentinel, so it is at the front */
	timerctl.next = 0xffffffff; /* since there is only the sentinel, the next timeout is the sentinel's timeout */
	return;
}

struct TIMER *timer_alloc(void)
{
	int i;
	for (i = 0; i < MAX_TIMER; i++) {
		if (timerctl.timers0[i].flags == 0) {
			timerctl.timers0[i].flags = TIMER_FLAGS_ALLOC;
			timerctl.timers0[i].flags2 = 0;
			return &timerctl.timers0[i];
		}
	}
	return 0; /* not found */
}

void timer_free(struct TIMER *timer)
{
	timer->flags = 0; /* unused */
	return;
}

void timer_init(struct TIMER *timer, struct FIFO32 *fifo, int data)
{
	timer->fifo = fifo;
	timer->data = data;
	return;
}

void timer_settime(struct TIMER *timer, unsigned int timeout)
{
	int e;
	struct TIMER *t, *s;
	timer->timeout = timeout + timerctl.count;
	timer->flags = TIMER_FLAGS_USING;
	e = io_load_eflags();
	io_cli();
	t = timerctl.t0;
	if (timer->timeout <= t->timeout) {
	/* insert at the front */
		timerctl.t0 = timer;
		timer->next = t; /* the following is t */
		timerctl.next = timer->timeout;
		io_store_eflags(e);
		return;
	}
	for (;;) {
		s = t;
		t = t->next;
		if (timer->timeout <= t->timeout) {
		/* insert between s and t */
			s->next = timer; /* the one after s is timer */
			timer->next = t; /* the one after timer is t */
			io_store_eflags(e);
			return;
		}
	}
}

void inthandler20(int *esp)
{
	struct TIMER *timer;
	char ts = 0;
	(void) esp;
	io_out8(PIC0_OCW2, 0x60); /* notify the PIC that the IRQ-00 receive signal is finished */
	timerctl.count++;
	if (timerctl.next > timerctl.count) {
		return;
	}
	timer = timerctl.t0; /* first assign the front address to timer */
	for (;;) {
	/* all timers in the timers list are running, so flags are not checked */
		if (timer->timeout > timerctl.count) {
			break;
		}
		/* timeout */
		timer->flags = TIMER_FLAGS_ALLOC;
		if (timer != task_timer) {
			fifo32_put(timer->fifo, timer->data);
		} else {
			ts = 1; /* mt_timer timeout */
		}
		timer = timer->next; /* assign the next timer's address to timer */
	}
	timerctl.t0 = timer;
	timerctl.next = timer->timeout;
	if (ts != 0) {
		task_switch();
	}
	return;
}

int timer_cancel(struct TIMER *timer)
{
	int e;
	struct TIMER *t;
	e = io_load_eflags();
	io_cli(); /* disable timer state changes during setup */
	if (timer->flags == TIMER_FLAGS_USING) { /* does it need to be canceled? */
		if (timer == timerctl.t0) {
			/* cancel the first timer */
			t = timer->next;
			timerctl.t0 = t;
			timerctl.next = t->timeout;
		} else {
			/* cancel a non-first timer */
			/* find the timer before timer */
			t = timerctl.t0;
			for (;;) {
				if (t->next == timer) {
					break;
				}
				t = t->next;
			}
			t->next = timer->next;
			/* make the one before timer point to the one after timer */
		}
		timer->flags = TIMER_FLAGS_ALLOC;
		io_store_eflags(e);
		return 1; /* cancellation succeeded */
	}
	io_store_eflags(e);
	return 0; /* no cancellation needed */
}

void timer_cancelall(struct FIFO32 *fifo)
{
	int e, i;
	struct TIMER *t;
	e = io_load_eflags();
	io_cli(); /* disable timer state changes during setup */
	for (i = 0; i < MAX_TIMER; i++) {
		t = &timerctl.timers0[i];
		if (t->flags != 0 && t->flags2 != 0 && t->fifo == fifo) {
			timer_cancel(t);
			timer_free(t);
		}
	}
	io_store_eflags(e);
	return;
}
