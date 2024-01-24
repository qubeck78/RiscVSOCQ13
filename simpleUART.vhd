library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity simpleUART is

generic(

    clockFreq               : integer := 100000000;
--    clockFreq               : integer := 50000000;
--    baudRate                : integer := 115200
    baudRate                : integer := 500000

);

port(
	--reset
	 reset:                          in  std_logic;
    clock:                          in  std_logic;

    uartTXD:                        out std_logic;
    uartRXD:                        in  std_logic;

    dataSenderReady:                out std_logic;
    dataToSend:                     in  std_logic_vector( 7 downto 0 );
    dataToSendStrobe:               in  std_logic;

    dataReceivedReady:              out std_logic;
    dataReceived:                   out std_logic_vector( 7 downto 0 );
    dataReceivedReadAcknowledge:    in  std_logic

);

end simpleUART;

architecture behavior of simpleUART is


constant baudCounterMax          : integer := ( clockFreq / baudRate )-1; 
constant baudCounterHalf         : integer := baudCounterMax / 2;
constant baudCounterRxStartBit   : integer := baudCounterMax + baudCounterHalf;

signal txBaudCounter    : std_logic_vector( 15 downto 0 );
signal txBuffer         : std_logic_vector( 7 downto 0 );

signal rxBaudCounter    : std_logic_vector( 15 downto 0 );
signal rxBuffer         : std_logic_vector( 7 downto 0 );

type txState_T is ( txsIdle, txsWaitForStrobeRelease, txsStartBit, txsB0, txsB1, txSB2, txsB3, txsB4, txsB5, txsB6, txsB7, txsStopBit );
signal txState          : txState_T;

type rxState_T is ( rxsWaitForStartBit, rxsB0, rxsB1, rxsB2, rxsB3, rxsB4, rxsB5, rxsB6, rxsB7, rxsStopBit, rxsWaitForAcknowledge );
signal rxState          : rxState_T;

signal uartRXDSync      : std_logic;

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



rxdSyncInst: inputSync
    generic map(
        inputWidth => 1
    )

    port map(

        clock           => clock,
        signalInput(0)  => uartRXD,
        signalOutput(0) => uartRXDSync

    );

receiver: process( all )

begin

    if rising_edge( clock ) then

        if reset = '1' then

            dataReceived        <= ( others => '0' );
            dataReceivedReady   <= '0';
            rxState             <= rxsWaitForStartBit;
            rxBaudCounter       <= ( others => '0' );

        else

            case rxState is

                when rxsWaitForStartBit =>

                    if uartRXDSync = '0' then

                        rxBaudCounter   <= conv_std_logic_vector( baudCounterRxStartBit, rxBaudCounter'length );
                        rxState         <= rxsB0;
                        
                    end if;

                when rxsB0 =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        rxBuffer( 0 )   <= uartRXDSync;
                        rxBaudCounter   <= conv_std_logic_vector( baudCounterMax, rxBaudCounter'length );
                        rxState         <= rxsB1;

                    end if;

                when rxsB1 =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        rxBuffer( 1 )   <= uartRXDSync;
                        rxBaudCounter   <= conv_std_logic_vector( baudCounterMax, rxBaudCounter'length );
                        rxState         <= rxsB2;

                    end if;

                when rxsB2 =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        rxBuffer( 2 )   <= uartRXDSync;
                        rxBaudCounter   <= conv_std_logic_vector( baudCounterMax, rxBaudCounter'length );
                        rxState         <= rxsB3;

                    end if;

                when rxsB3 =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        rxBuffer( 3 )   <= uartRXDSync;
                        rxBaudCounter   <= conv_std_logic_vector( baudCounterMax, rxBaudCounter'length );
                        rxState         <= rxsB4;

                    end if;

                when rxsB4 =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        rxBuffer( 4 )   <= uartRXDSync;
                        rxBaudCounter   <= conv_std_logic_vector( baudCounterMax, rxBaudCounter'length );
                        rxState         <= rxsB5;

                    end if;

                when rxsB5 =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        rxBuffer( 5 )   <= uartRXDSync;
                        rxBaudCounter   <= conv_std_logic_vector( baudCounterMax, rxBaudCounter'length );
                        rxState         <= rxsB6;

                    end if;

                when rxsB6 =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        rxBuffer( 6 )   <= uartRXDSync;
                        rxBaudCounter   <= conv_std_logic_vector( baudCounterMax, rxBaudCounter'length );
                        rxState         <= rxsB7;

                    end if;

                when rxsB7 =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        rxBuffer( 7 )   <= uartRXDSync;
                        rxBaudCounter   <= conv_std_logic_vector( baudCounterMax, rxBaudCounter'length );
                        rxState         <= rxsStopBit;

                    end if;

                when rxsStopBit =>

                    if rxBaudCounter /= 0 then
                    
                        rxBaudCounter <= rxBaudCounter - 1;

                    else
                        
                        --todo: check if stop bit is really '1'

                        dataReceived        <= rxBuffer;
                        dataReceivedReady   <= '1';
                        
                        --rxState             <= rxsWaitForAcknowledge;
								rxState             <= rxsWaitForStartBit;
                    end if;

--                when rxsWaitForAcknowledge =>

--                    if dataReceivedReadAcknowledge = '1' then
--
--                        dataReceivedReady   <= '0';
--                        rxState             <= rxsWaitForStartBit;
--
--                    end if;


                when others =>

                    rxState <= rxsWaitForStartBit;

            end case;


				if dataReceivedReadAcknowledge = '1' then

                 dataReceivedReady   <= '0';

				end if;
				
        end if;

    end if;

end process;



transmitter: process( all )

begin

    if rising_edge( clock ) then

        if reset = '1' then

            txState         <= txsIdle;
            uartTXD         <= '1';
            dataSenderReady <= '1';
            txBuffer        <= ( others => '0' );
            txBaudCounter   <= ( others => '0' );
            
        else

            case txState is


                when txsIdle =>

                    uartTXD         <= '1';
                    dataSenderReady <= '1';

                    if dataToSendStrobe = '1' then
                        
                        txBuffer        <= dataToSend;
                        dataSenderReady <= '0';
                        
                        txState         <= txsWaitForStrobeRelease;

                    end if;

                when txsWaitForStrobeRelease =>

                    if dataToSendStrobe = '0' then
                    
                        txState         <= txsStartBit;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );
                        
                    end if;

                when txsStartBit =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= '0';
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsB0;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;

                when txsB0 =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= txBuffer( 0 );
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsB1;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;
                
                when txsB1 =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= txBuffer( 1 );
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsB2;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;

                when txsB2 =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= txBuffer( 2 );
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsB3;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;

                when txsB3 =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= txBuffer( 3 );
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsB4;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;

                when txsB4 =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= txBuffer( 4 );
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsB5;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;

                when txsB5 =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= txBuffer( 5 );
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsB6;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;

                when txsB6 =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= txBuffer( 6 );
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsB7;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;

                when txsB7 =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= txBuffer( 7 );
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsStopBit;
                        txBaudCounter   <= conv_std_logic_vector( baudCounterMax, txBaudCounter'length );

                    end if;

                when txsStopBit =>

                    if txBaudCounter /= 0 then

                        uartTXD         <= '1';
                        txBaudCounter   <= txBaudCounter - 1;

                    else
                        txState         <= txsIdle;

                    end if;

                when others =>

                    txState <= txsIdle;

            end case;



        end if;

    end if;

end process;




end behavior;
