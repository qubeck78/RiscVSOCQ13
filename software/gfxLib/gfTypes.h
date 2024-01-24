#ifndef _GFTYPES_H
#define _GFTYPES_H

#define _GFXLIB_VERSION 20231230


//#define _GFXLIB_WINDOWS
//#define _GFXLIB_STM32_FATFS

//#define _GFXLIB_BIG_ENDIAN

#define _GFXLIB_RISCV_FATFS
#define _GFXLIB_HW_BLITTER_2D


//7.5MB
#define _SYSTEM_MEMORY_SIZE 	( 7864320 - 16)
#define _SYSTEM_MEMORY_BASE		0x20000000

//512 KB
#define _FASTRAM_MEMORY_SIZE	524288
#define _FASTRAM_MEMORY_BASE	0x30000000

//31.5 MB
#define _SDRAM_MEMORY_SIZE		0x01F80000
#define _SDRAM_MEMORY_BASE		0x40000000

typedef unsigned char	uchar;
typedef unsigned char	ubyte;
typedef unsigned short	ushort;
typedef unsigned long	ulong;

#ifndef NULL
#define NULL 0
#endif


typedef union _fixed_t
{
	signed long l;
	
	struct
	{
		signed short dec;
		unsigned short fract;
	}v;

}fixed_t;



#define gfAbs(x) ((x)>0?(x):-(x))



#endif
