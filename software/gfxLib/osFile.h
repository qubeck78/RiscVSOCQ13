#ifndef _OSFILE_H
#define _OSFILE_H

#include "gfTypes.h"


#ifdef _GFXLIB_WINDOWS

  #include <stdio.h>
  #include <vcl.h>

#endif

#ifdef _GFXLIB_ESP32_FFAT

  #include "FS.h"
  #include "FFat.h"

#endif

#ifdef _GFXLIB_STM32_FATFS

	/* FatFs includes component */
	#include "ff_gen_drv.h"
	#include "usbh_diskio.h"

#endif

#ifdef _GFXLIB_MC68K_FATFS

	/* FatFs includes component */

	#include "../ff.h"

#endif
#ifdef _GFXLIB_RISCV_FATFS

	/* FatFs includes component */

	#include "ff.h"
	#include "diskio.h"

#endif

#define OS_FILE_READ   1
#define OS_FILE_WRITE  2
#define OS_FILE_APPEND 4

typedef struct _tosFile
{

#ifdef _GFXLIB_WINDOWS
	FILE *fd;
#endif

#ifdef _GFXLIB_ESP32_FFAT
	File fd;
#endif

#ifdef _GFXLIB_STM32_FATFS
	FIL 	fd;
#endif

#ifdef _GFXLIB_MC68K_FATFS
	FIL		fd;
#endif

#ifdef _GFXLIB_RISCV_FATFS
	FIL		fd;
#endif

}tosFile;

ulong osFInit( void );
ulong osFOpen( tosFile *file, char *path, ulong mode );
ulong osFClose( tosFile *file );
ulong osFWrite( tosFile *file, uchar *buffer, ulong numBytesToWrite );
ulong osFRead( tosFile *file, uchar *buffer, ulong numBytesToRead, ulong *numBytesRead );
ulong osFGetS( tosFile *file, uchar *buffer, ulong maxLength );


#endif

