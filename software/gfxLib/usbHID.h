#ifndef _USBHID_H
#define _USBHID_H

#include "bsp.h"

#include "../gfxLib/osUIEvents.h"

#define SST_SHIFT     1
#define SST_CONTROL   2
#define SST_ALT       4

#define _KEYCODE_RIGHT		0x01
#define _KEYCODE_LEFT		0x02
#define _KEYCODE_DOWN		0x03
#define _KEYCODE_UP			0x04

#define _KEYCODE_BACKSPACE	0x08
#define _KEYCODE_TAB		0x09
#define _KEYCODE_ENTER		0x0a

#define _KEYCODE_ESC		0x1b

#define _KEYCODE_DELETE		0x7f
#define _KEYCODE_F1			0x80
#define _KEYCODE_F2			0x81
#define _KEYCODE_F3			0x82
#define _KEYCODE_F4			0x83
#define _KEYCODE_F5			0x84
#define _KEYCODE_F6			0x85
#define _KEYCODE_F7			0x86
#define _KEYCODE_F8			0x87
#define _KEYCODE_F9			0x88
#define _KEYCODE_F10		0x89
#define _KEYCODE_F11		0x8a
#define _KEYCODE_F12		0x8b
#define _KEYCODE_PGUP		0x8c
#define _KEYCODE_PGDOWN		0x8d
#define _KEYCODE_END		0x8e
#define _KEYCODE_INSERT		0x8f
#define _KEYCODE_HOME		0x90
#define _KEYCODE_CAPSLOCK	0x91
#define _KEYCODE_PRTSCR		0x92
#define _KEYCODE_SCRLOCK	0x93
#define _KEYCODE_PAUSE		0x94

int usbHIDInit( void );
int usbHIDHandleEvents( void );

#endif
