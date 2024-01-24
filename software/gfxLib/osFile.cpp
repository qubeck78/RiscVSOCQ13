
#include "osFile.h"


#ifdef _GFXLIB_RISCV_FATFS

#include "bsp.h"

FATFS 			 	 	fatfs;            /* File system object */

#endif

ulong osFInit( void )
{
	int rv;
	int retryCount;
	
	#if defined( _GFXLIB_RISCV_FATFS )
	
	rv = disk_initialize( 0 );

	if( rv )
	{		
	
		retryCount = 10;
		
		do{
			delayMs( 1000 );
		
			rv = disk_initialize( 0 );
			
			if( retryCount )
			{
				retryCount--;
			}
			else
			{
				//can't initialize sd
				return 1;
			}
			
		}while( rv );
		
	}
	
	f_mount( 0, &fatfs );     /* Register volume work area (never fails) */   

	return 0;

	#else
	
		return 1;	//not implemented

	#endif
}

ulong osFOpen( tosFile *file, char *path, ulong mode )
{
	#ifdef _GFXLIB_WINDOWS

	char    winMode[8];

	#endif

	#ifdef _GFXLIB_STM32_FATFS

	FRESULT	res;
    BYTE    stmMode;
	#endif

	#ifdef _GFXLIB_MC68K_FATFS
	FRESULT	res;
    BYTE    stmMode;
	#endif

	#ifdef _GFXLIB_RISCV_FATFS
	FRESULT	res;
    BYTE    stmMode;
	#endif

	if( !file )
	{
		return 1;
	}

	#ifdef _GFXLIB_WINDOWS

	switch( mode )
	{
		case OS_FILE_READ:

			strcpy( winMode, "rb" );
			break;

		case OS_FILE_WRITE:

			strcpy( winMode, "wb" );
			break;

		case OS_FILE_APPEND:

			strcpy( winMode, "ab" );
			break;

		default:

			return 2;

	}


	file->fd = fopen( path, winMode );

	if( file->fd )
	{
		return 0;
	}
	else
	{
		return 3;
	}

	#endif


	#ifdef _GFXLIB_STM32_FATFS

	switch( mode )
	{
		case OS_FILE_READ:

			stmMode = FA_READ | FA_OPEN_EXISTING;
			break;

		case OS_FILE_WRITE:

			stmMode = FA_WRITE | FA_CREATE_ALWAYS;
			break;

		case OS_FILE_APPEND:

            stmMode = FA_OPEN_APPEND | FA_OPEN_EXISTING;
			break;

		default:

			return 2;

	}



	res = f_open( &file->fd, path, stmMode );

	if( res == FR_OK )
	{
		return 0;
	}
	else
	{
		return 3;
	}


	#endif

	#ifdef _GFXLIB_MC68K_FATFS

	switch( mode )
	{
		case OS_FILE_READ:

			stmMode = FA_READ | FA_OPEN_EXISTING;
			break;

		case OS_FILE_WRITE:

			stmMode = FA_WRITE | FA_CREATE_ALWAYS;
			break;

		case OS_FILE_APPEND:

			return 2;	//not supported
			break;

		default:

			return 2;
			break;
	}



	res = f_open( &file->fd, path, stmMode );

	if( res == FR_OK )
	{
		return 0;
	}
	else
	{
		return 3;
	}
	#endif
	
	#ifdef _GFXLIB_RISCV_FATFS

	switch( mode )
	{
		case OS_FILE_READ:

			stmMode = FA_READ | FA_OPEN_EXISTING;
			break;

		case OS_FILE_WRITE:

			stmMode = FA_WRITE | FA_CREATE_ALWAYS;
			break;

		case OS_FILE_APPEND:

			return 2;	//not supported
			break;

		default:

			return 2;
			break;
	}



	res = f_open( &file->fd, path, stmMode );

	if( res == FR_OK )
	{
		return 0;
	}
	else
	{
		return 3;
	}
	#endif
	
	return 255;
}

ulong osFClose( tosFile *file )
{

	if( !file )
	{
		return 1;
	}


	#ifdef _GFXLIB_WINDOWS

	fclose( file->fd );

	return 0;

	#endif

	#ifdef _GFXLIB_STM32_FATFS

	f_close( &file->fd );

	return 0;

	#endif
	
	#ifdef _GFXLIB_MC68K_FATFS
	
	f_close( &file->fd );

	return 0;

	#endif
	
	#ifdef _GFXLIB_RISCV_FATFS
	
	f_close( &file->fd );

	return 0;

	#endif
	return 255;
}

ulong osFWrite( tosFile *file, uchar *buffer, ulong numBytesToWrite )
{
	#ifdef _GFXLIB_STM32_FATFS

	FRESULT res;
	UINT    nbw;

	#endif

	#ifdef _GFXLIB_MC68K_FATFS

	FRESULT res;
	UINT    nbw;

	#endif
	
	#ifdef _GFXLIB_RISCV_FATFS

	FRESULT res;
	UINT    nbw;

	#endif
	
	if( ( !file ) || ( !buffer ) )
	{
		return 1;
	}

	#ifdef _GFXLIB_WINDOWS

	if ( fwrite( buffer, 1, numBytesToWrite, file->fd ) != numBytesToWrite )
	{
		return 2;
	}
	else
	{
		return 0;
	}

	#endif


	#ifdef _GFXLIB_STM32_FATFS

	res = f_write( &file->fd, buffer, numBytesToWrite, &nbw );

	if( res == FR_OK )
	{
		return 0;
	}
	else
	{
		return 2;
	}


	#endif

	#ifdef _GFXLIB_MC68K_FATFS

	res = f_write( &file->fd, buffer, numBytesToWrite, &nbw );

	if( res == FR_OK )
	{
		return 0;
	}
	else
	{
		return 2;
	}

	#endif
	
	#ifdef _GFXLIB_RISCV_FATFS

	res = f_write( &file->fd, buffer, numBytesToWrite, &nbw );

	if( res == FR_OK )
	{
		return 0;
	}
	else
	{
		return 2;
	}

	#endif
	
	return 255;
}

ulong osFRead( tosFile *file, uchar *buffer, ulong numBytesToRead, ulong *numBytesRead )
{

	#ifdef _GFXLIB_WINDOWS

	int 	nbr;

	#endif

	#ifdef _GFXLIB_STM32_FATFS

	FRESULT res;
	UINT    nbr;

	#endif

	#ifdef _GFXLIB_MC68K_FATFS

	FRESULT res;
	UINT    nbr;

	#endif

	#ifdef _GFXLIB_RISCV_FATFS

	FRESULT res;
	UINT    nbr;

	#endif

	if( ( !file ) || ( !buffer ) )
	{
		return 1;
	}


	#ifdef _GFXLIB_WINDOWS

	nbr = fread( buffer, 1, numBytesToRead, file->fd );

	if( numBytesRead )
	{
		*numBytesRead = nbr;
	}

	if( nbr == numBytesToRead )
	{
		return 0;
	}
	else
	{
		return 2;
	}


	#endif


	#ifdef _GFXLIB_STM32_FATFS

	res = f_read( &file->fd, buffer, numBytesToRead, &nbr );

	if( numBytesRead )
	{
		*numBytesRead = nbr;

		return 0;
	}
	else
	{
		if( nbr == numBytesToRead )
		{
			return 0;
		}
		else
		{
			return 2;
		}
	}


	#endif

	#ifdef _GFXLIB_MC68K_FATFS

	res = f_read( &file->fd, buffer, numBytesToRead, &nbr );

	if( numBytesRead )
	{
		*numBytesRead = nbr;

		return 0;
	}
	else
	{
		if( nbr == numBytesToRead )
		{
			return 0;
		}
		else
		{
			return 2;
		}
	}


	#endif

	#ifdef _GFXLIB_RISCV_FATFS

	res = f_read( &file->fd, buffer, numBytesToRead, &nbr );

	if( numBytesRead )
	{
		*numBytesRead = nbr;
	}

		if( nbr == numBytesToRead )
		{
			return 0;
		}
		else
		{
			return 2;
		}


	#endif

	return 255;
}


ulong osFGetS( tosFile *file, uchar *buffer, ulong maxLength )
{
	uchar rbuf[4];
	ulong idx;
	ulong rv;
	ulong nbr;

	idx = 0;

	buffer[idx] = 0;
	do
	{
		rv = osFRead( file, rbuf, 1, &nbr );

		if( !rv )
		{
			if(( rbuf[0] == 0x0a ) || ( rbuf[0] == 0x0d ) )
			{
				break;
			}

			if( idx < maxLength - 1 )
			{
				buffer[idx++] = rbuf[0];
				buffer[idx] = 0;

			}

		}

	}while( !rv );


	return rv;
}
