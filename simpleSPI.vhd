library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity simpleSPI is
port(

	reset:                          	in  std_logic;
	clock:                          	in  std_logic;

	sclk:										out std_logic;
	mosi:										out std_logic;
	miso:										in  std_logic;
	
	spiReady:                			out std_logic;
   dataToSend:                     	in  std_logic_vector( 7 downto 0 );
   dataReceived:                   	out std_logic_vector( 7 downto 0 );
   dataToSendStrobe:               	in  std_logic

);
end simpleSPI;

architecture behavior of simpleSPI is

signal txBuffer: 				std_logic_vector( 7 downto 0 );
signal rxBuffer: 				std_logic_vector( 7 downto 0 );

signal misoSync: 				std_logic;


type spiState_t is ( spiIdle, spiWaitForStrobeRelease, spiB7L, spiB7H, spiB6L, spiB6H, spiB5L, spiB5H, spiB4L, 
							spiB4H, spiB3L, spiB3H, spiB2L, spiB2H, spiB1L, spiB1H, spiB0L, spiB0H );
						 
signal spiState:				spiState_t;

						 
component inputSync

    generic(

        inputWidth              : integer := 1


    );

    port(

        clock:                          in  std_logic;

        signalInput:                    in  std_logic_vector( inputWidth - 1 downto 0 );
        signalOutput:                   out std_logic_vector( inputWidth - 1 downto 0 )

    );

end component;

begin


--rxdSyncInst: inputSync
--    generic map(
--        inputWidth => 1
--    )
--
--    port map(
--
--        clock           => clock,
--        signalInput(0)  => miso,
--        signalOutput(0) => misoSync
--
--    );

	misoSync	<= miso;
	
main: process( all )


begin

	if rising_edge( clock ) then
	
	
		if reset = '1' then
		
			spiState	<= spiIdle;
			spiReady	<= '1';

			sclk		<= '0';
			mosi		<= '0';
			txBuffer	<= ( others => '0' );
			rxBuffer	<= ( others => '0' );
			
		else
		
		
			case spiState is 
	
				when spiIdle =>
				
					sclk				<= '0';
					spiReady			<= '1';
					
					dataReceived	<= rxBuffer;
					
					if dataToSendStrobe = '1' then
						
						txBuffer	<= dataToSend;
						spiReady	<= '0';
						
						spiState	<= spiWaitForStrobeRelease;
						
					end if;
					
				when spiWaitForStrobeRelease =>

					spiReady	<= '0';

					sclk		<= '0';
				
					if dataToSendStrobe = '0' then
					
						spiState	<= spiB7L;
						
					end if;
					
				when spiB7L	=>

					spiReady	<= '0';
				
					mosi		<= txBuffer( 7 );
					
					sclk		<= '0';
					spiState	<= spiB7H;
					
				when spiB7H	=>

					spiReady	<= '0';
					
					rxBuffer( 7 ) <= misoSync;
					
					sclk		<= '1';
					spiState	<= spiB6L;
					
				when spiB6L	=>
				
					mosi		<= txBuffer( 6 );

					spiReady	<= '0';

					sclk		<= '0';
					spiState	<= spiB6H;
					
				when spiB6H	=>
				
					spiReady	<= '0';

					rxBuffer( 6 ) <= misoSync;

					sclk		<= '1';
					spiState	<= spiB5L;
					
				when spiB5L	=>
				
					mosi		<= txBuffer( 5 );

					spiReady	<= '0';
				
					sclk		<= '0';
					spiState	<= spiB5H;
					
				when spiB5H	=>
				
					spiReady	<= '0';

					rxBuffer( 5 ) <= misoSync;

					sclk		<= '1';
					spiState	<= spiB4L;
					
				when spiB4L	=>
				
					mosi		<= txBuffer( 4 );

					spiReady	<= '0';

					sclk		<= '0';
					spiState	<= spiB4H;
					
				when spiB4H	=>
				
					spiReady	<= '0';

					rxBuffer( 4 ) <= misoSync;

					sclk		<= '1';
					spiState	<= spiB3L;
					
				when spiB3L	=>
				
					mosi		<= txBuffer( 3 );

					spiReady	<= '0';
				
					sclk		<= '0';
					spiState	<= spiB3H;
					
				when spiB3H	=>
				
					rxBuffer( 3 ) <= misoSync;

					spiReady	<= '0';

					sclk		<= '1';
					spiState	<= spiB2L;
					
				when spiB2L	=>
				
					mosi		<= txBuffer( 2 );

					spiReady	<= '0';
				
					sclk		<= '0';
					spiState	<= spiB2H;
					
				when spiB2H	=>

					rxBuffer( 2 ) <= misoSync;

					spiReady	<= '0';
				
					sclk		<= '1';
					spiState	<= spiB1L;
					
				when spiB1L	=>
				
					mosi		<= txBuffer( 1 );

					spiReady	<= '0';

					sclk		<= '0';
					spiState	<= spiB1H;
					
				when spiB1H	=>
				
					spiReady	<= '0';

					rxBuffer( 1 ) <= misoSync;

					sclk		<= '1';
					spiState	<= spiB0L;
					
				when spiB0L	=>
				
					mosi		<= txBuffer( 0 );

					spiReady	<= '0';

					sclk		<= '0';
					spiState	<= spiB0H;
					
				when spiB0H	=>
				
					spiReady	<= '0';

					rxBuffer( 0 ) <= misoSync;

					sclk		<= '1';
					spiState	<= spiIdle;
					
					
				when others =>
				
					spiState	<= spiIdle;
					
			end case;	--spiState is
			
			
		end if; --reset = '1'
	
	
	end if;


end process;



end behavior;
