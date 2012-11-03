-- Copyright (c) 2012, Juha Turunen (turunen@iki.fi)
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met: 
--
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer. 
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution. 
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity bitmap_screen is port ( 
    clk_50 : in  std_logic;
    reset : in std_logic;
    x : in std_logic_vector(9 downto 0);
    y : in std_logic_vector(9 downto 0);
    selector : in std_logic_vector(1 downto 0);
    pixel_ena : in std_logic;
    vblank_tick : in std_logic;
    col : out std_logic_vector(2 downto 0)
    );
end bitmap_screen;

architecture behavioral of bitmap_screen is

signal rom_address, rom_address_next : std_logic_vector(15 downto 0);
signal rom_data : std_logic_vector(7 downto 0);

signal line_address, line_address_next : std_logic_vector(15 downto 0);
signal base_address : std_logic_vector(15 downto 0);

-- Logo screen blink hack
signal blink_counter : std_logic_vector(5 downto 0);
signal in_blink_area : std_logic;

signal color : std_logic_vector(2 downto 0);

begin
    
    -- Base address for the 4 different images
    base_address <= (others=>'0') when selector = "00" else
                    std_logic_vector(to_unsigned(9600, 16)) when selector = "01" else
                    std_logic_vector(to_unsigned(19200, 16)) when selector = "10" else
                    std_logic_vector(to_unsigned(28800, 16));

    
    process(clk_50, pixel_ena, reset)
    begin
        if (reset = '1') then
            rom_address <= (others => '0');
        elsif (clk_50'event and clk_50 = '1') then
            if (pixel_ena = '1') then
                rom_address <= rom_address_next;
                line_address <= line_address_next;
            end if;
            
            if (vblank_tick = '1') then
                blink_counter <= blink_counter + 1;
            end if;
        end if;
    end process;
    
    -- Wasting a bit per pixel here but the bin2hex tool wants bytes so... :)
    color <= rom_data(6 downto 4) when x(2) = '0' else rom_data(2 downto 0);

    line_address_next <= base_address when x = 0 and y > 480 else
                         line_address + 80 when x = 640 and y(1 downto 0) = "11" else
                         line_address;
                         
    rom_address_next <= line_address_next when x > 640 else
                        rom_address + 1 when x(2 downto 0) = "111" else
                        rom_address;

    logo : entity work.pong_graphics_rom port map (
        address => rom_address,
        clock => clk_50,
        q => rom_data );
        
    -- A hack to blink the area of the logo screen that has the text "Press any key to play"
    in_blink_area <= '1' when x > 230 and x < 584 and y > 420 and y < 454 else '0';
    process (in_blink_area, color, blink_counter, selector)
    begin
        if (in_blink_area = '1' and selector = "00" and blink_counter(5) = '0') then
            col <= "010";		-- force the whole area to green
        else
            col <= color;
        end if;
    end process;


end behavioral;