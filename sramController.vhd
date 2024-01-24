library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;


entity sramController is


port(

	reset:				in  	std_logic;
	clock:				in  	std_logic;
	
	
	--static ram interface
	gds0_7n:				out 	std_logic;
	gds8_15n:			out 	std_logic;
	gds16_23n:			out 	std_logic;
	gds24_31n:			out 	std_logic;
		
	gwen:					out	std_logic;
	goen:					out	std_logic;

	ga:					out 	std_logic_vector( 20 downto 0 );
	gd:					inout std_logic_vector( 31 downto 0 )
);


end sramController;

architecture behavior of sramController is

begin

end behavior;
