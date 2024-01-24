#include "shellUI.h"

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

extern FATFS			fatfs;			//fs object defined in osFile.cpp
extern tgfBitmap 		screen;
extern tgfTextOverlay	con;


FRESULT 			 	rc;             /* Result code */
FIL 				 	fil;                /* File object */
DIR 				 	dir;                /* Directory object */
FILINFO 			 	fno;            /* File information object */ 

extern long					selectorWindowIdx;
extern long					selectorCursorPos;
extern long					selectorWindowHeight;
extern char					selectorFileNames[26][_MAXFILENAMELENGTH + 1];
extern ulong				selectorFileLengths[26];


extern tgfBitmap				background;
extern char					path[256];

extern char 					lfnBuf[ 512 + 16];

int uiDrawStatusBar()
{
	int rv;

	rv = 0;

	toSetCursorPos( &con, 0, 0 );
	con.textAttributes	= 0xf0;

	toPrintF( &con, ( char* )"SHELL B20240106                         " );


	return rv;
}

int uiDrawSelectorWindowFrame()
{
	int 	rv;
	int 	i;
	int 	j;
	char	buf[50];

	rv = 0;

	toSetCursorPos( &con, 0, 1 );
	con.textAttributes	= 0x0f;

	
	buf[0] = 0xda;

	j = strlen( path );

	for( i = 0; i < 38; i++ )
	{

		if( i < j )
		{
			buf[ 1 + i ] = path[i];
		}
		else
		{
			buf[ 1 + i ] = 0xc4;
		}

	}

	buf[39] = 0xbf;
	buf[40] = 0x00;

	toPrint( &con, buf );

	for( i = 0; i < selectorWindowHeight; i++ )
	{
		toSetCursorPos( &con, 0, 2 + i );
		toPrint( &con, ( char* ) "\xb3" );
		toSetCursorPos( &con, 39, 2 + i );
		toPrint( &con, ( char* ) "\xb3" );
	}

	buf[0] = 0xc0;

	for( i = 0; i < 38; i++ )
	{
		buf[ 1 + i ] = 0xc4;
	}

	buf[39] = 0xd9;
	buf[40] = 0x00;

	toSetCursorPos( &con, 0, 2 + selectorWindowHeight );
	toPrint( &con, buf );

	return rv;
}


int uiDrawSelectorWindowContents()
{
	int 	rv;
	int 	i;
	int		j;
	char	buf[50];

	rv = 0;

	con.textAttributes	= 0x0f;
	for( i = 0; i < selectorWindowHeight; i++ )
	{
		strcpy( buf, selectorFileNames[i] );
		for( j = strlen( buf ); j < 38; j++ )
		{
			buf[j]		= ' ';
			buf[j+1] 	= 0;
		}

		if( selectorFileLengths[i] == 0xffffffff )
		{
			j = 33;
			buf[j++]	= '(';
			buf[j++]	= 'd';
			buf[j++]	= 'i';
			buf[j++]	= 'r';
			buf[j++]	= ')';
		}

		toSetCursorPos( &con, 1, 2 + i );

		if( selectorCursorPos == i )
		{
			con.textAttributes = 0x5f;
		}
		else
		{
			con.textAttributes = 0x0f;
		}

		toPrint( &con, buf );

	}

	return rv;
}


int uiReadDirAndFillSelectorWindowContents()
{
	int rv;
	int i;
	int j;

	rv = 0;

	//clear selector windows contents
	for( i = 0 ; i < selectorWindowHeight; i++ )
	{
		selectorFileNames[i][0] = 0x0;
		selectorFileLengths[i] = 0;

	}

	rc = f_opendir( &dir, path ); 

	lfnBuf[0] = 0;

	fno.lfname = &lfnBuf[0];
	fno.lfsize = 512;		
	
	i = 0;
	j = 0;

	do
	{
		lfnBuf[0] = 0;

		rc = f_readdir( &dir, &fno );     // Read a directory item
			
		if( rc || !fno.fname[0] ) 
		{		
			break;
		} 

		if( j >= selectorWindowIdx )
		{


			if( fno.lfname[0] != 0 )
			{
				strncpy( selectorFileNames[i], fno.lfname, _MAXFILENAMELENGTH );
				selectorFileNames[i][_MAXFILENAMELENGTH] = 0;	//ensure eos
			}
			else
			{
				//8.3 filename
				strcpy( selectorFileNames[i], fno.fname );
			}

			if( fno.fattrib & AM_DIR )
			{
				selectorFileLengths[i] = 0xffffffff;
			}
			else
			{
				selectorFileLengths[i] = fno.fsize;
			}

			i++;	//selector file name table index
		}

		j++;	//directory item index

	}while( i < selectorWindowHeight );


	return 0;
}

int uiDrawInfoWindow( char *title, char *contents )
{
	ulong	wy;
	char	buf[50];
	ulong	i;
	ulong	j;


	wy = ( con.height / 2 ) - 1;

	
	buf[0] = 0xda;

	j = strlen( title );

	for( i = 0; i < 36; i++ )
	{

		if( i < j )
		{
			buf[ 1 + i ] = title[i];
		}
		else
		{
			buf[ 1 + i ] = 0xc4;
		}

	}

	buf[37] = 0xbf;
	buf[38] = 0x00;
	
	toSetCursorPos( &con, 1, wy - 1);
	con.textAttributes	= 0x0e;
	toPrint( &con, buf );

	buf[0] = 0xb3;

	j = strlen( contents );

	for( i = 0; i < 36; i++ )
	{

		if( i < j )
		{
			buf[ 1 + i ] = contents[i];
		}
		else
		{
			buf[ 1 + i ] = ' ';
		}

	}

	buf[37] = 0xb3;
	buf[38] = 0x00;

	toSetCursorPos( &con, 1, wy );
	toPrint( &con, buf );


	buf[0] = 0xc0;

	for( i = 0; i < 36; i++ )
	{
		buf[ 1 + i ] = 0xc4;
	}

	buf[37] = 0xd9;
	buf[38] = 0x00;

	toSetCursorPos( &con, 1, wy + 1 );
	toPrint( &con, buf );

	con.textAttributes	= 0x0f;

	return 0;
}
