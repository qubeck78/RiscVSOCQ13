#ifndef _OSUIEVENTS_H
#define _OSUIEVENTS_H

#include "gfTypes.h"

#define OS_EVENT_TYPE_USB_MS_CONNECT	0x0001
#define OS_EVENT_TYPE_USB_MS_DISCONNECT	0x0002

#define OS_EVENT_TYPE_KEYBOARD_KEYPRESS 	0x0101
#define OS_EVENT_TYPE_KEYBOARD_KEYDOWN		0x0102
#define OS_EVENT_TYPE_KEYBOARD_KEYRELEASE	0x0103

#define OS_EVENT_TYPE_POINTER_MOVE      0x0201
#define OS_EVENT_TYPE_POINTER_KEYDOWN   0x0202
#define OS_EVENT_TYPE_POINTER_KEYUP		0x0203


typedef struct _tosUIEvent
{
	ushort	type;
	ulong   arg1;
	ulong   arg2;
	ulong	arg3;
	void    *obj;

}tosUIEvent;

//Store up to 32 user interaction events
#define OS_UI_EVENT_QUEUE_DEPTH 		32

typedef struct _tosUIEventQueue
{
    volatile ushort     lock;

	volatile tosUIEvent	queue[OS_UI_EVENT_QUEUE_DEPTH];

	volatile ulong      rdIdx;
	volatile ulong      wrIdx;
    volatile ushort     elementCount;

}tosUIEventQueue;



ulong osUIEventsInit( void );


ulong osPutUIEvent( tosUIEvent *event );

ulong osGetUIEvent( tosUIEvent *event );




#endif
