library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;

entity gouraudWeight is

port(
   --reset
    reset:                          in  std_logic;
    clock:                          in  std_logic;
    
    edge:                           in std_logic_vector( 31 downto 0 );
    area:                           in std_logic_vector( 31 downto 0 );
    
    weight:                         out std_logic_vector( 31 downto 0 )

);

end gouraudWeight;

architecture behavior of gouraudWeight is


component divider32s is
   port
   (
      denom    : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      numer    : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      quotient    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
      remain      : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
end component;


component dividerStaged IS
   PORT
   (
      clock    : IN STD_LOGIC ;
      denom    : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      numer    : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      quotient    : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
      remain      : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
END component;

begin

divider32sInst: divider32s
   port map(

      numer    => edge( 23 downto 0 ) & x"00",

   
      denom    => area,
      quotient => weight
   );

--dividerStagedInst: dividerStaged
-- port map(
-- 
--    clock    => clock,
--    numer    => edge( 23 downto 0 ) & x"00",
-- 
--    denom    => area,
--    quotient => weight
-- 
-- );
-- 
   
end behavior;
