--
-- NAME:
--
--    rgb_timing.vhd
--
-- PURPOSE:
--
--    Generating the VGA specific signals (hsync_o, vsync_o, blank_o)
--    and providing the appropiate attributes of the chosen resolution:
--        - res_x, res_y (resolution for x and y axis for the active period)
--        - res_x_total, res_y_total (resolution for x and y axis for the inactive period)
--    Active period => the pixels are drawn on the screen
--    Inactive period => skip drawing pixels until active again


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.graphics.ALL;

ENTITY rgb_timing IS
  PORT( clk_i       : IN  std_logic;
        sw          : IN std_logic_vector(1 downto 0); -- switches used for changing the resolution
        pix_reset_o : OUT std_logic;
        hsync_o     : OUT std_logic;
        vsync_o     : OUT std_logic;
        blank_o     : OUT std_logic; -- inactive period 
        res_x       : OUT integer range 640 to 1920; -- x axis for active period
        res_y       : OUT integer range 480 to 1080; -- y axis for active period
        res_x_total : OUT integer range 800 to 2200; -- x axis for inactive period
        res_y_total : OUT integer range 525 to 1125);-- y axis for inactive period
END ENTITY rgb_timing;

ARCHITECTURE rgb_timing_a OF rgb_timing IS

  SIGNAL res   : res_attr;
  SIGNAL x     : unsigned(11 downto 0) := (OTHERS => '0');
  SIGNAL y     : unsigned(11 downto 0) := (OTHERS => '0');

BEGIN

  -- Choosing the right resolution when the switches change their position
  resolution: PROCESS(sw)
  BEGIN
    CASE sw IS
        WHEN "00" => res <= res_attr_480;
        WHEN "01" => res <= res_attr_720;
        WHEN "10" => res <= res_attr_1080;
        WHEN OTHERS => res <= res_attr_480;
    END CASE;
  END PROCESS;
  
  timing : PROCESS(clk_i, sw)
  BEGIN
    IF rising_edge(clk_i) THEN
        IF (x = res.C_RES_X - 1) THEN
            -- Entered the inactive period
            blank_o <= '1';
        ELSIF ((x = res.C_TOTAL_X - 1) AND ((y < res.C_RES_Y - 1) or (y = res.C_TOTAL_Y - 1))) THEN
            -- Active period
            blank_o <= '0';            
        END IF;
      
        IF (x = res.C_RES_X + res.C_HFRONT - 1) THEN
            -- Display time is over and the front porch is over
            -- HSYNC _______________      ______
            --                      |____|
            --      Display | FRONT |SYNC| BACK
            hsync_o <= '1';
        ELSIF (x = res.C_RES_X + res.C_HFRONT + res.C_HSYNC - 1) THEN
            -- Display time, front porch and sync pulse time is over
            hsync_o <= '0';
        END IF;

        IF (x = res.C_TOTAL_X - 1) THEN
            -- End of display time and blanking time. Reset.
            x <= (OTHERS => '0');
            -- Finished drawing one row, next row.
            IF (y = res.C_RES_Y + res.C_VFRONT - 1) THEN
                 -- Display time is over and the front porch is over
                 -- VSYNC _______________      ______
                 --                      |____|
                 --      Display | FRONT |SYNC| BACK
                vsync_o  <= '1';
                pix_reset_o <= '1';
            ELSIF (y = res.C_RES_Y + res.C_VFRONT + res.C_VSYNC - 1) THEN
               -- Display time, front porch and sync pulse time is over
                vsync_o  <= '0';
                pix_reset_o <= '0';  
            END IF;
            IF (y = res.C_TOTAL_Y - 1) THEN
            -- End of display time and blanking time. Reset.
                y <= (OTHERS => '0');
            ELSE
                y <= y + 1;
            END IF;
        ELSE
            x <= x + 1;
        END IF;    
    END IF;
  END PROCESS;

  -- Setting the values of the chosen resolution
  res_x       <= res.C_RES_X;    
  res_y       <= res.C_RES_Y;
  res_x_total <= res.C_TOTAL_X;
  res_y_total <= res.C_TOTAL_Y;
END ARCHITECTURE rgb_timing_a;