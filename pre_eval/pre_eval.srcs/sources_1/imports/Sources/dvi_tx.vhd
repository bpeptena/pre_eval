--
-- NAME:
--
--    dvi_tx.vhd
--
-- PURPOSE:
--
--    Stitching together all the vhdl modules


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY dvi_tx IS
    PORT( clk_i        : IN  std_logic; -- 125 MHz system clock
          rst_i        : IN  std_logic; -- Any board button
          sw_i         : IN  std_logic_vector(1 downto 0); -- switches used for resolution
          dvi_clk_p_o  : OUT std_logic;
          dvi_clk_n_o  : OUT std_logic;
          dvi_tx0_p_o  : OUT std_logic;
          dvi_tx0_n_o  : OUT std_logic;
          dvi_tx1_p_o  : OUT std_logic;
          dvi_tx1_n_o  : OUT std_logic;
          dvi_tx2_p_o  : OUT std_logic;
          dvi_tx2_n_o  : OUT std_logic);
END ENTITY dvi_tx;

ARCHITECTURE dvi_tx_a OF dvi_tx IS

  SIGNAL sclk_x        : std_logic;
  SIGNAL sclk_x5_x     : std_logic;
  SIGNAL pixel_clk_x   : std_logic;
  SIGNAL mmcm_locked_x : std_logic;
  SIGNAL rst_no_lock   : std_logic;
  
  SIGNAL hsync_x       : std_logic;
  SIGNAL vsync_x       : std_logic;
  SIGNAL blank_x       : std_logic;
  SIGNAL hsync_r0_x    : std_logic;
  SIGNAL vsync_r0_x    : std_logic;
  SIGNAL blank_r0_x    : std_logic;
  
  SIGNAL red_x         : std_logic_vector(7 downto 0);
  SIGNAL green_x       : std_logic_vector(7 downto 0);
  SIGNAL blue_x        : std_logic_vector(7 downto 0);
  
  SIGNAL count         : std_logic_vector(20 downto 0);
  
  SIGNAL res_x_x       : integer range 640 to 1920;
  SIGNAL res_y_x       : integer range 480 to 1080;
  SIGNAL res_x_total_x : integer range 800 to 2200;
  SIGNAL res_y_total_x : integer range 525 to 1125;
  SIGNAL pix_reset_x   : std_logic;
  
BEGIN
                 
   dvi_tx_clkgen_inst : ENTITY work.dvi_tx_clkgen
       PORT MAP( clk_i       => clk_i,
                 res_y_i     => res_y_x,
                 arst_i      => rst_i,
                 locked_o    => mmcm_locked_x,
                 pixel_clk_o => pixel_clk_x,
                 sclk_o      => sclk_x,
                 sclk_x5_o   => sclk_x5_x);

   rgb_timing_inst : ENTITY work.rgb_timing
       PORT MAP( clk_i   => pixel_clk_x,
                 sw      => sw_i,
                 pix_reset_o => pix_reset_x,
                 hsync_o => hsync_x,
                 vsync_o => vsync_x,
                 blank_o => blank_x,
                 res_x   => res_x_x,
                 res_y   => res_y_x,
                 res_x_total => res_x_total_x,
                 res_y_total => res_y_total_x);
     
   counter_inst: ENTITY work.counter
      PORT MAP( clk   => pixel_clk_x,
                reset => pix_reset_x,
                max_x => res_x_total_x,
                max_y => res_y_total_x,
                count => count);
        
   rgb_pattern_inst : ENTITY work.rgb_pattern
       PORT MAP( clk_i         => pixel_clk_x,
                 res_x_i       => res_x_x,
                 res_y_i       => res_y_x,
                 res_x_total_i => res_x_total_x,
                 res_y_total_i => res_y_total_x,
                 hsync_i       => hsync_x,
                 vsync_i       => vsync_x,
                 blank_i       => blank_x,
                 pixel_pos     => count,
                 hsync_o       => hsync_r0_x,
                 vsync_o       => vsync_r0_x,
                 blank_o       => blank_r0_x,
                 red_o         => red_x,
                 green_o       => green_x,
                 blue_o        => blue_x);

   rst_no_lock <= (rst_i OR (NOT mmcm_locked_x));

   rgb_to_dvi_inst : ENTITY work.rgb_to_dvi
       PORT MAP( sclk_i      => sclk_x,
                 sclk_x5_i   => sclk_x5_x,
                 pixel_clk_i => pixel_clk_x,
                 arst_i      => rst_no_lock,
                   
                 red_i       => red_x,
                 green_i     => green_x,
                 blue_i      => blue_x,
                 hsync_i     => hsync_r0_x,
                 vsync_i     => vsync_r0_x,
                 blank_i     => blank_r0_x,
            
                 dvi_clk_p_o => dvi_clk_p_o,
                 dvi_clk_n_o => dvi_clk_n_o,
                 dvi_tx0_p_o => dvi_tx0_p_o,
                 dvi_tx0_n_o => dvi_tx0_n_o,
                 dvi_tx1_p_o => dvi_tx1_p_o,
                 dvi_tx1_n_o => dvi_tx1_n_o,
                 dvi_tx2_p_o => dvi_tx2_p_o,
                 dvi_tx2_n_o => dvi_tx2_n_o);
END ARCHITECTURE dvi_tx_a;
