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


#include "../gfxLib/ff.h" 

#define _PERFORMANCE_TEST
#define _DMARAMTEST_ALL
#define _STOPONERROR

#define _SDRAMTEST

extern tgfTextOverlay	con;


volatile ulong	 fastRamTestArray[ 65536 / 4 ];
volatile ulong 	*testPtrL;
volatile ushort *testPtrW;
volatile uchar 	*testPtrB;
volatile ulong	 testAccL;
volatile ushort	 testAccW;
volatile uchar	 testAccB;


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


int memoryPerformanceTest( void *memPtr )
{
	int 	i,j;
	ulong	timerStart;
	ulong	timerEnd;
	ulong	testDuration;
	float	testResult;


	toPrintF( &con, (char*)"WB:" );
	testPtrB = (uchar*)memPtr;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		for( i = 0; i < 65536; i++ )
		{
			testPtrB[i] = 0xa5;
		}
	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	//time = /1000 [s]
	//amount = 16MB
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;
	
	toPrintF( &con, (char*)"%d.%04dMB/s W:", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );
	
	
	testPtrW = (ushort*)memPtr;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		for( i = 0; i < 32768; i++ )
		{
			testPtrW[i] = 0xaa55;
		}
	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;

	toPrintF( &con, (char*)"%d.%04dMB/s L:", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );
	
	testPtrL = (ulong*)memPtr;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		for( i = 0; i < 16384; i++ )
		{
			testPtrL[i] = 0x55aa55aa;
		}
	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;

	toPrintF( &con, (char*)"%d.%04dMB/s\n", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );
	
	toPrintF( &con, (char*)"RB:" );
	testPtrB = (uchar*)memPtr;
	
	testAccB = 0;
		
	timerStart = getTicks();

	for( j = 0; j < 256; j++ )
	{
		for( i = 0; i < 65536; i++ )
		{
			testAccB = testPtrB[i];
		}
	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	//time = /1000 [s]
	//amount = 16MB
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;
	
	toPrintF( &con, (char*)"%d.%04dMB/s W:", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );
	
	
	testPtrW = (ushort*)memPtr;
	testAccW = 0;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		for( i = 0; i < 32768; i++ )
		{
			testAccW = testPtrW[i];
		}
	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;

	toPrintF( &con, (char*)"%d.%04dMB/s L:", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );
	
	testPtrL = (ulong*)memPtr;
	testAccL = 0;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		for( i = 0; i < 16384; i++ )
		{
			testAccL = testPtrL[i];
		}
	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;

	toPrintF( &con, (char*)"%d.%04dMB/s\n", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );


	return 0;
}

int memoryBlitterPerformanceTest( void *memPtr )
{
	int 	i,j;
	ulong	timerStart;
	ulong	timerEnd;
	ulong	testDuration;
	float	testResult;
	
	toPrintF( &con, (char*)"BltW W:" );
	
	testPtrW = (ushort*)memPtr;
	testAccW = 0;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		blt->bltConfig0			= 0x0000;	//fill with value
			
		blt->bltDstAddress 		= ( ulong )(( (ulong)testPtrW - _SYSTEM_MEMORY_BASE ) / 2);
		blt->bltDstModulo		= 0;

		blt->bltTransferWidth	= 128;
		blt->bltTransferHeight	= 256 - 1;
			
		blt->bltValue			= j;
	
		blt->bltStatus			= 0x1;
	
		do{}while( ! ( blt->bltStatus & 1 ) ); 


	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;

	toPrintF( &con, (char*)"%d.%04dMB/s ", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );

	toPrintF( &con, (char*)"L:" );
	
	testPtrW = (ushort*)memPtr;
	testAccW = 0;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		blt->bltConfig0			= 0x2000;	//fill with value
			
		blt->bltDstAddress 		= ( ulong )(( (ulong)testPtrW - _SYSTEM_MEMORY_BASE ) / 4 );
		blt->bltDstModulo		= 0;

		blt->bltTransferWidth	= 64;
		blt->bltTransferHeight	= 256 - 1;
			
		blt->bltValue			= j;
	
		blt->bltStatus			= 0x1;
	
		do{}while( ! ( blt->bltStatus & 1 ) ); 


	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;

	toPrintF( &con, (char*)"%d.%04dMB/s\n", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );
	
	toPrintF( &con, (char*)"BltCpy W:" );
	
	testPtrW = (ushort*)memPtr;
	testAccW = 0;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		blt->bltConfig0			= 0x0002;	//copy
			
		blt->bltSrcAddress 		= ( ulong )(( (ulong)&testPtrW + 65536 - _SYSTEM_MEMORY_BASE ) / 2);
		blt->bltSrcModulo		= 0;

		blt->bltDstAddress 		= ( ulong )(( (ulong)testPtrW - _SYSTEM_MEMORY_BASE ) / 2);
		blt->bltDstModulo		= 0;

		blt->bltTransferWidth	= 128;
		blt->bltTransferHeight	= 256 - 1;
			
		blt->bltValue			= j;
	
		blt->bltStatus			= 0x1;
	
		do{}while( ! ( blt->bltStatus & 1 ) ); 


	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;

	toPrintF( &con, (char*)"%d.%04dMB/s ", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );

	toPrintF( &con, (char*)"L:" );

	testPtrW = (ushort*)memPtr;
	testAccW = 0;
	
	timerStart = getTicks();
	
	for( j = 0; j < 256; j++ )
	{
		blt->bltConfig0			= 0x2002;	//copy 32 bit
			
		blt->bltSrcAddress 		= ( ulong )(( (ulong)testPtrW + 65536 - _SYSTEM_MEMORY_BASE ) / 4 );
		blt->bltSrcModulo		= 0;
		
		blt->bltDstAddress 		= ( ulong )(( (ulong)testPtrW - _SYSTEM_MEMORY_BASE ) / 4 );
		blt->bltDstModulo		= 0;

		blt->bltTransferWidth	= 64;
		blt->bltTransferHeight	= 256 - 1;
			
		blt->bltValue			= j;
	
		blt->bltStatus			= 0x1;
	
		do{}while( ! ( blt->bltStatus & 1 ) ); 


	}
	timerEnd = getTicks();
	
	testDuration = timerEnd - timerStart;
	
	testResult	= testDuration / 1000.0f;	//time [s]
	testResult	= 16.0f / testResult;

	toPrintF( &con, (char*)"%d.%04dMB/s\n", (int)testResult, (int)( ( testResult - (int)testResult ) * 10000.0 ) );
	

	return 0;
}
int memoryTestL( void *memPtr, ulong memLength )
{
	ulong 	i;
	ulong 	j;
	int		rv;
	
	volatile ulong 	*memPtrL;
	ulong 	error;
	ulong 	value;
	ulong 	expectedValue;
	
	memPtrL = (ulong*)memPtr;

	#ifdef _DMARAMTEST_ALL
	
	toPrintF( &con, (char*)"Filling 0 " );
	
	for( i = 0; i < memLength; i++ )
	{
		memPtrL[i] = 0;
	}

	toPrintF( &con, (char*)"checking " );
	
	error = 0;
	for( i = 0; i < memLength; i++ )
	{
		value = memPtrL[i];
		if( value != 0 )
		{
			toPrintF( &con, (char*)"error@ 0x%04x - 0x%04x", i, value );
			error = 1;
		}
	}
	
	rv = error;
	
	if( !error )
	{
		toPrintF( &con, (char*)"ok\n");
	}
	else
	{
		toPrintF( &con, (char*)"\n");
	}
	
	
	toPrintF( &con, (char*)"Pattern 0xaa55aa55 " );
	
	for( i = 0; i < memLength; i++ )
	{
		memPtrL[i] = 0xaa55aa55;
	}

	toPrintF( &con, (char*)"checking " );
	
	error = 0;
	for( i = 0; i < memLength; i++ )
	{
		value = memPtrL[i];
		if( value != 0xaa55aa55 )
		{
			toPrintF( &con, (char*)"error@ 0x%04x - 0x%04x", i, value );
			error = 1;
		}
	}
	
	rv |= error;
	
	if( !error )
	{
		toPrintF( &con, (char*)"ok\n");
	}
	else
	{
		toPrintF( &con, (char*)"\n");
	}

	toPrintF( &con, (char*)"Pattern 0x55aa55aa " );
	
	for( i = 0; i < memLength; i++ )
	{
		memPtrL[i] = 0x55aa55aa;
	}

	toPrintF( &con, (char*)"checking " );
	
	error = 0;
	for( i = 0; i < memLength; i++ )
	{
		value = memPtrL[i];
		if( value != 0x55aa55aa )
		{
			toPrintF( &con, (char*)"error@ 0x%04x - 0x%04x", i, value );
			error = 1;
		}
	}
	
	rv |= error;
	if( !error )
	{
		toPrintF( &con, (char*)"ok\n");
	}
	else
	{
		toPrintF( &con, (char*)"\n");
	}

	toPrintF( &con, (char*)"Noise 0xffffffff 0x00000000 " );
	
	for( i = 0; i < memLength; i++ )
	{
		for( j = 0; j < 32; j++ )
		{
			memPtrL[i] = 0xffffffff;
			memPtrL[i] = 0x00000000;			
		}
		animLeds( i >> 12 );
	
	}

	toPrintF( &con, (char*)"checking " );
	
	error = 0;
	for( i = 0; i < memLength; i++ )
	{
		value = memPtrL[i];
		if( value != 0x00000000 )
		{
			toPrintF( &con, (char*)"error@ 0x%04x - 0x%04x", i, value );
			error = 1;
		}
	}
	
	rv |= error;
	if( !error )
	{
		toPrintF( &con, (char*)"ok\n");
	}
	else
	{
		toPrintF( &con, (char*)"\n");
	}

	toPrintF( &con, (char*)"Noise 0xaaaaaaaa 0x55555555 " );
	
	for( i = 0; i < memLength; i++ )
	{
		for( j = 0; j < 32; j++ )
		{
			memPtrL[i] = 0xaaaaaaaa;
			memPtrL[i] = 0x55555555;			
		}
		
		animLeds( i >> 12 );
	}

	toPrintF( &con, (char*)"checking " );
	
	error = 0;
	for( i = 0; i < memLength; i++ )
	{
		value = memPtrL[i];
		if( value != 0x55555555 )
		{
			toPrintF( &con, (char*)"error@ 0x%04x - 0x%04x", i, value );
			error = 1;
		}
	}
	
	rv |= error;
	if( !error )
	{
		toPrintF( &con, (char*)"ok\n");
	}
	else
	{
		toPrintF( &con, (char*)"\n");
	}
	#endif
	
	toPrintF( &con, (char*)"Pattern i, !i " );
	
	for( i = 0; i < memLength; i++ )
	{
	
		if( i & 1 )
		{
			memPtrL[i] = i ^ 0xffffffff;
			memPtrL[i] = i;
		}
		else
		{
			memPtrL[i] = i;
			memPtrL[i] = i ^ 0xffffffff;		
		}
		animLeds( i >> 15 );
	}

	toPrintF( &con, (char*)"checking " );
	
	error = 0;
	for( i = 0; i < memLength; i++ )
	{
		value = memPtrL[i];
		
		if( i & 1 )
		{
			expectedValue = i;
		}
		else
		{
			expectedValue = i ^ 0xffffffff;		
		}
		
		if( value != expectedValue )
		{
			toPrintF( &con, (char*)"error@ 0x%04x - exp:0x%04x real:0x%04x\nRechecking ", i, expectedValue, value );
			error = 1;
		
		
			for( j = 0; j < 65536; j++ )
			{
				value = memPtrL[i];
				if( value == expectedValue )
				{
					toPrintF( &con, (char*)"ok at %d try\n", j + 1 );
					break;
				}
			}
			if( j == 65536 )
			{
				toPrintF( &con, (char*)"Still bad\nWriting correct value, checking " );
			
				memPtrL[i] = expectedValue;
			
				value = memPtrL[i];
			
				if( value == expectedValue )
				{
					toPrintF( &con, (char*)"ok\n" );
				}
				else
				{
					toPrintF( &con, (char*)"still bad\n" );			
				}
			}
		}
	}
	
	rv |= error;
	if( !error )
	{
		toPrintF( &con, (char*)"ok\n");
	}
	else
	{
		toPrintF( &con, (char*)"\n");
	}
	
	return rv;
}

int main()
{
	int 	i,j;
	int 	rv;
	
	bspInit();
	setVideoMode( _VIDEOMODE_TEXT40_ONLY );
			
	con.textAttributes = 0x0f; 
			
	toPrint( &con, (char*)"MemoryTest B20231118\n\n" );
	
	#ifdef _PERFORMANCE_TEST
	
	toPrint( &con, (char*)"Checking memory performance\n" );
	
	con.textAttributes = 0x01;
	toPrintF( &con, (char*)"FastRam\n" );
	con.textAttributes = 0x0f;

	memoryPerformanceTest( (void*)fastRamTestArray );

	#ifdef _SDRAMTEST
	con.textAttributes = 0x02;
	toPrintF( &con, (char*)"SDRam\n" );
	con.textAttributes = 0x0f;

	memoryPerformanceTest( (void*)_SDRAM_MEMORY_BASE );
	#endif


	con.textAttributes = 0x02;
	toPrintF( &con, (char*)"DMARam text mode only\n" );
	con.textAttributes = 0x0f;
	memoryPerformanceTest( (void*)_SYSTEM_MEMORY_BASE );
	memoryBlitterPerformanceTest( (void*)_SYSTEM_MEMORY_BASE );

	setVideoMode( _VIDEOMODE_320_TEXT40_OVER_GFX );
	con.textAttributes = 0x03;
	toPrintF( &con, (char*)"DMARam - 320x240\n" );
	con.textAttributes = 0x0f;
	memoryPerformanceTest( (void*)_SYSTEM_MEMORY_BASE );
	memoryBlitterPerformanceTest( (void*)_SYSTEM_MEMORY_BASE );

	setVideoMode( _VIDEOMODE_640_TEXT40_OVER_GFX );
	con.textAttributes = 0x05;
	toPrintF( &con, (char*)"DMARam - 640x480\n" );
	con.textAttributes = 0x0f;
	memoryPerformanceTest( (void*)_SYSTEM_MEMORY_BASE );
	memoryBlitterPerformanceTest( (void*)_SYSTEM_MEMORY_BASE );
	
	#endif
 
	#ifdef _SDRAMTEST
	
	con.textAttributes = 0x06;
	toPrintF( &con, (char*)"SDRam test - 320x240\n" );
	con.textAttributes = 0x8f;	
		
	rv = memoryTestL( (void *)_SDRAM_MEMORY_BASE, 1048576 * 2 );
	
	#ifdef _STOPONERROR
	if( rv )
	{
		do{}while( 1 );
	}
	#endif
	
	#endif
	
 
 
	do
	{
		setVideoMode( _VIDEOMODE_320_TEXT40_OVER_GFX );
		con.textAttributes = 0x06;
		toPrintF( &con, (char*)"DMARam test - 320x240\n" );
		con.textAttributes = 0x8f;	
		
		rv = memoryTestL( (void *)_SYSTEM_MEMORY_BASE, 1048576 * 2 );
	
		#ifdef _STOPONERROR
		if( rv )
		{
			do{}while( 1 );
		}
		#endif
		
		setVideoMode( _VIDEOMODE_640_TEXT40_OVER_GFX );
		con.textAttributes = 0x06;
		toPrintF( &con, (char*)"DMARam test - 640x480\n" );
		con.textAttributes = 0x8f;	
		
		rv = memoryTestL( (void *)_SYSTEM_MEMORY_BASE, 1048576 * 2 );

		#ifdef _STOPONERROR
		if( rv )
		{
			do{}while( 1 );
		}
		#endif
		
	}while( 1 );
	
} 