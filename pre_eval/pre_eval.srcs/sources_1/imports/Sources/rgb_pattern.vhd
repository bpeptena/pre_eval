--
-- NAME:
--
--    rgb_pattern.vhd
--
-- PURPOSE:
--
--    File in which the user decides what to draw on screen using
--    red_o, green_o, blue_o.
--    Right now drawing 6 patterns


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.graphics.ALL;

ENTITY rgb_pattern IS
    port( clk_i         : IN  std_logic;
          res_x_i       : IN  integer range 640 to 1920;
          res_y_i       : IN  integer range 480 to 1080;
          res_x_total_i : IN  integer range 800 to 2200;
          res_y_total_i : IN  integer range 525 to 1125;
          hsync_i       : IN  std_logic;
          vsync_i       : IN  std_logic;
          blank_i       : IN  std_logic;
          pixel_pos     : IN  std_logic_vector(20 downto 0); -- 1920*1080 needs minimum 21 bits
          hsync_o       : OUT std_logic;
          vsync_o       : OUT std_logic;
          blank_o       : OUT std_logic;
          red_o         : OUT std_logic_vector(7 downto 0);
          green_o       : OUT std_logic_vector(7 downto 0);
          blue_o        : OUT std_logic_vector(7 downto 0));
END ENTITY rgb_pattern;

ARCHITECTURE rgb_pattern_a OF rgb_pattern IS

    SIGNAL rainbow       : colors(0 to 7) := (x"FF0000", x"FF7F00", x"FFFF00", x"00FF00", x"0000FF", x"4B0082", x"9400D3", x"000000");
    SIGNAL pos_x         : integer range 0 to 2200;
    SIGNAL pos_y         : integer range 0 to 1125;
    SIGNAL pattern_index : integer range 0 to 5; 
    SIGNAL vsync_r       : std_logic := '0';
    
BEGIN
  pos_x <= to_integer(unsigned(pixel_pos)) mod res_x_total_i;
  pos_y <= to_integer(unsigned(pixel_pos)) / res_x_total_i;
  
  -- Update the pattern index
  update: PROCESS(clk_i)
  VARIABLE cnt: integer range 0 to C_TIMER_MAX;
  BEGIN
    IF (rising_edge(clk_i)) THEN
      vsync_r <= vsync_i;
      -- The value of vsync_r will update after the process is done
      -- so we can use this to get moment of the appariton of vsync
      IF (vsync_i = '1' AND vsync_r = '0') THEN
        IF (cnt = C_TIMER_MAX - 1) THEN
          pattern_index <= pattern_index + 1;
          IF (pattern_index = 6) THEN
              pattern_index <= 0;
          END IF;
          cnt := 0;
        ELSE
          cnt := cnt + 1;
        END IF;
      END IF;
    END IF;
  END PROCESS;

  -- Drawing process
  draw: PROCESS(clk_i)
  VARIABLE index: integer range 0 to 7 := 0;
  VARIABLE funct_colors: std_logic_vector(23 downto 0); 
  BEGIN
      IF (rising_edge(clk_i)) THEN
          hsync_o <= hsync_i;
          vsync_o <= vsync_i;
      
            -- Active time - drawing time 
            IF (blank_i = '0') THEN
                  IF (pattern_index = 0) THEN
                      funct_colors := rainbow(0); -- just background color
                  ELSIF (pattern_index = 1) THEN
                      index := horizontal_lines(pos_y, res_y_i);
                      funct_colors := rainbow(index);
                  ELSIF (pattern_index = 2) THEN
                      index := vertical_lines(pos_x, res_x_i);
                      funct_colors := rainbow(index);
                  ELSIF (pattern_index = 3) THEN
                      funct_colors := pixel(pos_x, pos_y, 320, 240, rainbow(2), rainbow(6));
                  ELSIF (pattern_index = 4) THEN
                      funct_colors := square(pos_x, pos_y, 190, 270, 100, rainbow(2), rainbow(4));
                  ELSIF (pattern_index = 5) THEN
                      funct_colors := rectangle(pos_x, pos_y, 220, 190, 200, 100, rainbow(4), rainbow(1));
                  END IF;
              
              red_o   <= funct_colors(23 downto 16);
              green_o <= funct_colors(15 downto 8);
              blue_o  <= funct_colors(7 downto 0); 
              blank_o <= '0';
          ELSE
              red_o   <= (OTHERS => '0');
              green_o <= (OTHERS => '0');
              blue_o  <= (OTHERS => '0');   
              blank_o <= '1';
          END IF;
      END IF;
  END PROCESS;
END ARCHITECTURE rgb_pattern_a;