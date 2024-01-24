MEMORY 
	{						         

/*dma ram*/
/*		 ram 	: ORIGIN = 0x20781000, LENGTH = 0x0007efff
		 eram   : ORIGIN = 0x20800000, LENGTH = 0
*/

/*fast ram*/
		 ram 	: ORIGIN = 0x30000000, LENGTH = 0x0007ffff
		 eram   : ORIGIN = 0x30080000, LENGTH = 0

/*sdram*/
/*		 ram 	: ORIGIN = 0x40000000, LENGTH = 0x0007ffff*/

/*system ram*/
/*		 ram 	: ORIGIN = 0x00002000, LENGTH = 0x00005fff*/

	}


SECTIONS
{


        .text :
	{
	    __text_start = . ;

	    *(.text)

	_etext = . ;
	__data_rom_start = ALIGN ( 4 ) ;
        } > ram

        .data :
	{
	_sdata = . ;
	__data_start = . ;

        *(.data)

	_edata = . ;
	edata = ALIGN( 0x10 ) ;
        } > ram

	.eram :
	{
	__ramend = . ;
	__bss_end__ = .;
    	_end = __bss_end__;
    	end = _end; 

	} > eram
}
