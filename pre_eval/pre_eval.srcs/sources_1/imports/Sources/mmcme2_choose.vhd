--
-- NAME:
--
--    mmcme2_choose.vhd
--
-- PURPOSE:
--
--    This is a clock generator using MMCME2_ADV (Mixed Mode Clock Manager).
--    It generates 3 clocks from which we choose one because we cannot
--    have more than one pixel clock at the same time.
--    The criteria by which we make the choice is res_y_i (480 to 1080).


LIBRARY IEEE;
LIBRARY UNISIM;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.VCOMPONENTS.ALL;
USE work.graphics.ALL;

ENTITY mmcme2_choose IS
    PORT( clk_i         : IN  std_logic;
          res_y_i       : IN  integer range 480 to 1080; -- criteria for choosing the pixel clock
          mmcm_rst      : IN  std_logic;
          sclk_x5_o     : OUT std_logic;
          pixel_clk_o   : OUT std_logic;
          mmcm_locked_o : OUT std_logic);
END ENTITY mmcme2_choose;
 
ARCHITECTURE mmcme2_choose_a OF mmcme2_choose IS
  
    SIGNAL pixel_clk_480  : std_logic;  
    SIGNAL pixel_clk_720  : std_logic;  
    SIGNAL pixel_clk_1080 : std_logic;  
    SIGNAL clkfb         : std_logic;
  
BEGIN

  -- Generating the 3 clocks from which we choose one to be the pixel clock
  mmcme2_adv_inst : MMCME2_ADV
    GENERIC MAP( BANDWIDTH          => "OPTIMIZED",
                 CLKFBOUT_MULT_F    => 12.0,
                 CLKFBOUT_PHASE     => 0.0,
                 CLKIN1_PERIOD      => 8.0,

                 CLKOUT0_DIVIDE_F   => 1.0,
                 CLKOUT1_DIVIDE     => 30,      -- 480: 25 MHz
                 CLKOUT2_DIVIDE     => 10,      -- 720: 75 MHz
                 CLKOUT3_DIVIDE     => 5,       -- 1080: 150MHz 
   
                 COMPENSATION       => "ZHOLD",
                 DIVCLK_DIVIDE      => 2,
                 REF_JITTER1        => 0.0)
    PORT MAP( CLKOUT0      => sclk_x5_o,
              CLKOUT0B     => OPEN,
              CLKOUT1      => pixel_clk_480,
              CLKOUT1B     => OPEN,
              CLKOUT2      => pixel_clk_720,
              CLKOUT2B     => OPEN,
              CLKOUT3      => pixel_clk_1080,
              CLKOUT3B     => OPEN,
              CLKOUT4      => OPEN,
              CLKOUT5      => OPEN,
              CLKOUT6      => OPEN,
              CLKFBOUT     => clkfb,
              CLKFBOUTB    => OPEN,

              CLKIN1       => clk_i,
              CLKIN2       => '0',
              CLKFBIN      => clkfb,
              CLKINSEL     => '1',

              DCLK         => '0',
              DEN          => '0',
              DWE          => '0',
              DADDR        => (OTHERS => '0'),
              DI           => (OTHERS => '0'),
              DO           => OPEN,
              DRDY         => OPEN,
        
              PSCLK        => '0',
              PSEN         => '0',
              PSINCDEC     => '0',
              PSDONE       => OPEN,
        
              LOCKED       => mmcm_locked_o,
              PWRDWN       => '0',
              RST          => mmcm_rst,
              CLKFBSTOPPED => OPEN,
              CLKINSTOPPED => OPEN);
              
    -- Choosing the pixel clock:
    pixel_clk_o <= pixel_clk_480  WHEN res_y_i = 480 ELSE
                   pixel_clk_720  WHEN res_y_i = 720 ELSE
                   pixel_clk_1080 WHEN res_y_i = 1080 ELSE
                   pixel_clk_480;
END ARCHITECTURE mmcme2_choose_a;
