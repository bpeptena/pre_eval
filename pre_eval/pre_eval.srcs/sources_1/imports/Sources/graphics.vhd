--
-- NAME:
--
--    graphics.vhd
--
-- PURPOSE:
--
--    A package containing types, constants and functions used for 
--    rendering computer graphics.
--    The type res_attr is used for easy storage of the video timing attributes.
--    Each of the 3 resolutions gets one constant of the type res_attr.
--    Available functions:
--        - vertical lines
--        - horizontal lines
--        - pixel
--        - square
--        - rectangle


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

PACKAGE graphics IS
    TYPE colors IS ARRAY (natural range <>) OF std_logic_vector(23 downto 0);
    CONSTANT C_TIMER_MAX : integer := 120;         
    -- video timing structure                             
    TYPE res_attr IS RECORD
        C_RES_X   : integer range 640 to 1920;
        C_RES_Y   : integer range 480 to 1080;
        C_HFRONT  : integer range  16 to 110; -- Front porch HSYNC
        C_HSYNC   : integer range  40 to 96;  -- Horizontal sync pulse
        C_HBACK   : integer range  48 to 220; -- Back porch HSYNC
        C_VFRONT  : integer range   4 to 10;  -- Front porch VSYNC
        C_VSYNC   : integer range   2 to 5;   -- Vertical sync pulse
        C_VBACK   : integer range  20 to 36;  -- Back porch VSYNC
        C_HBLANK  : integer range 104 to 426; -- total blanking time for HSYNC
        C_VBLANK  : integer range  26 to 51;  -- total blanking time for VSYNC
        C_TOTAL_X : integer range 800 to 2200;
        C_TOTAL_Y : integer range 525 to 1125;
    END RECORD res_attr;
    
    -- Video timing attributes for 1920x1080
    CONSTANT res_attr_1080: res_attr := ( C_RES_X   => 1920,
                                          C_RES_Y   => 1080,
                                          C_HFRONT  => 88,
                                          C_HSYNC   => 44,
                                          C_HBACK   => 148,
                                          C_VFRONT  => 4,
                                          C_VSYNC   => 5,
                                          C_VBACK   => 36,
                                          C_HBLANK  => 280,
                                          C_VBLANK  => 45,
                                          C_TOTAL_X => 2200,
                                          C_TOTAL_Y => 1125);
    
    -- Video timing attributes for 1280x720                                        
    CONSTANT res_attr_720: res_attr := ( C_RES_X   => 1280,
                                         C_RES_Y   => 720,
                                         C_HFRONT  => 110,
                                         C_HSYNC   => 40,
                                         C_HBACK   => 220,
                                         C_VFRONT  => 5,
                                         C_VSYNC   => 5,
                                         C_VBACK   => 20,
                                         C_HBLANK  => 370,
                                         C_VBLANK  => 30,
                                         C_TOTAL_X => 1650,
                                         C_TOTAL_Y => 750);
   
   -- Video timing attributes for 640x480
    CONSTANT res_attr_480: res_attr := ( C_RES_X   => 640,
                                         C_RES_Y   => 480,
                                         C_HFRONT  => 16,
                                         C_HSYNC   => 96,
                                         C_HBACK   => 48,
                                         C_VFRONT  => 10,
                                         C_VSYNC   => 2,
                                         C_VBACK   => 33,
                                         C_HBLANK  => 160,
                                         C_VBLANK  => 45,
                                         C_TOTAL_X => 800,
                                         C_TOTAL_Y => 525);   
                                         
                                         
FUNCTION vertical_lines( pos_x: integer range   0 to 2200;
                         res_x: integer range 640 to 1920)
                         RETURN integer;  
                         
FUNCTION horizontal_lines( pos_y: integer range   0 to 1125;
                           res_y: integer range 480 to 1080)
                           RETURN integer;  

FUNCTION pixel( pos_x      : integer range 0 to 2200;
                pos_y      : integer range 0 to 1125;
                pos_x_pix  : integer range 0 to 1920;
                pos_y_pix  : integer range 0 to 1080;
                color_pix  : std_logic_vector(23 downto 0); 
                color_back : std_logic_vector(23 downto 0))
                RETURN std_logic_vector;

FUNCTION square( pos_x        : integer range 0 to 2200;
                 pos_y        : integer range 0 to 1125;
                 pos_x_square : integer range 0 to 1920;
                 pos_y_square : integer range 0 to 1080;
                 dimension    : integer range 0 to 1080;
                 color_square : std_logic_vector(23 downto 0);
                 color_back   : std_logic_vector(23 downto 0))
                 RETURN std_logic_vector;

FUNCTION rectangle( pos_x      : integer range 0 to 2200;
                    pos_y      : integer range 0 to 1125;
                    pos_x_rect : integer range 0 to 1920;
                    pos_y_rect : integer range 0 to 1080;
                    length     : integer range 0 to 1920;
                    width      : integer range 0 to 1080; 
                    color_rect : std_logic_vector(23 downto 0);
                    color_back : std_logic_vector(23 downto 0))
                    RETURN std_logic_vector;
END PACKAGE graphics;



PACKAGE BODY graphics IS

FUNCTION vertical_lines( pos_x: integer range   0 to 2200;
                         res_x: integer range 640 to 1920)
                         RETURN integer IS
VARIABLE index: integer range  0 to 7   := 0;
VARIABLE bs   : integer range 80 to 240 := res_x / 8; -- block size
BEGIN
    IF (pos_x >= bs * 0 AND pos_x <= bs * 1 - 1) THEN
        index := 0;
    ELSIF (pos_x >= bs * 1 AND pos_x <= bs * 2 - 1) THEN
        index := 1;
    ELSIF (pos_x >= bs * 2 AND pos_x <= bs * 3 - 1) THEN
        index := 2;
    ELSIF (pos_x >= bs * 3 AND pos_x <= bs * 4 - 1) THEN
        index := 3;
    ELSIF (pos_x >= bs * 4 AND pos_x <= bs * 5 - 1) THEN
        index := 4;
    ELSIF (pos_x >= bs * 5 AND pos_x <= bs * 6 - 1) THEN
        index := 5;
    ELSIF (pos_x >= bs * 6 AND pos_x <= bs * 7 - 1) THEN
        index := 6;
    ELSE
        index := 7;  
    END IF;
    RETURN index;
END FUNCTION vertical_lines;


FUNCTION horizontal_lines( pos_y: integer range   0 to 1125;
                           res_y: integer range 480 to 1080)
                           RETURN integer IS
VARIABLE index: integer range  0 to 5   := 0;
VARIABLE bs   : integer range 80 to 240 := res_y / 6; -- block size
BEGIN
    IF (pos_y >= bs * 0 AND pos_y <= bs * 1 - 1) THEN
        index := 0;
    ELSIF (pos_y >= bs * 1 AND pos_y <= bs * 2 - 1) THEN
        index := 1;
    ELSIF (pos_y >= bs * 2 AND pos_y <= bs * 3 - 1) THEN
        index := 2;
    ELSIF (pos_y >= bs * 3 AND pos_y <= bs * 4 - 1) THEN
        index := 3;
    ELSIF (pos_y >= bs * 4 AND pos_y <= bs * 5 - 1) THEN
        index := 4;
    ELSIF (pos_y >= bs * 5 AND pos_y <= bs * 6 - 1) THEN
        index := 5;                       
    ELSE index := 7;    
    END IF;
    RETURN index;
END FUNCTION horizontal_lines;


FUNCTION pixel( pos_x      : integer range 0 to 2200;
                pos_y      : integer range 0 to 1125;
                pos_x_pix  : integer range 0 to 1920;
                pos_y_pix  : integer range 0 to 1080;
                color_pix  : std_logic_vector(23 downto 0); 
                color_back : std_logic_vector(23 downto 0))
                RETURN std_logic_vector IS
VARIABLE rgb: std_logic_vector(23 downto 0);
BEGIN
    IF (pos_x = pos_x_pix AND pos_y = pos_y_pix) THEN
        rgb := color_pix;
    ELSE
        rgb := color_back;
    END IF;
    RETURN rgb;
END FUNCTION pixel;


FUNCTION square( pos_x        : integer range 0 to 2200;
                 pos_y        : integer range 0 to 1125;
                 pos_x_square : integer range 0 to 1920;
                 pos_y_square : integer range 0 to 1080;
                 dimension    : integer range 0 to 1080;
                 color_square : std_logic_vector(23 downto 0);
                 color_back   : std_logic_vector(23 downto 0))
                 RETURN std_logic_vector IS
VARIABLE rgb: std_logic_vector(23 downto 0); 
BEGIN
    IF ((pos_x >= pos_x_square AND pos_x <= pos_x_square + dimension) AND
        (pos_y >= pos_y_square AND pos_y <= pos_y_square + dimension)) THEN    
        rgb := color_square;
    ELSE
        rgb := color_back;
    END IF;
    RETURN rgb;
END FUNCTION square;


FUNCTION rectangle( pos_x      : integer range 0 to 2200;
                    pos_y      : integer range 0 to 1125;
                    pos_x_rect : integer range 0 to 1920;
                    pos_y_rect : integer range 0 to 1080;
                    length     : integer range 0 to 1920;
                    width      : integer range 0 to 1080; 
                    color_rect : std_logic_vector(23 downto 0);
                    color_back : std_logic_vector(23 downto 0))
                    RETURN std_logic_vector IS
VARIABLE rgb: std_logic_vector(23 downto 0); 
BEGIN
    IF ((pos_x >= pos_x_rect AND pos_x <= pos_x_rect + length) AND
        (pos_y >= pos_y_rect AND pos_y <= pos_y_rect + width)) THEN    
        rgb := color_rect;
    ELSE
        rgb := color_back;
    END IF;
    RETURN rgb;
END FUNCTION rectangle;

END PACKAGE BODY graphics;
