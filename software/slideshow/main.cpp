#include "main.h"
#include <cstring>
#include <climits>

#include "../gfxLib/bsp.h"
#include "../gfxLib/osAlloc.h"
#include "../gfxLib/osFile.h"
#include "../gfxLib/gfBitmap.h"
#include "../gfxLib/gfDrawing.h"
#include "../gfxLib/gfFont.h"
#include "../gfxLib/gfGouraud.h"
#include "../gfxLib/gfJPEG.h"
#include "../gfxLib/osUIEvents.h"
#include "../gfxLib/usbHID.h" 
#include "../gfxLib/ff.h" 

#define _MODE640

extern BSP_T 		*bsp;

extern	FATFS 		 fatfs;          // File system object defined in osFile.cpp

FRESULT 			 rc;             /* Result code */
FIL 				 fil;            /* File object */
DIR 				 dir;            /* Directory object */
FILINFO 			 fno;            /* File information object */ 


extern tgfTextOverlay		 con;
tgfBitmap 			 screen;
tgfBitmap 			 background;
tgfBitmap			 fileBmp;


char buf[128];
char lfnBuf[ 512 + 16];

int animLeds( int j )
{	
		switch( j % 2 )
		{
			case 0:
				bsp->gpoPort |= 0x00f0;
				bsp->gpoPort ^= 0x0010;
			
				break;

			case 1:

				bsp->gpoPort |= 0x00f0;
				bsp->gpoPort ^= 0x0020;
			
				break;

/*			case 2:
			
				bsp->gpoPort |= 0x00f0;
				bsp->gpoPort ^= 0x0040;

				break; 

			case 3:
		
				bsp->gpoPort |= 0x00f0;
				bsp->gpoPort ^= 0x0080;

				break;
*/
		}
		
	return 0;
} 



int slideshow()
{
	int 			rv;
	int 			i;
	int 			led;
	volatile ulong	j;
	short 			x;
	short			y;
	char 			extension[8];
	tosUIEvent		event;

	led = 0;
	
	do{
		
		rc = f_opendir(&dir, "0:img");
		
	
		do
		{
			lfnBuf[0] = 0;

			fno.lfname = &lfnBuf[0];
			fno.lfsize = 512;		
		
			rc = f_readdir(&dir, &fno);     // Read a directory item
			
			if( rc || !fno.fname[0] ) 
			{
				break; // Error or end of dir
			}
			
			if (fno.fattrib & AM_DIR)
			{
				/* toPrint( &con, (char*)"<dir> " );
				toPrint( &con, (char*)fno.fname );
				toPrint( &con, (char*)"\n" );
				
				//printf("   <dir>  %s\n", fno.fname);
				*/
			}else
			{

				i = strlen( fno.fname );
			
				if( i >= 4 )
				{
					extension[0] = fno.fname[ i - 4 ];
					extension[1] = fno.fname[ i - 3 ];
					extension[2] = fno.fname[ i - 2 ];
					extension[3] = fno.fname[ i - 1 ];
					extension[4] = 0;
					
					if( ( strcmp( extension, ".JPG" ) == 0 ) || ( strcmp( extension, ".GBM" ) == 0 ) )
					{
					
						animLeds( led++ );
						
						strcpy( buf, "0:img/" );
						strcat( buf, fno.fname );

						con.textAttributes = 0x0f;
						toCls( &con );
						con.textAttributes	= 0x8f;

						if( lfnBuf[0] != 0 )
						{
							toPrintF( &con, (char*)"Loading:%s", fno.lfname);
						}
						else
						{
							toPrintF( &con, (char*)"Loading:%s", fno.fname);						
						}
						if( fno.fname[ i - 3 ] == 'G' )
						{
							gfLoadBitmapFS( &fileBmp, buf );
						}
						else
						{
							gfLoadJPEGFS( &fileBmp, buf );						
						}
						
						if( screen.width > 320 )
						{						
							x  = ((ulong)randomNumber() ) % 320;
							y  = ((ulong)randomNumber() ) % 240;
							
						}
						else
						{
						
							x = ( screen.width / 2 ) - ( fileBmp.width / 2);
							y = ( screen.height / 2 ) - ( fileBmp.height / 2 );
						}

						for( i = 0; i < 256; i += 16 )
						{		
							do{}while( ! bsp->videoVSync ); 
							gfBlitBitmapA( &screen, &fileBmp, x, y, i );
						}
						
						
						gfBlitBitmap( &screen, &fileBmp, x, y );

						osFree( fileBmp.buffer );
						
						fileBmp.buffer			= NULL;
						con.textAttributes		= 0x0f;
						
						toCls( &con );
						con.textAttributes		= 0x8f;
						
						if( lfnBuf[0] != 0 )
						{
							toPrintF( &con, (char*)"%s %d\n", fno.lfname, fno.fsize );
						}
						else
						{
							toPrintF( &con, (char*)"%s %d\n", fno.fname, fno.fsize );						
						}
						
						for( i = 0; i < 100; i++ )
						{
							delayMs( 100 );
							
							usbHIDHandleEvents();
		
							if( !osGetUIEvent( &event ) )
							{ 
								if( event.type == OS_EVENT_TYPE_KEYBOARD_KEYPRESS )
								{
									switch( event.arg1 )
									{
									
										case _KEYCODE_PAUSE:

											reboot();
											break; 

										case _KEYCODE_F1:

											if( screen.width == 320 )
											{
												//switch to 640x480
												screen.width	= 640;
												screen.rowWidth	= 640;
												screen.height	= 480;

												setVideoMode( _VIDEOMODE_640_TEXT80_OVER_GFX );
											
												gfFillRect( &screen, 0, 0, screen.width - 1, screen.height - 1 , gfColor( 0, 0, 0 ) ); 

												//exit delay loop
												i = 100;
											}
											else
											{
												//switch to 320x240
												screen.width	= 320;
												screen.rowWidth	= 320;
												screen.height	= 240;

												setVideoMode( _VIDEOMODE_320_TEXT80_OVER_GFX );

												gfFillRect( &screen, 0, 0, screen.width - 1, screen.height - 1 , gfColor( 0, 0, 0 ) ); 

												//exit delay loop
												i = 100;
											}

											break;

										default:

											//exit delay loop
											i = 100;
											break;
									}
								}

							}
						}
					}
				}
			}
			
		}while( 1 );
	
	}while( 1 );

}



int main()
{
	int i;
	int rv;
	
	volatile int j;
		
	bspInit();
		
	
	#ifdef _MODE640
	
	setVideoMode( _VIDEOMODE_640_TEXT80_OVER_GFX );

	//alloc screen buffers
	screen.width 			= 640;	
	screen.rowWidth			= 640;	
	screen.height   		= 480;	
	
	#else
	
	setVideoMode( _VIDEOMODE_320_TEXT80_OVER_GFX );

	//alloc screen buffers
	screen.width 			= 320;
	screen.rowWidth			= 320;
	screen.height   		= 240;
	
	#endif
	
	screen.flags    		= 0;
	screen.transparentColor = 0;

	//always alloc 640x480 to allow screenmode switching
	screen.buffer           = osAlloc( 640 * 480 * 2, OS_ALLOC_MEMF_CHIP );	
	
	if( screen.buffer == NULL )
	{
		toPrint( &con, (char*)"\nCan't alloc screen\n" );
		do{}while( 1 );
	} 
		
	
	//display first buffer
	
	gfDisplayBitmap( &screen );

	gfFillRect( &screen, 0, 0, screen.width - 1, screen.height - 1 , gfColor( 0, 0, 0 ) ); 
	
	//init usb HID stack
	rv = usbHIDInit();
	
	if( rv )
	{
		toPrint( &con, ( char* )"USB HID init error\n" );
		
		rv = 1;
		return rv;

	}

	//init events queue
	osUIEventsInit();  

	//init filesystem
	rv = osFInit();


	if( rv )
	{
		toPrint( &con, ( char* )"SD init error!" );
		
		do{
		}while( 1 );		
	}
	else
	{
		toPrint( &con, ( char* )"SD init ok\n" );
	}
		


	slideshow();

} 