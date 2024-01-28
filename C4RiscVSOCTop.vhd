
library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;


--https://github.com/nullobject/de0-nano-examples/blob/master/sdram/src/sdram.vhd
--https://www.intel.com/content/www/us/en/docs/programmable/683492/18-1/using-synthesis-attributes.html


--https://github.com/splinedrive/my_sdram/blob/main/my_sdram_ctrl.v
--https://github.com/douggilliland/Retro-Computers/blob/master/68000/TG68_AMR/TG68_AMR_FPGA/RTL/Memory/sdram.vhd
--https://github.com/nullobject/sdram-fpga
--https://www.geocities.ws/mikael262/sdram.html
--https://www.fpga4fun.com/SDRAM2.html
--http://www.pudn.com/Download/item/id/122819.html
--https://github.com/emard/Minimig_ECS/blob/master/rtl_emard/sdram/sdram.vhd

--multicycle paths
--https://github.com/ijor/fx68k/blob/master/fx68k.txt


--creating timing constraints
--https://www.youtube.com/watch?v=SpKAg3JJOs8

--https://community.intel.com/t5/FPGA/ct-p/fpga
--https://community.intel.com/t5/Intel-Quartus-Prime-Software/How-to-improve-Fmax-for-SOPC-System/td-p/46478

--https://github.com/YosysHQ/picorv32
--https://github.com/YosysHQ/nerv/blob/main/firmware.s

--hdmi output example
--https://numato.com/kb/hdmi-output-example-design-for-telesto/

entity C4RiscVSOCTop is
generic(
   instHDMIOutput:               boolean := true;
   instBlitter3DAcceleration:    boolean := true;
   instFastFloatingMath:         boolean := true;
   instHidUSBHost:               boolean := true

);
port(
   
   --onboard peripherals
      
   --clock
   core_board_clk_50:   in std_logic;
   
   --reset
   core_board_reset:    in std_logic;
   
   --user key
   core_board_key:      in std_logic;
   
   --leds
   core_board_leds:     out std_logic_vector( 1 downto 0 );
   
   --sdram
   sd1_a:               out std_logic_vector( 12 downto 0 );
   sd1_ba:              out std_logic_vector( 1 downto 0 );
   
   sd1_cke:             out std_logic;
   sd1_clk:             out std_logic;
   
   sd1_dqml:            out std_logic;
   sd1_dqmh:            out std_logic;
   
   sd1_cas:             out std_logic;
   sd1_ras:             out std_logic;
   
   sd1_wen:             out std_logic;
   sd1_csn:             out std_logic;
   
   sd1_d:               inout std_logic_vector( 15 downto 0 );
   
   
   --base board peripherals
   
   --vga
   red:   out std_logic_vector( 4 downto 0 );
   green: out std_logic_vector( 4 downto 0 );
   blue:  out std_logic_vector( 4 downto 0 );
   vsync: out std_logic;
   hsync: out std_logic;
   
   --ext uart
   extUartTx:  out   std_logic;
   extUartRx:  in    std_logic;
   
   --sd card
   sdMciDat:   inout std_logic_vector( 3 downto 0 );  
   sdMciCmd:   out   std_logic;  
   sdMciClk:   out   std_logic;  
   
   --usb host
   usbHDp:     inout std_logic;     -- ae17 (I2S_IO0)
   usbHDm:     inout std_logic;     -- af17 (I2S_IO1)
   
   
   --hdmi output
   tmdsOutClk:       out std_logic;
   tmdsOutClkN:      out std_logic;
   tmdsOutData:      out std_logic_vector( 2 downto 0 );
   tmdsOutDataN:     out std_logic_vector( 2 downto 0 ); 

   --graphics sram
   gds0_7n:    out   std_logic;
   gds8_15n:   out   std_logic;
   gds16_23n:  out   std_logic;
   gds24_31n:  out   std_logic;
      
   gwen:       out   std_logic;
   goen:       out   std_logic;

   ga:         out   std_logic_vector( 20 downto 0 );
   gd:         inout std_logic_vector( 31 downto 0 )
   
);
end C4RiscVSOCTop;


architecture behavior of C4RiscVSOCTop is

-- components

-- main pll
component mainPll IS
   PORT
   (
      areset      : IN STD_LOGIC  := '0';
      inclk0      : IN STD_LOGIC  := '0';
      c0          : OUT STD_LOGIC ;          
      c1          : OUT STD_LOGIC ;
      c2          : OUT STD_LOGIC ;
      c3          : OUT STD_LOGIC ;
      c4          : OUT STD_LOGIC ;
      locked      : OUT STD_LOGIC 
   );
END component;

-- gfx pll
component gfxPll IS
   PORT
   (
      areset      : IN STD_LOGIC  := '0';
      inclk0      : IN STD_LOGIC  := '0';
      c0          : OUT STD_LOGIC ;
      c1          : OUT STD_LOGIC ;
      c2          : OUT STD_LOGIC ;
      locked      : OUT STD_LOGIC 
   );
END component;


-- font prom
component fontProm IS
   PORT
   (
      address     : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
      clock       : IN STD_LOGIC  := '1';
      q           : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
   );
END component;


-- text mode pixel and sync gen
component pixelGenTxt
    port(
        --reset
        reset:          in  std_logic;
        pgClock:        in  std_logic;
        pgVSync:        out std_logic;
        pgHSync:        out std_logic;
        pgDe:           out std_logic;
        pgR:            out std_logic_vector( 7 downto 0 );
        pgG:            out std_logic_vector( 7 downto 0 );
        pgB:            out std_logic_vector( 7 downto 0 );

        fontRomA:       out std_logic_vector( 10 downto 0 );
        fontRomDout:    in  std_logic_vector( 7 downto 0 );

        videoRamBA:     out std_logic_vector( 13 downto 0 );
        videoRamBDout:  in  std_logic_vector( 15 downto 0 );
        
        pgXCount:       out std_logic_vector( 11 downto 0 );
        pgYCount:       out std_logic_vector( 11 downto 0 );
        pgDeX:          out std_logic;
        pgDeY:          out std_logic;
        pgPreFetchLine: out std_logic;
        pgFetchEnable:  out std_logic;
      pgVideoMode:      in  std_logic_vector( 1 downto 0 )
   );
end component;

-- gfx pixel gen
component pixelGenGfx is
port(
   reset:            in  std_logic;
   pggClock:         in  std_logic;
   pggR:             out std_logic_vector( 7 downto 0 );
   pggG:             out std_logic_vector( 7 downto 0 );
   pggB:             out std_logic_vector( 7 downto 0 );

    --gfx buffer ram
   gfxBufRamDOut:    in  std_logic_vector( 31 downto 0 );
   gfxBufRamRdA:     out std_logic_vector( 8 downto 0 );

   --2 dma requests
   pggDMARequest:    out std_logic_vector( 1 downto 0 );
   
   --sync gen outputs
   pgVSync:          in  std_logic;
   pgHSync:          in  std_logic;
   pgDe:             in  std_logic;
   pgXCount:         in  std_logic_vector( 11 downto 0 );
   pgYCount:         in  std_logic_vector( 11 downto 0 );
   pgDeX:            in  std_logic;
   pgDeY:            in  std_logic;
   pgPreFetchLine:   in  std_logic;
   pgFetchEnable:    in  std_logic;

   pgVideoMode:      in  std_logic_vector( 1 downto 0 )

   );
end component;


-- riscv cpu
component picorv32 is   
   port
   (
      clk:           in  std_logic;
      resetn:        in  std_logic;
      trap:          out std_logic;
      mem_valid:     out std_logic;
      mem_instr:     out std_logic;
      mem_ready:     in  std_logic;

      mem_addr:      out std_logic_vector( 31 downto 0 );
      mem_wdata:     out std_logic_vector( 31 downto 0 );
      mem_wstrb:     out std_logic_vector( 3 downto 0 );
      mem_rdata:     in  std_logic_vector( 31 downto 0 );

      --Look-Ahead Interface
      mem_la_read:   out std_logic;
      mem_la_write:  out std_logic;
      mem_la_addr:   out std_logic_vector( 31 downto 0 );
      mem_la_wdata:  out std_logic_vector( 31 downto 0 );
      mem_la_wstrb:  out std_logic_vector( 3 downto 0 );

      --Pico Co-Processor Interface (PCPI)
      pcpi_valid:    out std_logic;
      pcpi_insn:     out std_logic_vector( 31 downto 0 );
      pcpi_rs1:      out std_logic_vector( 31 downto 0 );
      pcpi_rs2:      out std_logic_vector( 31 downto 0 );
      pcpi_wr:       in  std_logic;
      pcpi_rd:       in  std_logic_vector( 31 downto 0 );
      pcpi_wait:     in  std_logic;
      pcpi_ready:    in  std_logic;

      --IRQ Interface
      irq:           in  std_logic_vector( 31 downto 0 );
      eoi:           out std_logic_vector( 31 downto 0 );

      --Trace Interface
      trace_valid:   out std_logic;
      trace_data:    out std_logic_vector( 35 downto 0 )

);
end component;

-- static ram controller and dma
component sramController is
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
end component;

-- UART
component UART
    port(
      --cpu interface
      reset:            in    std_logic;
      clock:            in    std_logic;
      a:                in    std_logic_vector( 15 downto 0 );
      din:              in    std_logic_vector( 31 downto 0 );
      dout:             out   std_logic_vector( 31 downto 0 );
      
      ce:               in    std_logic;
      wr:               in    std_logic;
      dataMask:         in    std_logic_vector( 3 downto 0 );
      
      ready:            out   std_logic;
      
      --uart interface
      uartTXD:          out std_logic;
      uartRXD:          in  std_logic
    );
end component;

-- SPI
component SPI is
port(

   --cpu interface
   reset:      in  std_logic;
   clock:      in  std_logic;

   a:          in    std_logic_vector( 15 downto 0 );
   din:        in    std_logic_vector( 31 downto 0 );
   dout:       out   std_logic_vector( 31 downto 0 );
   
   ce:         in    std_logic;
   wr:         in    std_logic;
   dataMask:   in    std_logic_vector( 3 downto 0 );
   
   ready:      out   std_logic;
   
   --spi interface
   sclk:       out std_logic;
   mosi:       out std_logic;
   miso:       in  std_logic
   
);
end component;


-- system RAM ( 32K, bootloader, textmode display data, stack )
component systemRam IS
   PORT
   (
      address_a      : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
      address_b      : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
      byteena_a      : IN STD_LOGIC_VECTOR (3 DOWNTO 0) :=  (OTHERS => '1');
      byteena_b      : IN STD_LOGIC_VECTOR (3 DOWNTO 0) :=  (OTHERS => '1');
      clock_a        : IN STD_LOGIC  := '1';
      clock_b        : IN STD_LOGIC ;
      data_a         : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      data_b         : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      wren_a         : IN STD_LOGIC  := '0';
      wren_b         : IN STD_LOGIC  := '0';
      q_a            : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
      q_b            : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
END component;

-- fastram (512K)
component fastRam IS
   PORT
   (
      address_a      : IN STD_LOGIC_VECTOR (16 DOWNTO 0);
      address_b      : IN STD_LOGIC_VECTOR (16 DOWNTO 0);
      byteena_a      : IN STD_LOGIC_VECTOR (3 DOWNTO 0) :=  (OTHERS => '1');
      byteena_b      : IN STD_LOGIC_VECTOR (3 DOWNTO 0) :=  (OTHERS => '1');
      clock_a        : IN STD_LOGIC  := '1';
      clock_b        : IN STD_LOGIC ;
      data_a         : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      data_b         : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
      wren_a         : IN STD_LOGIC  := '0';
      wren_b         : IN STD_LOGIC  := '0';
      q_a            : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
      q_b            : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
END component;

-- usb host
component usbHost is
port(

   --cpu interface
   reset:            in    std_logic;
   clock:            in    std_logic;
   a:                in    std_logic_vector( 15 downto 0 );
   din:              in    std_logic_vector( 31 downto 0 );
   dout:             out   std_logic_vector( 31 downto 0 );
   
   ce:               in    std_logic;
   wr:               in    std_logic;
   dataMask:         in    std_logic_vector( 3 downto 0 );
   
   ready:            out   std_logic;
   
   --usb phy clock (12MHz)
   usbHClk:          in    std_logic;
   
   --usb host interfaces
   usbH0Dp:          inout std_logic;     
   usbH0Dm:          inout std_logic      

);
end component;

-- sdram memory controller
component sdramController is
port(

   clk:                 in    std_logic;
   reset:               in    std_logic;
   
   --sdram interface
   sdramCke:            out   std_logic;

   sdramA:              out   std_logic_vector( 12 downto 0 );
   sdramBa:             out   std_logic_vector( 1 downto 0 );

   sdramD:              inout std_logic_vector( 15 downto 0 );
      
   sdramDqml:           out   std_logic;
   sdramDqmh:           out   std_logic;
   
   sdramCas:            out   std_logic;
   sdramRas:            out   std_logic;
   
   sdramWen:            out   std_logic;
   sdramCsn:            out   std_logic;
   
   --cpu interface
   cpuSdramCE:          in    std_logic;
   cpuSdramA:           in    std_logic_vector( 22 downto 0 );
   
   cpuDataOutForCPU:    out   std_logic_vector( 31 downto 0 );
   cpuDataIn:           in    std_logic_vector( 31 downto 0 );
   
   cpuWr:               in    std_logic;
   cpuDataMask:         in    std_logic_vector( 3 downto 0 );
   cpuSdramReady:       out   std_logic

   
);
end component;


-- differential output buffer
component diffBuf IS
port(
      datain      : IN STD_LOGIC_VECTOR (0 DOWNTO 0);
      dataout     : OUT STD_LOGIC_VECTOR (0 DOWNTO 0);
      dataout_b   : OUT STD_LOGIC_VECTOR (0 DOWNTO 0)
   );
end component;


-- dvi encoder
component dvid is
    Port ( clk       : in  STD_LOGIC;
           clk_pixel : in  STD_LOGIC;
           red_p     : in  STD_LOGIC_VECTOR (7 downto 0);
           green_p   : in  STD_LOGIC_VECTOR (7 downto 0);
           blue_p    : in  STD_LOGIC_VECTOR (7 downto 0);
           blank     : in  STD_LOGIC;
           hsync     : in  STD_LOGIC;
           vsync     : in  STD_LOGIC;
           red_s     : out STD_LOGIC;
           green_s   : out STD_LOGIC;
           blue_s    : out STD_LOGIC;
           clock_s   : out STD_LOGIC);
end component;

-- fp alu
component fpAlu is
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

end component;


-- blitter
component blitter is

generic(
   inst3DAcceleration:     boolean := true
);

port(

   --cpu interface

   reset:            in    std_logic;
   clock:            in    std_logic;
   a:                in    std_logic_vector( 15 downto 0 );
   din:              in    std_logic_vector( 31 downto 0 );
   dout:             out   std_logic_vector( 31 downto 0 );
   
   ce:               in    std_logic;
   wr:               in    std_logic;
   dataMask:         in    std_logic_vector( 3 downto 0 );
   
   ready:            out   std_logic;
   
   --dma interface
   
   dmaDin:           in    std_logic_vector( 31 downto 0 );
   dmaDout:          out   std_logic_vector( 31 downto 0 );
   
   dmaA:             out   std_logic_vector( 21 downto 0 );
   dmaRWn:           out   std_logic;
   dmaRequest:       out   std_logic;
   dmaTransferSize:  out   std_logic;
   dmaTransferMask:  out   std_logic_vector( 1 downto 0 );
   dmaReady:         in    std_logic

);

end component;

-- signals

-- active high async reset
signal   reset:      std_logic;

-- main pll
signal   pllLocked:  std_logic;

-- gfx pll
signal   gfxPllLocked:  std_logic;

-- global clocks
signal   clk25:      std_logic;
signal   clk50:      std_logic;
signal   clk100:     std_logic;
signal   clk100ps:   std_logic;  --100 MHz phase shifted
signal   clk12:      std_logic;  --12 MHz USB clock

signal   clk125:     std_logic;  --hdmi pixel clock
signal   clk125ps:   std_logic;  --hdmi pixel clock phase shifted

-- txt pixel gen signals
signal   pgClock:          std_logic;
signal   pgVSync:          std_logic;
signal   pgHSync:          std_logic;
signal   pgDe:             std_logic;
signal   pgR:              std_logic_vector( 7 downto 0 );
signal   pgG:              std_logic_vector( 7 downto 0 );
signal   pgB:              std_logic_vector( 7 downto 0 ); 
signal   pgXCount:         std_logic_vector( 11 downto 0 );
signal   pgYCount:         std_logic_vector( 11 downto 0 );
signal   pgDeX:            std_logic;
signal   pgDeY:            std_logic;
signal   pgPreFetchLine:   std_logic;
signal   pgFetchEnable:    std_logic;
signal   videoRamBDout:    std_logic_vector( 15 downto 0 );
signal   videoRamBA:       std_logic_vector( 13 downto 0 );

-- gfx pixel gen signals
signal   pggR:             std_logic_vector( 7 downto 0 );
signal   pggG:             std_logic_vector( 7 downto 0 );
signal   pggB:             std_logic_vector( 7 downto 0 ); 
signal   pggDMARequest:    std_logic_vector( 1 downto 0 );


-- font rom signals
signal   fontRomA:        std_logic_vector( 10 downto 0 );
signal   fontRomDout:     std_logic_vector( 7 downto 0 );


-- uart signals
signal   uartClock:           std_logic;

signal   uartCE:              std_logic;
signal   uartDoutForCPU:      std_logic_vector( 31 downto 0 );
signal   uartReady:           std_logic;

signal   uartTxd:             std_logic;
signal   uartRxd:             std_logic;

-- system ram signals
signal   fpgaCpuMemoryClock:           std_logic;
signal   systemRamDoutForCPU:          std_logic_vector( 31 downto 0 );
signal   systemRamDoutForPixelGen:     std_logic_vector( 31 downto 0 );
signal   systemRAMCE:                  std_logic;

-- fast ram signals
signal   fastRamDoutForCPU:            std_logic_vector( 31 downto 0 );
signal   fastRAMCE:                    std_logic;


-- cpu signals
signal   cpuClock:         std_logic;
signal   cpuResetn:        std_logic;
signal   cpuAOut:          std_logic_vector( 29 downto 0 );
signal   cpuDOut:          std_logic_vector( 31 downto 0 );

signal   cpuMemValid:      std_logic;
signal   cpuMemInstr:      std_logic; 
signal   cpuMemReady:      std_logic;
signal   cpuAOutFull:      std_logic_vector( 31 downto 0 );
signal   cpuWrStrobe:      std_logic_vector( 3 downto 0 );
signal   cpuDin:           std_logic_vector( 31 downto 0 );

signal   cpuWr:            std_logic;
signal   cpuDataMask:      std_logic_vector( 3 downto 0 );
      

-- SPI signals
signal   spiClock:         std_logic;
signal   spiCE:            std_logic;
signal   spiDoutForCPU:    std_logic_vector( 31 downto 0 );
signal   spiReady:         std_logic;

signal   spiSClk:          std_logic;
signal   spiMOSI:          std_logic;
signal   spiMISO:          std_logic;

-- gpo signals
signal   gpoRegister:      std_logic_vector( 7 downto 0 );


-- registers signals

signal   registersClock:      std_logic;

type     regState_T is ( rsWaitForRegAccess, rsWaitForBusCycleEnd );
signal   registerState:       regState_T;

signal   registersCE:         std_logic;
signal   registersDoutForCPU: std_logic_vector( 31 downto 0 );

-- video mux signals
signal   vmMode:  std_logic_vector( 15 downto 0 );

-- dma process signals
signal   dmaClock:               std_logic;
                     
-- dma ch0 buf ram signals ( for gfx pixel gen )
signal   gfxBufRamDOut:          std_logic_vector( 31 downto 0 );
signal   gfxBufRamRdA:           std_logic_vector( 8 downto 0 );
signal   dmaDisplayPointerStart: std_logic_vector( 20 downto 0 );

-- dma ch2 signals (blitter)
signal   dmaCh2Request:          std_logic;
signal   dmaCh2Ready:            std_logic;
signal   dmaCh2RWn:              std_logic;
signal   dmaCh2Din:              std_logic_vector( 31 downto 0 );
signal   dmaCh2Dout:             std_logic_vector( 31 downto 0 );
signal   dmaCh2A:                std_logic_vector( 21 downto 0 );
signal   dmaCh2TransferSize:     std_logic;
signal   dmaCh2TransferMask:     std_logic_vector( 1 downto 0 );

-- dma ch3 signals ( cpu )
signal   dmaMemoryCE:            std_logic;
signal   cpuDmaReady:            std_logic;
signal   dmaDoutForCPU:          std_logic_vector( 31 downto 0 );


-- tick timer signals
signal   tickTimerClock:            std_logic;
signal   tickTimerReset:            std_logic;
signal   tickTimerPrescalerCounter: std_logic_vector( 31 downto 0 );
signal   tickTimerCounter:          std_logic_vector( 31 downto 0 );

constant tickTimerPrescalerValue:   integer:=   50000 - 1;  --1ms tick timer @50MHz

-- usb host signals
signal   usbHostClock:           std_logic;
signal   usbHostCE:              std_logic;
signal   usbHostReady:           std_logic;
signal   usbHostDoutForCPU:      std_logic_vector( 31 downto 0 );

-- usb phy clock ( 12 MHz )
signal   usbHClk:                std_logic;

-- blitter signals
signal   blitterClock:           std_logic;
signal   blitterCE:              std_logic;
signal   blitterReady:           std_logic;
signal   blitterDoutForCPU:      std_logic_vector( 31 downto 0 );

-- frameTimer signals
signal   frameTimerClock:        std_logic;
signal   frameTimerReset:        std_logic;
signal   frameTimerPgPrvVSync:   std_logic;
signal   frameTimerValue:        std_logic_vector( 31 downto 0 );

-- sdram controller signals
signal   sdramClock:             std_logic;
signal   sdramCtrlClock:         std_logic;
signal   sdramCtrlCE:            std_logic;
signal   sdramCtrlDataOutForCPU: std_logic_vector( 31 downto 0 );
signal   sdramCtrlSdramReady:    std_logic;

-- hdmi controller signals
signal   tmdsClk:    std_logic;
signal   tmdsData:   std_logic_vector( 2 downto 0 );

signal   dviClock:   std_logic;
signal   dviClockps: std_logic;
signal   dviRed:     std_logic_vector( 7 downto 0 );
signal   dviGreen:   std_logic_vector( 7 downto 0 );
signal   dviBlue:    std_logic_vector( 7 downto 0 );
signal   dviHSync:   std_logic;
signal   dviVSync:   std_logic;
signal   dviBlank:   std_logic;
   
-- fpalu signals
signal   fpAluClock:       std_logic;
signal   fpAluCE:          std_logic;
signal   fpAluDoutForCPU:  std_logic_vector( 31 downto 0 );
signal   fpAluReady:       std_logic;

begin

-- async reset signals 

   reset       <= not pllLocked;
   cpuResetn   <= core_board_key and pllLocked;

-- place main pll
mainPllInst: mainPll
   port map
   (
      areset   => not core_board_reset,
      inclk0   => core_board_clk_50,
--    c0       => clk25,
      c1       => clk50,
      c2       => clk100,
      c3       => clk12,
      c4       => clk100ps,
      locked   => pllLocked
   
   );

-- place gfx pll
gfxPllInst : gfxPll 
   port map
   (
      areset    => not core_board_reset,
      inclk0   => core_board_clk_50,
      
      c0       => clk25,               --25 MHz
      c1       => clk125,              --125 MHz
      c2       => clk125ps,            --125 MHz 180 degree ps
      locked   => gfxPllLocked
   
   );

-- connect gpo to leds
   core_board_leds <= gpoRegister( 5 downto 4 );
   
   
-- clock config

-- txt pixel gen clock
   pgClock              <= clk25;

-- cpu clock
   cpuClock             <= clk50;
   
-- fpga cpu memory clock ( system RAM, fast ram )
   fpgaCpuMemoryClock   <= not cpuClock;
   
-- registers process clock
   registersClock       <= clk100;

-- uart clock
   uartClock            <= clk100;
   
-- sram direct memory access process clock
   dmaClock             <= clk100;

-- tick timer clock
   tickTimerClock       <= clk50;

-- frame timer process clock (not timer clock)
   frameTimerClock   <= clk100;

-- blitter clock
   blitterClock      <= clk100;

-- spi clock
   spiClock          <= clk50;

-- fpAlu clock
   fpAluClock        <= clk100;
         
-- usb host clock
   usbHostClock      <= clk100;

--usb phy clock ( 12MHz )
   usbHClk           <= clk12;
      
-- sdram memory clock
   sdramClock        <= clk100ps;
   
-- sdram controller clock
   sdramCtrlClock    <= clk100;
   
-- hdmi encoder clocks
   dviClock          <= clk125;
   dviClockPs        <= clk125ps;
   
   
-- place text mode font rom   
fontPromInst: fontProm 
   port map(
      clock    => pgClock,
      address  => fontRomA,
      q        => fontRomDout
   );

      
   --place txt pixel gen
   pixelGenInst: pixelGenTxt
    port map(
        reset           => reset,
        pgClock         => pgClock,

        pgVSync         => pgVSync,
        pgHSync         => pgHSync,
        pgDe            => pgDe,
        pgR             => pgR,
        pgG             => pgG,
        pgB             => pgB,

        fontRomA        => fontRomA,
        fontRomDout     => fontRomDout,

        videoRamBA      => videoRamBA,
        videoRamBDout   => videoRamBDout,
        
        pgXCount        => pgXCount,
        pgYCount        => pgYCount,
        pgDeX           => pgDeX,
        pgDeY           => pgDeY,
        pgPreFetchLine  => pgPreFetchLine,
        pgFetchEnable   => pgFetchEnable,
      
      pgVideoMode       => vmMode( 3 downto 2 )
        
    );   

   
-- place gfx pixel gen

   pixelGenGfxInst: pixelGenGfx
   port map(
      reset             => reset,
      pggClock          => pgClock,
      
      pggR              => pggR,
      pggG              => pggG,
      pggB              => pggB,

      --gfx buffer ram
      gfxBufRamDOut     => gfxBufRamDOut,
      gfxBufRamRdA      => gfxBufRamRdA,
   
      --2 dma requests
      pggDMARequest     => pggDMARequest,

      --sync gen outputs
      pgVSync           => pgVSync,
      pgHSync           => pgHSync,
      pgDe              => pgDe,
      pgXCount          => pgXCount,
      pgYCount          => pgYCount,
      pgDeX             => pgDeX,
      pgDeY             => pgDeY,
      pgPreFetchLine    => pgPreFetchLine,
      pgFetchEnable     => pgFetchEnable,
      
      pgVideoMode       => vmMode( 5 downto 4 )
   );

   

--video out mux (pixelGenTxt and pixelGenGfx to analog vga and hdmi)

videoMux: process( all )

begin

   if rising_edge( pgClock ) then
   
      if reset = '1' then
                           
      else
      
         case vmMode( 1 downto 0 ) is
         
            --text mode
            when "00" =>
            
               hsync       <= pgHSync;
               vsync       <= pgVSync;
               
               red         <= pgR( 7 downto 3 );
               green       <= pgG( 7 downto 3 );
               blue        <= pgB( 7 downto 3 );

               dviHSync    <= pgHSync;
               dviVSync    <= pgVSync;
               dviBlank    <= not pgDE;
               
               dviRed      <= pgR( 7 downto 3 ) & "000";
               dviGreen    <= pgG( 7 downto 2 ) & "00";
               dviBlue     <= pgB( 7 downto 3 ) & "000";
         
            --gfx mode
            when "01"   =>
            
               hsync       <= pgHSync;
               vsync       <= pgVSync;
               
               red      <= pggR( 7 downto 3 );
               green    <= pggG( 7 downto 3 );
               blue     <= pggB( 7 downto 3 );

               dviHSync    <= pgHSync;
               dviVSync    <= pgVSync;
               dviBlank    <= not pgDE;
               
               dviRed      <= pggR( 7 downto 3 ) & "000";
               dviGreen    <= pggG( 7 downto 2 ) & "00";
               dviBlue     <= pggB( 7 downto 3 ) & "000";

            --text over gfx mode
            when "10" =>
            
               hsync       <= pgHSync;
               vsync       <= pgVSync;
               dviHSync    <= pgHSync;
               dviVSync    <= pgVSync;
               dviBlank    <= not pgDE;
               

               if pgR = x"00" and pgG = x"00" and pgB = x"00" then
                  
                  red      <= pggR( 7 downto 3 );
                  green    <= pggG( 7 downto 3 );
                  blue     <= pggB( 7 downto 3 );
               
                  dviRed      <= pggR( 7 downto 3 ) & "000";
                  dviGreen    <= pggG( 7 downto 2 ) & "00";
                  dviBlue     <= pggB( 7 downto 3 ) & "000";
                  
               --gray color -> dim background
               elsif pgR = x"80" and pgG = x"80" and pgB = x"80" then
            
                  red      <= "0" & pggR( 7 downto 4 );
                  green    <= "0" & pggG( 7 downto 4 );
                  blue     <= "0" & pggB( 7 downto 4 );
                                 
                  dviRed      <= "0" & pggR( 7 downto 3 ) & "00";
                  dviGreen    <= "0" & pggG( 7 downto 2 ) & "0";
                  dviBlue     <= "0" & pggB( 7 downto 3 ) & "00";
               else

                  red      <= pgR( 7 downto 3 );
                  green    <= pgG( 7 downto 3 );
                  blue     <= pgB( 7 downto 3 );
            
                  dviRed      <= pgR( 7 downto 3 ) & "000";
                  dviGreen    <= pgG( 7 downto 2 ) & "00";
                  dviBlue     <= pgB( 7 downto 3 ) & "000";
               
               end if;

            --gfx over text mode
            when "11" =>
            
               hsync       <= pgHSync;
               vsync       <= pgVSync;

               dviHSync    <= pgHSync;
               dviVSync    <= pgVSync;
               dviBlank    <= not pgDE;
               

               --dviDE       <= pgDE;

               if pggR = x"00" and pggG = x"00" and pggB = x"00" then
                  
                  red      <= pgR( 7 downto 3 );
                  green    <= pgG( 7 downto 3 );
                  blue     <= pgB( 7 downto 3 );
                                 
                  dviRed      <= pgR( 7 downto 3 ) & "000";
                  dviGreen    <= pgG( 7 downto 2 ) & "00";
                  dviBlue     <= pgB( 7 downto 3 ) & "000";
               
               else

                  red      <= pggR( 7 downto 3 );
                  green    <= pggG( 7 downto 3 );
                  blue     <= pggB( 7 downto 3 );              
                  
                  dviRed      <= pggR( 7 downto 3 ) & "000";
                  dviGreen    <= pggG( 7 downto 2 ) & "00";
                  dviBlue     <= pggB( 7 downto 3 ) & "000";
                  
               end if;

            when others =>
            
            
         end case;
      
      end if;
   
   end if;
   
end process;

-- place uart
   
   extUartTx   <= uartTxd;
   uartRxd     <= extUartRx;

   UARTInst: UART
    port map(
      reset    => reset,
      clock    => uartClock,     
      
      a        => cpuAOut( 15 downto 0 ),
      din      => cpuDOut,
      dout     => uartDoutForCPU,
      ce       => uartCE,
      wr       => cpuWr,
      dataMask => cpuDataMask,
      ready    => uartReady,        
        
      uartTXD  => uartTxd,
      uartRXD  => uartRxd
      
    );  

-- place SPI   
   
   sdMciClk    <= spiSClk;
   sdMciDat(3) <= gpoRegister( 0 ); --cs
   sdMciCmd    <= spiMOSI;
   spiMISO     <= sdMciDat( 0 );


   sdMciDat(2 downto 0 )   <= "ZZZ";

   
SPIInst:SPI
port map(

   --cpu interface
   reset       => reset,
   clock       => spiClock,

   a           => cpuAOut( 15 downto 0 ),
   din         => cpuDOut,
   dout        => spiDoutForCPU,
   
   ce          => spiCE,
   wr          => cpuWr,
   dataMask    => cpuDataMask,
   
   ready       => spiReady,
   
   --spi interface
   sclk        => spiSClk,
   mosi        => spiMOSI,
   miso        => spiMISO
   
);

   
-- place system ram ( bootloader, stack, textmode data )
   systemRAMInst: systemRAM 
   port map
   (
      address_a      => cpuAOut( 12 downto 0 ),
      address_b      => videoRamBA( 13 downto 1 ),
      byteena_a      => cpuDataMask,
      byteena_b      => "1111",
      clock_a        => fpgaCpuMemoryClock,
      clock_b        => pgClock,
      data_a         => cpuDOut,
      data_b         => ( others => '0' ),
      wren_a         => cpuWr and systemRAMCE,
      wren_b         => '0',
      q_a            => systemRamDoutForCPU,
      q_b            => systemRamDoutForPixelGen
   );

   
   videoRamBDout  <= systemRamDoutForPixelGen( 15 downto 0 ) when videoRamBA( 0 ) = '0' else systemRamDoutForPixelGen( 31 downto 16 );
   
-- place fast RAM
   fastRAMInst: fastRAM 
   port map
   (
      address_a      => cpuAOut( 16 downto 0 ),
      address_b      => ( others => '0' ),
      byteena_a      => cpuDataMask,
      byteena_b      => "1111",
      clock_a        => fpgaCpuMemoryClock,
      clock_b        => '0',
      data_a         => cpuDOut,
      data_b         => ( others => '0' ),
      wren_a         => cpuWr and fastRAMCE,
      wren_b         => '0',
      q_a            => fastRamDoutForCPU
      --q_b          : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
   );

   
-- place picorv32
   
-- bus signals
   cpuAOut           <= cpuAOutFull( 31 downto 2 );

   cpuWr             <= cpuWrStrobe( 3 ) or cpuWrStrobe( 2 ) or cpuWrStrobe( 1 ) or cpuWrStrobe( 0 );

   cpuDataMask       <= cpuWrStrobe when cpuWr = '1' else "1111";


-- chip selects
   systemRAMCE       <= '1' when ( cpuMemValid = '1' ) and cpuAOutFull( 31 downto 20 ) = x"000" else
                        '0';

   fastRAMCE         <= '1' when ( cpuMemValid = '1'  ) and cpuAOutFull( 31 downto 24 ) = x"30" else '0';
         
   dmaMemoryCE       <= '1' when ( cpuMemValid = '1'  ) and cpuAOutFull( 31 downto 24 ) = x"20" else '0';
         
   registersCE       <= '1' when ( cpuMemValid = '1' ) and cpuAOutFull( 31 downto 20 ) = x"f00" else '0';

   fpAluCE           <= '1' when ( cpuMemValid = '1' ) and cpuAOutFull( 31 downto 20 ) = x"f01" else '0';
   
   blitterCE         <= '1' when ( cpuMemValid = '1' ) and cpuAOutFull( 31 downto 20 ) = x"f02" else '0';

   usbHostCE         <= '1' when ( cpuMemValid = '1' ) and cpuAOutFull( 31 downto 20 ) = x"f03" else '0';

   uartCE            <= '1' when ( cpuMemValid = '1' ) and cpuAOutFull( 31 downto 20 ) = x"f04" else '0';

   spiCE             <= '1' when ( cpuMemValid = '1' ) and cpuAOutFull( 31 downto 20 ) = x"f05" else '0';
   
   sdramCtrlCE       <= '1' when ( cpuMemValid = '1'  ) and cpuAOutFull( 31 downto 28 ) = x"4" else '0';
   
-- bus slaves ready signals mux
   cpuMemReady       <= '1' when systemRAMCE = '1' or fastRAMCE = '1' or registersCE = '1' 
                        else fpAluReady when fpAluCE = '1' 
                        else blitterReady when blitterCE = '1' 
                        else usbHostReady when usbHostCE = '1' 
                        else uartReady when uartCE = '1' 
                        else spiReady when spiCE = '1' 
                        else cpuDmaReady when dmaMemoryCE = '1' 
                        else sdramCtrlSdramReady when sdramCtrlCE = '1' 
                        else '1';


-- bus slaves data outputs mux
   cpuDin            <= systemRamDoutForCPU                       when cpuAOutFull( 31 downto 20 ) = x"000" else 
                        fastRamDoutForCPU                         when cpuAOutFull( 31 downto 24 ) = x"30"  else 
                        registersDoutForCPU                       when cpuAOutFull( 31 downto 20 ) = x"f00" else
                        fpAluDoutForCPU                           when cpuAOutFull( 31 downto 20 ) = x"f01" else
                        blitterDoutForCPU                         when cpuAOutFull( 31 downto 20 ) = x"f02" else
                        usbHostDoutForCPU                         when cpuAOutFull( 31 downto 20 ) = x"f03" else 
                        uartDoutForCPU                            when cpuAOutFull( 31 downto 20 ) = x"f04" else
                        spiDoutForCPU                             when cpuAOutFull( 31 downto 20 ) = x"f05" else
                        dmaDoutForCPU                             when cpuAOutFull( 31 downto 24 ) = x"20"  else
                        sdramCtrlDataOutForCPU                    when cpuAOutFull( 31 downto 28 ) = x"4"   else
                        x"00000000";

                     
-- the cpu
   picorv32Inst: picorv32 
   port map
   (
      clk               => cpuClock,
      resetn            => cpuResetn,
      --trap:           out std_logic;
      mem_valid         => cpuMemValid,
      mem_instr         => cpuMemInstr,
      mem_ready         => cpuMemReady,

      mem_addr          => cpuAOutFull,
      mem_wdata         => cpuDOut,
      mem_wstrb         => cpuWrStrobe,
      mem_rdata         => cpuDin,

      --Look-Ahead Interface
      --mem_la_read:    out std_logic;
      --mem_la_write:   out std_logic;
      --mem_la_addr: out std_logic_vector( 31 downto 0 );
      --mem_la_wdata:   out std_logic_vector( 31 downto 0 );
      --mem_la_wstrb:   out std_logic_vector( 3 downto 0 );

      --Pico Co-Processor Interface (PCPI)
      --pcpi_valid:     out std_logic;
      --pcpi_insn:      out std_logic_vector( 31 downto 0 );
      --pcpi_rs1:    out std_logic_vector( 31 downto 0 );
      --pcpi_rs2:    out std_logic_vector( 31 downto 0 );
      pcpi_wr           => '0',
      pcpi_rd           => ( others => '0' ),
      pcpi_wait         => '0',
      pcpi_ready        => '0',

      --IRQ Interface
      irq               => ( others => '0' )
      --eoi:            out std_logic_vector( 31 downto 0 );

      --Trace Interface
      --trace_valid: out std_logic;
      --trace_data:     out std_logic_vector( 35 downto 0 )

);
 

--registers process
registers: process( all )

begin
   
   if rising_edge( registersClock ) then
   
      if reset = '1' then
      
         registersDoutForCPU  <= ( others => '0' );
         
         --default register values
         vmMode                  <= x"0002";
         dmaDisplayPointerStart  <= ( others => '0' );
         gpoRegister             <= ( others => '1' );
         
         tickTimerReset             <= '0';
                  
         registerState              <= rsWaitForRegAccess;

      else
      
         tickTimerReset             <= '0';
         frameTimerReset            <= '0';
         
         case registerState is
         
            when rsWaitForRegAccess =>
         
               if registersCE = '1' then
                  
                  case cpuAOut( 7 downto 0 ) is
               
               
                     --rw 0xf0000008 - videoMuxMode
                     when x"02" =>
               
                        registersDoutForCPU  <= x"0000" & vmMode;
                        
                        if cpuWr = '1' then
                        
                           vmMode   <= cpuDOut( 15 downto 0 );
                        
                        end if;
               
                     --rw 0xf000000c - videoVSync
                     when x"03" =>
               
                        registersDoutForCPU  <= x"0000" & x"000" & "000" & pgVSync;

                     --rw 0xf0000010 - dmaDisplayPointerStart
                     when x"04" =>
               
                        registersDoutForCPU  <= "00000000000" & dmaDisplayPointerStart;
                        
                        if cpuWr = '1' then
                        
                           dmaDisplayPointerStart  <= cpuDOut( 20 downto 0 );
                        
                        end if;
                                       
                     --rw 0xf000001c - gpoPort
                     when x"07" =>
               
                        registersDoutForCPU  <= x"0000" & x"00" & gpoRegister;
                        
                        if cpuWr = '1' then
                        
                           gpoRegister <= cpuDOut( 7 downto 0 );
                        
                        end if;
                        
                     ---w 0xf0000020 - tickTimerConfig
                     when x"08" =>
                                 
                        if cpuWr = '1' then
                        
                           tickTimerReset <= cpuDOut( 0 );
                        
                        end if;  
                        
                     --r- 0xf0000024 - tickTimerValue
                     when x"09" =>
                              
                        registersDoutForCPU  <= tickTimerCounter;
                           
                              
                              
                     --rw 0xf0000028 - frameTimer (write resets timer)
                     when x"0a" =>
                     
                        registersDoutForCPU  <= frameTimerValue;
                     
                        if cpuWr = '1' then
                           
                              frameTimerReset <= '1';
                              
                        end if;
                                             

                     when others =>

                        registersDoutForCPU  <= ( others => '0' );
                     
                  end case; --cpuAOut( 7 downto 0 ) is
               
                  registerState  <= rsWaitForBusCycleEnd;
               
               end if; --registersCE = '1'
         
            when rsWaitForBusCycleEnd =>
                     
               --wait for bus cycle to end
               if registersCE = '0' then
               
                  registerState <= rsWaitForRegAccess;
                  
               end if;
         
            when others =>

               registerState <= rsWaitForRegAccess;
            
         end case;   --registerState is
         
      end if; --! reset = '1'
         
   end if; --rising_edge( registersClock )
   

end process;


-- place static ram controller and DMA

sramControllerInst:sramController
port map(

   reset                => reset,
   clock                => dmaClock,

   --gfx display mode interface ( ch0 )
   ch0DmaRequest        => pggDMARequest,
   ch0DmaPointerStart   => dmaDisplayPointerStart,
   ch0DmaPointerReset   => pgVSync,
   
   ch0BufClk            => not pgClock,
   ch0BufDout           => gfxBufRamDOut,
   ch0BufA              => gfxBufRamRdA,
   
   
   --audio interface ( ch1 )
   
   --tbd
   

   --blitter interface ( ch2 )
   ch2DmaRequest     => dmaCh2Request,
   ch2A              => dmaCh2A,
   ch2Din            => dmaCh2Din,
   ch2Dout           => dmaCh2Dout,
   ch2RWn            => dmaCh2RWn,
   ch2WordSize       => dmaCh2TransferSize,
   ch2DataMask       => dmaCh2TransferMask,
   ch2Ready          => dmaCh2Ready,
   
   
   --cpu interface ( ch3 )
   a           => cpuAOut( 20 downto 0 ),
   din         => cpuDOut,
   dout        => dmaDoutForCPU,
   
   ce          => dmaMemoryCE,
   wr          => cpuWr,
   dataMask    => cpuDataMask,   
   ready       => cpuDmaReady,
   
   
   --static ram interface
   gds0_7n     => gds0_7n,
   gds8_15n    => gds8_15n,
   gds16_23n   => gds16_23n,
   gds24_31n   => gds24_31n,
      
   gwen        => gwen,
   goen        => goen,

   ga          => ga,
   gd          => gd
);


--tick timer process

tickTimer: process( all )
begin

   if rising_edge( tickTimerClock ) then
   
      if reset = '1' then
         
         tickTimerPrescalerCounter  <= ( others => '0' );
         tickTimerCounter           <= ( others => '0' );
         
      
      else
      
         if tickTimerPrescalerCounter /= x"00000000" then
            
            tickTimerPrescalerCounter <= tickTimerPrescalerCounter - 1;
            
         else
         
            tickTimerPrescalerCounter <= conv_std_logic_vector( tickTimerPrescalerValue, tickTimerPrescalerCounter'length );
            
            tickTimerCounter <= tickTimerCounter + 1;
         
         end if;
      
         if tickTimerReset = '1' then

            tickTimerPrescalerCounter  <= ( others => '0' );
            tickTimerCounter           <= ( others => '0' );
         
         end if;
         
      
      end if;  --reset = '1'
   
   
   end if; --rising_edge( tickTimerClock )

end process;


-- frame timer process

frameTimerProcess: process( all )
begin
   
   if rising_edge( frameTimerClock ) then

      if frameTimerReset = '1' then
      
         frameTimerValue <= ( others => '0' );
         
      else
      
         frameTimerPgPrvVSync <= pgVSync;
         
         
         if frameTimerPgPrvVSync = '0' and pgVSync = '1' then
      
            frameTimerValue <= frameTimerValue + '1';
            
         end if;
      
      end if;
   
   end if; -- rising_edge( frameTimerClock )
end process;


-- place blitter

blitterInst:blitter
generic map(
   inst3DAcceleration   => instBlitter3DAcceleration
)
port map(

   --cpu interface

   reset          => reset,
   clock          => blitterClock,
   a              => cpuAOut( 15 downto 0 ),
   din            => cpuDOut,
   dout           => blitterDoutForCpu,
   
   ce             => blitterCE,
   wr             => cpuWr,
   dataMask       => cpuDataMask,
   
   ready          => blitterReady,
   
   --dma interface

   dmaDin            => dmaCh2Dout,
   dmaDout           => dmaCh2Din,
   
   dmaA              => dmaCh2A,
   dmaRWn            => dmaCh2RWn,
   dmaRequest        => dmaCh2Request,
   dmaTransferSize   => dmaCh2TransferSize,
   dmaTransferMask   => dmaCh2TransferMask,
   dmaReady          => dmaCh2Ready

);
 
instFastFloatingMathGen: if( instFastFloatingMath = true ) generate

-- place fpAlu
fpAluInst:fpAlu
port map(
   reset    => reset,
   clock    => fpAluClock,
   a        => cpuAOut( 15 downto 0 ),
   din      => cpuDOut,
   dout     => fpAluDoutForCPU,
   
   ce       => fpAluCE,
   wr       => cpuWr,
   dataMask => cpuDataMask,
   
   ready    => fpAluReady
);

end generate;

    

instHidUSBHostGen: if ( instHidUSBHost = true ) generate

   -- place usb host
   usbHostInst: usbHost
   port map(

      --cpu interface
      reset          => reset,
      clock          => usbHostClock,
      a              => cpuAOut( 15 downto 0 ),
      din            => cpuDOut,
      dout           => usbHostDoutForCpu,
      
      ce             => usbHostCE,
      wr             => cpuWr,
      dataMask       => cpuDataMask,
      
      ready          => usbHostReady,
      
      --usb phy clock (12MHz)
      usbHClk        => usbHClk,
      
      --usb interfaces
      usbH0Dp        => usbhDp,
      usbH0Dm        => usbhDm   

   );

end generate;


-- place sdram controller
   sd1_clk  <= sdramClock;
   
sdramControllerInst:sdramController
port map(

   clk            => sdramCtrlClock,
   reset          => reset,
   
   --sdram interface
   sdramCke       => sd1_cke,

   sdramA         => sd1_a,
   sdramBa        => sd1_ba,

   sdramD         => sd1_d,
      
   sdramDqml      => sd1_dqml,
   sdramDqmh      => sd1_dqmh,
   
   sdramCas       => sd1_cas,
   sdramRas       => sd1_ras,
   
   sdramWen       => sd1_wen,
   sdramCsn       => sd1_csn,
   
   --cpu interface
   cpuSdramCE     => sdramCtrlCE,
   cpuSdramA      => cpuAOut( 22 downto 0 ),
   
   cpuDataOutForCPU  => sdramCtrlDataOutForCPU,
   cpuDataIn         => cpuDOut,
   
   cpuWr             => cpuWr,
   cpuDataMask       => cpuDataMask,
   cpuSdramReady     => sdramCtrlSdramReady
);




instHDMIOutputGen: if ( instHDMIOutput = true ) generate

-- place hdmi diff bufs

diffBufTmdsClk : diffBuf 
   port map(
      datain(0)      => tmdsClk,
      dataout(0)     => tmdsOutClk,
      dataout_b(0)   => tmdsOutClkN
   );

diffBufTmdsData0 : diffBuf 
   port map(
      datain(0)      => tmdsData(0),
      dataout(0)     => tmdsOutData(0),
      dataout_b(0)   => tmdsOutDataN(0)
   );

diffBufTmdsData1 : diffBuf 
   port map(
      datain(0)      => tmdsData(1),
      dataout(0)     => tmdsOutData(1),
      dataout_b(0)   => tmdsOutDataN(1)
   );

diffBufTmdsData2 : diffBuf 
   port map(
      datain(0)      => tmdsData(2),
      dataout(0)     => tmdsOutData(2),
      dataout_b(0)   => tmdsOutDataN(2)
   );



-- place dvi encoder

dvidInst: dvid 
port map(
      clk       => dviClock,
      clk_pixel => pgClock,
      red_p     => dviRed,
      green_p   => dviGreen,
      blue_p    => dviBlue,
      blank     => dviBlank,
      hsync     => dviHSync,
      vsync     => dviVsync,
      -- outputs to TMDS drivers
      red_s     => tmdsData(2),
      green_s   => tmdsData(1),
      blue_s    => tmdsData(0),
      clock_s   => tmdsClk
   );

end generate;
   
end behavior;


