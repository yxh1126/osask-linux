/* mouse control code */

#include "bootpack.h"

struct FIFO32 *mousefifo;
int mousedata0;

void inthandler2c(int *esp)
/* interrupt from PS/2 mouse */
{
	int data;
	(void) esp;
	io_out8(PIC1_OCW2, 0x64); /* notify PIC1 that the IRQ-12 receive signal is finished */
	io_out8(PIC0_OCW2, 0x62); /* notify PIC0 that the IRQ-02 receive signal is finished */
	data = io_in8(PORT_KEYDAT);
	fifo32_put(mousefifo, data + mousedata0);
	return;
}

#define KEYCMD_SENDTO_MOUSE		0xd4
#define MOUSECMD_ENABLE			0xf4

void enable_mouse(struct FIFO32 *fifo, int data0, struct MOUSE_DEC *mdec)
{
	/* save the FIFO buffer information to global variables */
	mousefifo = fifo;
	mousedata0 = data0;
	/* enable the mouse */
	wait_KBC_sendready();
	io_out8(PORT_KEYCMD, KEYCMD_SENDTO_MOUSE);
	wait_KBC_sendready();
	io_out8(PORT_KEYDAT, MOUSECMD_ENABLE);
	/* if successful, ACK (0xfa) will be sent */
	mdec->phase = 0; /* waiting for the mouse's 0xfa stage */
	return;
}

int mouse_decode(struct MOUSE_DEC *mdec, unsigned char dat)
{
	if (mdec->phase == 0) {
		/* stage waiting for the mouse's 0xfa */
		if (dat == 0xfa) {
			mdec->phase = 1;
		}
		return 0;
	}
	if (mdec->phase == 1) {
		/* stage waiting for the first byte from the mouse */
		if ((dat & 0xc8) == 0x08) {
			mdec->buf[0] = dat;
			mdec->phase = 2;
		}
		return 0;
	}
	if (mdec->phase == 2) {
		/* stage waiting for the second byte from the mouse */
		mdec->buf[1] = dat;
		mdec->phase = 3;
		return 0;
	}
	if (mdec->phase == 3) {
		/* stage waiting for the third byte from the mouse */
		mdec->buf[2] = dat;
		mdec->phase = 1;
		mdec->btn = mdec->buf[0] & 0x07;
		mdec->x = mdec->buf[1];
		mdec->y = mdec->buf[2];
		if ((mdec->buf[0] & 0x10) != 0) {
			mdec->x |= 0xffffff00;
		}
		if ((mdec->buf[0] & 0x20) != 0) {
			mdec->y |= 0xffffff00;
		}
		mdec->y = - mdec->y; /* the mouse y direction is opposite in sign to the screen */
		return 1;
	}
	/* should not reach here */
	return -1;
}
