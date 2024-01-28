library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity fpAlu is

port(
   reset:      in    std_logic;
   clock:      in    std_logic;
   a:          in    std_logic_vector( 15 downto 0 );
   din:        in    std_logic_vector( 31 downto 0 );
   dout:       out   std_logic_vector( 31 downto 0 );
   
   ce:         in    std_logic;
   wr:         in    std_logic;
   dataMask:   in    std_logic_vector( 3 downto 0 );
   
   ready:      out   std_logic
);

end fpAlu;

architecture behavior of fpAlu is

component fpMult is
port( 
       clock   :  IN  STD_LOGIC;
       dataa   :  IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
       datab   :  IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
       result  :  OUT  STD_LOGIC_VECTOR (31 DOWNTO 0)
    ); 
end component;
 
component fpAdd is 
port(
       clock   :  IN  STD_LOGIC;
       dataa   :  IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
       datab   :  IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
       result  :  OUT  STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
end component;

component fpSub is 
port(
       clock   :  IN  STD_LOGIC;
       dataa   :  IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
       datab   :  IN  STD_LOGIC_VECTOR (31 DOWNTO 0);
       result  :  OUT  STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
end component;

component fpDiv is
port
   (
      clock    : IN STD_LOGIC ;
      dataa    : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      datab    : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      result      : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
END component;

type fpAluRegState_T is ( farsWaitForRegAccess, farsWaitForBusCycleEnd );

signal   state:         fpAluRegState_T;

signal   fpA:           std_logic_vector( 31 downto 0 );
signal   fpB:           std_logic_vector( 31 downto 0 );
signal   fpAddResult:   std_logic_vector( 31 downto 0 );
signal   fpSubResult:   std_logic_vector( 31 downto 0 );
signal   fpMulResult:   std_logic_vector( 31 downto 0 );
signal   fpDivResult:   std_logic_vector( 31 downto 0 );

begin

fpMultInst: fpMult
port map(

   clock    => clock,
   dataa    => fpA,
   dataB    => fpB,
   result   => fpMulResult

);

fpAddInst: fpAdd
port map(

   clock    => clock,
   dataa    => fpA,
   dataB    => fpB,
   result   => fpAddResult

);

fpSubInst: fpSub
port map(

   clock    => clock,
   dataa    => fpA,
   dataB    => fpB,
   result   => fpSubResult

);

fpDivInst: fpDiv
port map(

   clock    => clock,
   dataa    => fpA,
   dataB    => fpB,
   result   => fpDivResult

);


   fpAluMain: process( all )
   begin

      if rising_edge( clock ) then
      
         if reset = '1' then
         
            ready <= '0';  
            state <= farsWaitForRegAccess;
            
         else
         
            case state is
      
               when farsWaitForRegAccess =>
            
                  if ce = '1' then
                  
                     --cpu wants to access registers
                  
                     ready <= '0';
                     
                     case a( 7 downto 0 ) is
                     
                        --0x00 rw fpA                       
                        when x"00" =>
                        
                           dout  <= fpA;
                           
                           if wr = '1' then
                           
                              fpA <= din;
                              
                           end if;

                           ready <= '1';
                           
                        --0x04 rw fpB
                        when x"01" =>
                        
                           dout  <= fpB;
                           
                           if wr = '1' then
                           
                              fpB <= din;
                              
                           end if;

                           ready <= '1';
                        
                        --0x08 r- fpAddResult
                        when x"02" =>
                        
                           dout  <= fpAddResult;
                        
                           ready <= '1';

                        --0x0c r- fpSubResult
                        when x"03" =>
                        
                           dout  <= fpSubResult;
                        
                           ready <= '1';

                        --0x10 r- fpMulResult
                        when x"04" =>
                        
                           dout  <= fpMulResult;
                        
                           ready <= '1';

                        --0x14 r- fpDivResult
                        when x"05" =>
                        
                           dout  <= fpDivResult;
                        
                           ready <= '1';


                        when others =>
                        
                           dout  <= ( others =>'0' );
                           ready <= '1';
                     
                     end case; --a
                  
                     state <= farsWaitForBusCycleEnd;
                  
                  end if; --ce = '1'
                           
               
               when farsWaitForBusCycleEnd =>
               
                  --wait for bus cycle to end
                  if ce = '0' then
                  
                     state <= farsWaitForRegAccess;
                     ready <= '0';
                     
                  end if;
                  
               when others =>
               
                  state <= farsWaitForRegAccess;
            
            end case; --state
      
         end if; --reset = '1'
      
      
      
      end if; --rising_edge( clock )
   

   end process;


end behavior;
