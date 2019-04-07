--
-- NAME:
--
--    dvi_tx_clkgen.vhd
--
-- PURPOSE:
--
--    Generating the pixel clock (25MHz/75Mhz/150MHz), where the adequate 
--    frequency is determined by res_y_i (480 to 1080).
--    Providing the necessary signals for the DVI standard (sclk_o, sclk_x5_o)
--    and the other signal used for the synchronization of the reset (locked_o).


LIBRARY IEEE;
LIBRARY UNISIM;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE UNISIM.VCOMPONENTS.ALL;

ENTITY dvi_tx_clkgen IS
    PORT( clk_i       : in  std_logic;   -- 125 MHz reference 
          res_y_i     : IN  integer range 480 to 1080; -- current resolution
          arst_i      : in  std_logic;   -- asynchronous reset (from board pin)
          locked_o    : out std_logic;   -- synchronous to reference clock
          pixel_clk_o : out std_logic;   -- pixel clock
          sclk_o      : out std_logic;   -- serdes clock (framing clock)
          sclk_x5_o   : out std_logic);  -- serdes clock x5 (bit clock)
END ENTITY dvi_tx_clkgen;

ARCHITECTURE dvi_tx_clkgen_a OF dvi_tx_clkgen IS

  SIGNAL refrst_x           : std_logic;
  SIGNAL mmcm_locked_x      : std_logic;
  SIGNAL mmcm_locked_sync_x : std_logic;
  SIGNAL mmcm_rst_r         : std_logic;
  SIGNAL bufr_rst_r         : std_logic;
  SIGNAL pixel_clk_x        : std_logic;
  SIGNAL sclk_x5_x          : std_logic;

  TYPE fsm_mmcm_rst_t is (WAIT_LOCK, LOCKED);
  SIGNAL state_mmcm_rst : fsm_mmcm_rst_t := WAIT_LOCK;

BEGIN
  -- The reset bridge will make sure we can use the async reset
  -- safely in the reference clock domain
  refrst_inst : ENTITY work.rst_bridge
    PORT MAP( arst_in  => arst_i,
              sclk_in  => clk_i,
              srst_out => refrst_x);

  -- sync MMCM lock signal to the reference clock domain
  sync_mmcm_locked_inst : ENTITY work.sync_dff
    PORT MAP( async_in => mmcm_locked_x,
              sclk_in  => clk_i,
              sync_out => mmcm_locked_sync_x);

  -- Need to generate an MMCM reset pulse >= 5 ns (Xilinx DS191).
  -- We can use the reference clock to create the pulse. The fsm
  -- below will only work is the reference clk frequency is < 200MHz.
  -- The BUFR needs to be reset any time the MMCM acquires lock.
  fsm_mmcm_rst : PROCESS(refrst_x, clk_i)
  BEGIN
    IF (refrst_x = '1') THEN
        state_mmcm_rst <= WAIT_LOCK;
        mmcm_rst_r <= '1';
        bufr_rst_r <= '0';
    ELSIF rising_edge(clk_i) THEN
        mmcm_rst_r <= '0';
        bufr_rst_r <= '0';
        CASE state_mmcm_rst IS
            WHEN WAIT_LOCK =>
                IF (mmcm_locked_sync_x = '1') THEN
                    bufr_rst_r     <= '1';
                    state_mmcm_rst <= LOCKED;
                END IF;
            WHEN LOCKED =>
                IF (mmcm_locked_sync_x = '0') THEN
                    mmcm_rst_r     <= '1';
                    state_mmcm_rst <= WAIT_LOCK;
                END IF;
            END CASE;
    END IF;
  END PROCESS;

  -- Choosing the pixel clock after generating the three
  -- clock signals (25MHz/75Mhz/150MHz) with the help of
  -- a MMCME2_ADV primitive
  mmcme2_choose_inst: ENTITY work.mmcme2_choose
    PORT MAP( clk_i         => clk_i ,
              res_y_i       => res_y_i,
              mmcm_rst      => mmcm_rst_r,
              sclk_x5_o     => sclk_x5_x,
              pixel_clk_o   => pixel_clk_x,
              mmcm_locked_o => mmcm_locked_x);

  bufio_inst : BUFIO
    PORT MAP( O => sclk_x5_o, 
              I => sclk_x5_x);

  -- If the clock to the BUFR is stopped, then a reset (CLR) 
  -- must be applied after the clock returns (see Xilinx UG472)
  bufr_inst : BUFR
    GENERIC MAP( BUFR_DIVIDE => "5",
                 SIM_DEVICE  => "7SERIES")
    PORT MAP( O   => sclk_o,
              CE  => '1',
              CLR => bufr_rst_r,
              I   => sclk_x5_x);

  -- The tools will issue a warning that pixel clock is not 
  -- phase aligned to sclk_x, sclk_x5_x. We can safely
  -- ignore it as we don't care about the phase relationship
  -- of the pixel clock to the sampling clocks.
  bufg_inst : BUFG
    PORT MAP( O => pixel_clk_o,
              I => pixel_clk_x);

  locked_p : PROCESS(mmcm_locked_x, clk_i)
  BEGIN
    IF (mmcm_locked_x = '0') THEN
        locked_o <= '0';
    ELSIF rising_edge(clk_i) THEN
        -- Raise locked only after BUFR has been reset
        IF (bufr_rst_r = '1') THEN
            locked_o <= '1';
        END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE dvi_tx_clkgen_a;