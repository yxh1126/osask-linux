#include <apilib.h>

void HariMain(void)
{
	int i, timer;
	timer = api_alloctimer();
	api_inittimer(timer, 128);
	for (i = 20000000; i >= 20000; i -= i / 100) {
		/* 20KHz to 20Hz, the audible range for humans */
		/* i decreases by 1% each step */
		api_beep(i);
		api_settimer(timer, 1); /* 0.01 sec */
		if (api_getkey(1) != 128) {
			break;
		}
	}
	api_beep(0);
	api_end();
}
