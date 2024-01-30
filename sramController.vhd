library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;


entity sramController is
port(

   reset:      in  std_logic;
   clock:      in  std_logic;
   


   --gfx display mode interface ( ch0 )
   ch0DmaRequest:       in  std_logic_vector( 1 downto 0 );
   ch0DmaPointerStart:  in  std_logic_vector( 20 downto 0 );
   ch0DmaPointerReset:  in  std_logic;
   
   ch0BufClk:           in  std_logic;
   ch0BufDout:          out std_logic_vector( 31 downto 0 );
   ch0BufA:             in  std_logic_vector( 8 downto 0 );
   
   
   --audio interface ( ch1 )
   
   --tbd
   
   
   --blitter interface ( ch2 )
   ch2DmaRequest: in  std_logic;
   ch2A:          in  std_logic_vector( 21 downto 0 );
   ch2Din:        in  std_logic_vector( 31 downto 0 );
   ch2Dout:       out std_logic_vector( 31 downto 0 );
   ch2RWn:        in  std_logic;
   ch2WordSize:   in  std_logic;
   ch2DataMask:   in  std_logic_vector( 1 downto 0 );
   ch2Ready:      out std_logic;
   
   
   --cpu interface ( ch3 )
   a:          in  std_logic_vector( 20 downto 0 );
   din:        in  std_logic_vector( 31 downto 0 );
   dout:       out std_logic_vector( 31 downto 0 );
   
   ce:         in  std_logic;
   wr:         in  std_logic;
   dataMask:   in  std_logic_vector( 3 downto 0 );
   
   ready:      out std_logic; 
   
   
   --static ram interface
   gds0_7n:    out std_logic;
   gds8_15n:   out std_logic;
   gds16_23n:  out std_logic;
   gds24_31n:  out std_logic;
      
   gwen:       out std_logic;
   goen:       out std_logic;

   ga:         out   std_logic_vector( 20 downto 0 );
   gd:         inout std_logic_vector( 31 downto 0 )
);


end sramController;

architecture behavior of sramController is

--components

-- gfx pixel gen buffer ram ( ch0 buffer )
component gfxBufRam IS
   PORT
   (
      data        : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      rdaddress   : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      rdclock     : IN STD_LOGIC;
      wraddress   : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      wrclock     : IN STD_LOGIC  := '1';
      wren        : IN STD_LOGIC  := '0';
      q           : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
END component;


--signals

type  dmaState_T is ( dmaIdle, dmaGfxFetch0, dmaGfxFetch1, dmaGfxFetch2, dmaGfxFetch3, dmaGfxFetch4, dmaGfxFetch5,
                     dmaCpuWrite0, dmaCpuWrite1, dmaCpuWrite2, dmaCpuWrite3, dmaCpuWrite4, 
                     dmaCpuRead0, dmaCpuRead1, dmaCpuRead2, dmaCpuRead3, dmaCpuRead4,
                     dmaCh2Write0, dmaCh2Write1, dmaCh2Write2, dmaCh2Write3, dmaCh2Write4, 
                     dmaCh2Read0, dmaCh2Read1, dmaCh2Read2, dmaCh2Read3, dmaCh2Read4,
                     dmaCh2Write32_0, dmaCh2Write32_1, dmaCh2Write32_2, dmaCh2Write32_3, dmaCh2Write32_4,
                     dmaCh2Read32_0, dmaCh2Read32_1, dmaCh2Read32_2, dmaCh2Read32_3, dmaCh2Read32_4               
               );
                     
signal   dmaState:   dmaState_T;

--ch0 buf ram
signal   ch0BufRamDIn:           std_logic_vector( 31 downto 0 );
signal   ch0BufRamWrA:           std_logic_vector( 8 downto 0 );
signal   ch0BufRamWe:            std_logic;
signal   ch0TransferCounter:     std_logic_vector( 7 downto 0 );
signal   ch0DmaPointer:          std_logic_vector( 20 downto 0 );
signal   ch0DmaBufPointer:       std_logic_vector( 8 downto 0 );

--ch0 doesn't have handshake, so requests have to be latched
signal   ch0DmaRequestLatched:   std_logic_vector( 1 downto 0 );

begin

gfxBufRAMInst: gfxBufRam
port map(

   rdclock     => ch0BufClk,
   rdaddress   => ch0BufA,
   q           => ch0BufDout,

   wrclock     => clock,
   wren        => ch0BufRamWe,
   wraddress   => ch0BufRamWrA,
   data        => ch0BufRamDIn
);


dmaMain: process( all )
begin

   if rising_edge( clock ) then

      if reset = '1' then
      
         --static ram signals
         gds0_7n     <= '1';
         gds8_15n    <= '1';
         gds16_23n   <= '1';
         gds24_31n   <= '1';
         gwen        <= '1';
         goen        <= '1';

         ga          <= ( others => '0' );
         gd          <= ( others => 'Z' );

      
         --dma channels
         ch2Dout     <= ( others => '0' );
         ch2Ready    <= '1';
         
         dout        <= ( others => '0' );
         ready       <= '0';
         
         --ch0 buf ram
         ch0BufRamDIn   <= ( others => '0' );
         ch0BufRamWrA   <= ( others => '0' );
         ch0BufRamWe    <= '0';

         --ch0 pointers, counters
         ch0DmaPointer        <= ( others => '0' );
         ch0DmaBufPointer     <= ( others => '0' );

         ch0TransferCounter   <= ( others => '0' );

         ch0DmaRequestLatched <= "00";
         
         dmaState <= dmaIdle;
         
      else

         --latch ch0 dma requests
         if ch0DmaRequest( 0 ) = '1' then
         
            ch0DmaRequestLatched( 0 ) <= '1';
            
         end if;
      
         if ch0DmaRequest( 1 ) = '1' then
         
            ch0DmaRequestLatched( 1 ) <= '1';
            
         end if;
         
         --reset ch0 dma pointer if requested
         if ch0DmaPointerReset = '1' then
         
            ch0DmaPointer  <= ch0DmaPointerStart;
            
         end if;
         
         case dmaState is
         
            when dmaIdle =>
            
               --hold cpu
               ready <= '0';
               
               --ch0 request 0 ( buffer, lower part )
               if ch0DmaRequestLatched( 0 ) = '1' then
               
                  ch0DmaBufPointer     <= "000000000";
                  ch0TransferCounter   <= x"a0";      --160 long words
                  
                  ga <= ch0DmaPointer( 20 downto 0 );
                  gd <= ( others => 'Z' );
   
                  gds0_7n                 <= '0';
                  gds8_15n                <= '0';
                  gds16_23n               <= '0';
                  gds24_31n               <= '0';
            
                  gwen                    <= '1';
                  goen                    <= '0';

                  dmaState <= dmaGfxFetch0;
                  
               --ch0 request 0 ( buffer, upper part )
               elsif ch0DmaRequestLatched( 1 ) = '1' then
               
                  ch0DmaBufPointer     <= "100000000";
                  ch0TransferCounter   <= x"a0";      --160 long words
                  
                  ga <= ch0DmaPointer( 20 downto 0 );
                  gd <= ( others => 'Z' );
   
                  gds0_7n                 <= '0';
                  gds8_15n                <= '0';
                  gds16_23n               <= '0';
                  gds24_31n               <= '0';
            
                  gwen                    <= '1';
                  goen                    <= '0';

                  dmaState <= dmaGfxFetch0;
               
               --ch2 request 
               elsif ch2DmaRequest = '1' then
   
                  ch2Ready <= '0';
                  
                  if ch2WordSize = '0' then
                  
                     --16 bit transfer
                     
                     ga <= ch2A( 21 downto 1 );
                     
                     if ch2A( 0 ) = '0' then
                     
                        gds0_7n     <= '0';
                        gds8_15n    <= '0';  
                        gds16_23n   <= '1';
                        gds24_31n   <= '1';
                     
                     else
                        
                        gds0_7n     <= '1';
                        gds8_15n    <= '1';
                        gds16_23n   <= '0';
                        gds24_31n   <= '0';  
                     
                     end if; --ch2a( 0 ) = '0'
                  
                     if ch2RWn = '1' then
                     
                        --read 
                        gd             <= ( others => 'Z' );
                        gwen           <= '1';
                        goen           <= '0';
                     
                        dmaState       <= dmaCh2Read0;
                        
                     else
                     
                        --write
                        if ch2A( 0 ) = '0' then
                     
                           gd( 15 downto 0 ) <= ch2Din( 15 downto 0 );

                        else
                           gd( 31 downto 16 ) <= ch2Din( 15 downto 0 );
                     
                        end if;

                        gwen           <= '1';
                        goen           <= '1';
                     
                        dmaState       <= dmaCh2Write0;
                        
                     end if; --ch2RWn = '1'
                     
                  else
                  
                     --32 bit transfer
                     
                     ga <= ch2A( 20 downto 0 );
                     
                     gds0_7n     <= '0';
                     gds8_15n    <= '0';  
                     gds16_23n   <= '0';
                     gds24_31n   <= '0';
                     
                     if ch2RWn = '1' then
                     
                        --read
                        gd             <= ( others => 'Z' );
                        gwen           <= '1';
                        goen           <= '0';
                     
                        dmaState       <= dmaCh2Read32_0;
                     
                     else
                     
                        --write                    
                        gd             <= ch2Din;

                        gwen           <= '1';
                        goen           <= '1';
                     
                        dmaState       <= dmaCh2Write32_0;
                     
                     end if; --dmaCh2RWn ='1'
                     
                     
                  end if; --ch2WordSize   = '0'
            
               --ch3 request
               elsif ce = '1' then
               
                  ready <= '0';
                  
                  --write                 
                  if wr = '1' then
                     
                     ga          <= a( 20 downto 0 );
                     gd          <= din;
                        
                     
                     gds0_7n     <= not dataMask( 0 );
                     gds8_15n    <= not dataMask( 1 );   
                     gds16_23n   <= not dataMask( 2 );
                     gds24_31n   <= not dataMask( 3 );
                        
                     gwen        <= '1';
                     goen        <= '1';
                  
                     
                     dmaState    <= dmaCpuWrite0;
                     
                  else
                  
                     --read
                     
                     ga          <= a( 20 downto 0 );
                     gd          <= ( others => 'Z' );
                     gwen        <= '1';
                     goen        <= '1';
                                             
                     gds0_7n     <= '0';
                     gds8_15n    <= '0';  
                     gds16_23n   <= '0';
                     gds24_31n   <= '0';
                           
                                                                           
                     dmaState    <= dmaCpuRead0;
               
                  end if;  
               
               end if;
         
         
            --ch0
            when dmaGfxFetch0 =>
      
               ch0BufRamWe             <= '0';
   
               ch0TransferCounter      <= ch0TransferCounter - 1;
            
               ga                      <= ch0DmaPointer( 20 downto 0 );
                                    
               dmaState                <= dmaGfxFetch1;
            
            when dmaGfxFetch1 =>
         
               dmaState <= dmaGfxFetch2;
                  
            when dmaGfxFetch2 =>
         
               ch0BufRamWrA            <= ch0DmaBufPointer;

               ch0DmaBufPointer        <= ch0DmaBufPointer + 1;
               ch0DmaPointer           <= ch0DmaPointer  + 1;

               dmaState <= dmaGfxFetch3;
            
            when dmaGfxFetch3 =>
         
--               ch0BufRamWrA            <= ch0DmaBufPointer;
--
--               ch0DmaBufPointer        <= ch0DmaBufPointer + 1;
--               ch0DmaPointer           <= ch0DmaPointer  + 1;

               --
               
               ch0BufRamDIn   <= gd;
                        
               ch0BufRamWe    <= '1';
               
               if ch0TransferCounter = x"00" then
            
                  --static ram signals
                  gds0_7n                    <= '1';
                  gds8_15n                   <= '1';
                  gds16_23n                  <= '1';
                  gds24_31n                  <= '1';
                  gwen                       <= '1';
                  goen                       <= '1';

                  ga                         <= ( others => '0' );
                  gd                         <= ( others => 'Z' );

                  ch0DmaRequestLatched( 0 )  <= '0';
                  ch0DmaRequestLatched( 1 )  <= '0';
               
                  dmaState <= dmaGfxFetch4;
               
               else
            
                  dmaState <= dmaGfxFetch0;
            
               end if;
         
            when dmaGfxFetch4 =>
         
               ch0BufRamWe    <= '0';

               dmaState <= dmaIdle;          

         
            --ch2
            when dmaCh2Read0 =>
         
               dmaState    <= dmaCh2Read2; -- skip waitstates
         
            when dmaCh2Read1 =>
         
            
               dmaState <= dmaCh2Read2;

            when dmaCh2Read2 =>
         
               dmaState <= dmaCh2Read3;
            
            
            when dmaCh2Read3 =>
         
               if ch2A( 0 ) = '0' then
            
                  ch2Dout( 15 downto 0 )  <= gd( 15 downto 0 );
               
               else
            
                  ch2Dout( 15 downto 0 )  <= gd( 31 downto 16 );
               
               end if;
               
               ch2Ready             <= '1';
               
               gds0_7n     <= '1';
               gds8_15n    <= '1';
               gds16_23n   <= '1';
               gds24_31n   <= '1';
               gwen        <= '1';
               goen        <= '1';

               dmaState <= dmaIdle;
            
            when dmaCh2Write0 =>
         
               gwen     <= '0';
            
               dmaState <= dmaCh2Write2;  

            when dmaCh2Write1 =>
            
               gwen     <= '1';
            
               dmaState <= dmaCh2Write2;
            
            when dmaCh2Write2 =>
            
               gwen        <= '1';
         
               gds0_7n     <= '1';
               gds8_15n    <= '1';
               gds16_23n   <= '1';
               gds24_31n   <= '1';
               gwen        <= '1';
               goen        <= '1';
            
               gd          <= ( others => 'Z' );
            
               dmaState <= dmaCh2Write3;

            when dmaCh2Write3 =>
            
               gwen        <= '1';
         
               gds0_7n     <= '1';
               gds8_15n    <= '1';
               gds16_23n   <= '1';
               gds24_31n   <= '1';
               gwen        <= '1';
               goen        <= '1';
            
               gd          <= ( others => 'Z' );
            
               ch2Ready             <= '1';
               
               dmaState    <= dmaIdle;       

            when dmaCh2Read32_0 =>
         
               dmaState    <= dmaCh2Read32_1; 
         
            when dmaCh2Read32_1 =>
         
               dmaState <= dmaCh2Read32_2;

            when dmaCh2Read32_2 =>
         
               dmaState <= dmaCh2Read32_3;
            
            when dmaCh2Read32_3 =>
         
               ch2Dout  <= gd;            

               ch2Ready             <= '1';
            
               gds0_7n     <= '1';
               gds8_15n    <= '1';
               gds16_23n   <= '1';
               gds24_31n   <= '1';
               gwen        <= '1';
               goen        <= '1';

               dmaState <= dmaIdle;          

            when dmaCh2Write32_0 =>
         
               gwen     <= '0';
            
               dmaState <= dmaCh2Write32_1;  

            when dmaCh2Write32_1 =>
            
               gwen     <= '1';
            
               dmaState <= dmaCh2Write32_3;
            
            when dmaCh2Write32_2 =>
            
               gwen        <= '1';
         
               gds0_7n     <= '1';
               gds8_15n    <= '1';
               gds16_23n   <= '1';
               gds24_31n   <= '1';
               gwen        <= '1';
               goen        <= '1';
            
               gd          <= ( others => 'Z' );
            
               dmaState <= dmaCh2Write32_3;

            when dmaCh2Write32_3 =>
            
               gwen        <= '1';
         
               gds0_7n     <= '1';
               gds8_15n    <= '1';
               gds16_23n   <= '1';
               gds24_31n   <= '1';
               gwen        <= '1';
               goen        <= '1';
            
               gd          <= ( others => 'Z' );

               ch2Ready    <= '1';
               
               dmaState    <= dmaIdle;          
         
            --ch3
            when dmaCpuRead0 =>
         
               dmaState <= dmaCpuRead1; 
         
            when dmaCpuRead1 =>
         
               goen     <= '0';

               dmaState <= dmaCpuRead2;

            when dmaCpuRead2 =>
         
               dmaState <= dmaCpuRead3;

            when dmaCpuRead3 =>
         
               dout     <= gd;
               ready    <= '1';

               dmaState <= dmaCpuRead4;
            
            when dmaCpuRead4 =>
         
               gds0_7n     <= '1';
               gds8_15n    <= '1';
               gds16_23n   <= '1';
               gds24_31n   <= '1';
               gwen        <= '1';
               goen        <= '1';
         
               if ce = '0' then
            
                  ready    <= '0';
                  dmaState <= dmaIdle;
            
               end if;
               
            
            when dmaCpuWrite0 =>
         
         
               gwen     <= '1';
            
               dmaState <= dmaCpuWrite1;  

            when dmaCpuWrite1 =>
            
               gwen     <= '0';
            
               dmaState <= dmaCpuWrite4;

            when dmaCpuWrite2 =>
            
               gwen     <= '0';
            
               dmaState <= dmaCpuWrite3;  
            
            when dmaCpuWrite3 =>
   
               gwen        <= '1';
            
               dmaState <= dmaCpuWrite4;

            when dmaCpuWrite4 =>
            
               gwen        <= '1';
         
               gds0_7n     <= '1';
               gds8_15n    <= '1';
               gds16_23n   <= '1';
               gds24_31n   <= '1';
               gwen        <= '1';
               goen        <= '1';
            
               gd          <= ( others => 'Z' );
            
               ready       <= '1';

               if ce = '0' then
            
                  ready    <= '0';
                  dmaState <= dmaIdle;
            
               end if;
                     
         
            when others =>
            
               dmaState <= dmaIdle;
         
         end case;
      
      end if;


   end if; -- rising_edge( clock )
   
end process;




end behavior;
