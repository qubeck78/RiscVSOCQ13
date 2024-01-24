
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;


entity sdramController is
--generic(
--
--
--);
port(

	clk:						in		std_logic;
	reset:					in 	std_logic;
	
	--sdram interface
	sdramCke:				out 	std_logic;

	sdramA:					out 	std_logic_vector( 12 downto 0 );
	sdramBa:					out 	std_logic_vector( 1 downto 0 );

	sdramD:					inout std_logic_vector( 15 downto 0 );
		
	sdramDqml:				out 	std_logic;
	sdramDqmh:				out 	std_logic;
	
	sdramCas:				out 	std_logic;
	sdramRas:				out 	std_logic;
	
	sdramWen:				out 	std_logic;
	sdramCsn:				out 	std_logic;
	
	--cpu interface
	cpuSdramCE:				in 	std_logic;
	cpuSdramA:				in		std_logic_vector( 22 downto 0 );
	
	cpuDataOutForCPU:		out 	std_logic_vector( 31 downto 0 );
	cpuDataIn:				in 	std_logic_vector( 31 downto 0 );
	
	cpuWr:					in		std_logic;
	cpuDataMask:			in		std_logic_vector( 3 downto 0 );
	cpuSdramReady:			out	std_logic

	
);
end sdramController;


architecture behavior of sdramController is

type sdcState_T is ( sdcIdle, sdcInit0, sdcInit1, sdcInit2, sdcInit3, sdcInit4, sdcInit5, sdcInit6,
	sdcCpuRead0, sdcCpuRead1, sdcCpuRead2, sdcCpuRead3, sdcCpuRead4, sdcCpuRead5, sdcCpuRead6, sdcCpuRead7, sdcCpuRead8, 
	sdcCpuWrite0, sdcCpuWrite1, sdcCpuWrite2, sdcCpuWrite3, sdcCpuWrite4, sdcCpuWrite5, sdcCpuWrite6, sdcCpuWrite7, sdcCpuWrite8,
	sdcSubRefresh0, sdcSubRefresh1, sdcSubRefresh2, sdcSubRefresh3, sdcSubRefresh4, sdcSubRefresh5, sdcSubRefresh6
	);
	
signal sdcState:			sdcState_T;
signal sdcReturnState:	sdcState_T;

signal counter:			std_logic_vector( 15 downto 0 );

signal refreshCounter:	std_logic_vector( 11 downto 0 );
signal refreshRequest:	std_logic;
signal refreshDone:		std_logic;

begin

refreshGuard: process( all )
begin
	
	if reset = '1' then
	
		refreshCounter	<= ( others => '0' );
		refreshRequest	<= '0';
		
	else
	
		if rising_edge( clk ) then
		
		
			if refreshDone = '0' then
			
				if refreshCounter = x"000" then
		
					refreshRequest	<= '1';
		
				else
		
					refreshCounter	<= refreshCounter - 1;
		
				end if;
	
	
			else  --refreshDone = '1' 
			
				refreshRequest	<= '0';
				refreshCounter	<= x"320";		-- 8us @ 100Mhz
			
			end if;
			
		end if;
	
	end if;

end process;



sdc: process( all )

begin

	if reset = '1' then
	
		sdcState			<= sdcInit0;
		sdcReturnState	<= sdcIdle;
		
		counter			<= x"ffff";
		refreshDone		<= '0';
		
		sdramCke			<= '1';
		sdramDqmh		<= '1';
		sdramDqml		<= '1';
		sdramBa(0)		<= '1';
		sdramBa(1)		<= '1';
		
		sdramA			<= ( others => '0' );
		sdramD			<= ( others => 'Z' );
		
		sdramCsn			<= '0';
		sdramRas			<= '1';
		sdramCas			<= '1';
		sdramWen			<= '1';
		
		cpuSdramReady	<= '0';
		
	elsif rising_edge( clk ) then
	
		case sdcState is
		
			when sdcIdle =>
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';	
								
				--check refresh request

				if refreshRequest = '1' then
					
					--refresh request
					
					cpuSdramReady	<= '0';
					
					--call refresh
					sdcReturnState	<= sdcIdle;
					sdcState			<= sdcSubRefresh0;
								
				else
				
					--normal operation
				
					--check cpu access
					
					if cpuSdramCE = '1' then
					
						cpuSdramReady	<= '0';
						
						if cpuWr = '1' then
						
							--write
							
							sdcState		<= sdcCpuWrite0;
						else
						
							--read
														
							sdcState		<= sdcCpuRead0;
							
						end if;
					
					end if; 
			
				end if; -- counter = x"0000"
				
			when sdcInit0	=>
				
				if counter /= x"0000" then
				
					counter <= counter - 1;
					
				else
				
					sdcState	<= sdcInit1;
					
				end if;
			
			when sdcInit1 =>
			
				--precharge all banks
				
				sdramCsn			<= '0';
				sdramRas			<= '0';
				sdramCas			<= '1';
				sdramWen			<= '0';
				
				sdramBa			<= "00";
				sdramA( 10 ) 	<= '1';
				
				sdcState			<= sdcInit2;
				
			when sdcInit2 =>
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
		
				--call refresh
				sdcState			<= sdcSubRefresh0;
				sdcReturnState	<= sdcInit3;
				
			when sdcInit3 =>
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
		
				--call refresh
				sdcState			<= sdcSubRefresh0;
				sdcReturnState	<= sdcInit4;
			
			when sdcInit4	=>
			
				--mode register set
				
				sdramCsn			<= '0';
				sdramRas			<= '0';
				sdramCas			<= '0';
				sdramWen			<= '0';
				
				sdramBa			<= "00";
				
				--burst lenght = 2
				--addressing mode = sequential
				--cas latency = 2
				--burst read and burst write
				
				sdramA			<=  "000" & '0' & "00" & "010" & '0' & "001";
				
				sdcState			<= sdcInit5;
				
			when sdcInit5 =>
			
				sdramCsn			<= '1';

				sdcState		<= sdcInit6;
				
			when sdcInit6 =>
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
		
				counter			<= x"0190";			--8uS @ 50Mhz ( refresh time )
				sdcState			<= sdcIdle;
			
		
			--cpu read 
			
			when	sdcCpuRead0 =>
			
				--bank/row activation
				
				sdramDqmh		<= '0';
				sdramDqml		<= '0';

				
				--sdram data bus in
				sdramD			<= ( others => 'Z' );
				
				
				--row select, read, auto precharge

				
				--row / bank address ( cpu adr max downto 8 )
				
				sdramBa			<= cpuSdramA( 22 downto 21 );
				sdramA			<= cpuSdramA( 20 downto 8 );
				
				
				sdramCsn			<= '0';
				sdramRas			<= '0';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				
				sdcState			<= sdcCpuRead1;
				
			when sdcCpuRead1	=>
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcCpuRead2;
	
			when sdcCpuRead2	=>
	
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcCpuRead3;

			when sdcCpuRead3	=>
				
				--read
				
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '0';
				sdramWen			<= '1';
				
				--auto precharge
				sdramA(12 downto 9 )		<= "0010";
				
				--column address ( convert long address to word address)
				--a0-a8 - column address (word)
				--cpu addresses in longwords
				
				sdramA( 8 downto 0 ) 	<= cpuSdramA( 7 downto 0 ) & "0";
				
				sdcState			<= sdcCpuRead4;
				
			when sdcCpuRead4	=>
				
				-- cas latency 1
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcCpuRead5;

			when sdcCpuRead5	=>
				
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';

--				cpuDataOutForCPU( 15 downto 0 ) <= sdramD;	--cpuSdramA(15 downto 0 );
				
				sdcState			<= sdcCpuRead6;
				
			when sdcCpuRead6	=>
				
--				cpuDataOutForCPU( 31 downto 16 ) <= sdramD;	--cpuSdramA(15 downto 0 );
				cpuDataOutForCPU( 15 downto 0 ) <= sdramD;	--cpuSdramA(15 downto 0 );

				
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';

				
				sdcState			<= sdcCpuRead7;

			when sdcCpuRead7	=>

				cpuDataOutForCPU( 31 downto 16 ) <= sdramD;	--cpuSdramA(15 downto 0 );
	
				--notify cpu, data is ready
				cpuSdramReady	<= '1';
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';

				sdcState			<= sdcCpuRead8;

			when sdcCpuRead8	=>

				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
	
				if cpuSdramCE = '0' then
				
					cpuSdramReady	<= '0';
					sdcState			<= sdcIdle;
				
				end if;
				
			--cpu write
			
			when	sdcCpuWrite0 =>
			
				--bank/row activation
				
				sdramDqmh		<= '0';
				sdramDqml		<= '0';

				
				--sdram data bus in
				sdramD			<= ( others => 'Z' );
				
				
				--row select, read, auto precharge

				
				--row / bank address ( cpu adr max downto 8 )
				
				sdramBa			<= cpuSdramA( 22 downto 21 );
				sdramA			<= cpuSdramA( 20 downto 8 );
				
				
				sdramCsn			<= '0';
				sdramRas			<= '0';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				
				sdcState			<= sdcCpuWrite1;
				
			when sdcCpuWrite1	=>
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcCpuWrite2;
	
			when sdcCpuWrite2	=>
	
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcCpuWrite3;				
				
			
			when sdcCpuWrite3 =>
			
				--write
				
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '0';
				sdramWen			<= '0';
				
				--auto precharge
				sdramA(12 downto 9 )		<= "0010";
				
				--column address ( convert long address to word address)
				--a0-a8 - column address (word)
				--cpu addresses in longwords
				
				sdramA( 8 downto 0 ) 	<= cpuSdramA( 7 downto 0 ) & "0";
				
				--put data on bus (lo)
				sdramD			<= cpuDataIn( 15 downto 0 );
				sdramDqmh		<= not cpuDataMask( 1 );
				sdramDqml		<= not cpuDataMask( 0 );
				
				
				sdcState			<= sdcCpuWrite4;

			when sdcCpuWrite4 =>
				
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';

				--put data on bus (hi)
				sdramD			<= cpuDataIn( 31 downto 16 );
				sdramDqmh		<= not cpuDataMask( 3 );
				sdramDqml		<= not cpuDataMask( 2 );
				
				
				sdcState			<= sdcCpuWrite5;

			when sdcCpuWrite5	=>
	
				--notify cpu, data is written
				cpuSdramReady	<= '1';
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';

				sdcState			<= sdcCpuWrite6;

			when sdcCpuWrite6	=>

				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
	
				if cpuSdramCE = '0' then
				
					cpuSdramReady	<= '0';
					sdcState			<= sdcIdle;
				
				end if;

				
			--refresh subroutine
			
			when sdcSubRefresh0 =>
			
				--auto refresh
				sdramCsn			<= '0';
				sdramRas			<= '0';
				sdramCas			<= '0';
				sdramWen			<= '1';
				
				sdcState			<= sdcSubRefresh1;
				
			when sdcSubRefresh1 =>
			
				--clear refreshCounter
				
				refreshDone		<= '1';
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcSubRefresh2;
				
			when sdcSubRefresh2 =>
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcSubRefresh3;

			when sdcSubRefresh3 =>
			
				refreshDone		<= '0';
				
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcSubRefresh4;

			when sdcSubRefresh4 =>
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcSubRefresh5;

			when sdcSubRefresh5 =>
			
			
				--nop
				sdramCsn			<= '0';
				sdramRas			<= '1';
				sdramCas			<= '1';
				sdramWen			<= '1';
				
				sdcState			<= sdcReturnState;


			when others =>
			
				sdcState	<= sdcIdle;
		
			
		end case;
		
	end if;
	
end process;



end behavior;

