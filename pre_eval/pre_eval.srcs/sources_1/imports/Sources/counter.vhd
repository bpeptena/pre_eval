--
-- NAME:
--
--    counter.vhd
--
-- PURPOSE:
--
--    A simple counter with the possibility of resetting the value to 0.
--    It will keep counting until the value is equal to max_x * max_y,
--    where max_x and max_y are resolution sizes:
--        -  max_x for the X axis(640 to 1920)
--        -  max_y for the Y axis(480 to 1080).
--    When the value max_x * max_y is met - the counter will reset to 0.


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY counter IS
    PORT( clk   : IN  std_logic;
          reset : IN  std_logic;
          max_x : IN  integer range 640 to 1920;
          max_y : IN  integer range 480 to 1080;
          count : OUT std_logic_vector(20 downto 0));
END ENTITY counter;

ARCHITECTURE counter_a OF counter IS
BEGIN
    PROCESS (reset, clk)
    VARIABLE cnt: std_logic_vector(20 downto 0) := (OTHERS => '0');
    BEGIN				
        IF (reset = '1') THEN
            -- a manual reset has been requested
            cnt := (OTHERS => '0');
        ELSE
            IF (rising_edge(clk)) THEN
                cnt := cnt + '1';
                IF (cnt = max_x * max_y) THEN
                -- the automatic reset
                    cnt := (OTHERS => '0');
                END IF;
            END IF;
        END IF;	
        count <= cnt;
    END PROCESS;
END ARCHITECTURE counter_a;


