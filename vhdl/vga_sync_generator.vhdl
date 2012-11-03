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

entity vga_sync_generator is port ( 
    clk_50 : in std_logic;
    hsync : out std_logic;
    vsync : out std_logic;
    x, y : out std_logic_vector(9 downto 0);
    visible : out std_logic;
    pixel_ena : out std_logic;
    vblank_tick : out std_logic
    );
    
end vga_sync_generator;

architecture Behavioral of vga_sync_generator is


constant vertical_visible : integer := 480;
constant vertical_front_porch : integer := 10;
constant vertical_sync : integer := 2;
constant vertical_back_porch : integer := 33;

constant vertical_length : integer := 
            vertical_visible + vertical_front_porch +
            vertical_sync + vertical_back_porch;

constant horizontal_visible : integer := 640 * 2;
constant horizontal_front_porch : integer := 16 * 2;
constant horizontal_sync : integer := 96 * 2;
constant horizontal_back_porch : integer := 48 * 2;

constant horizontal_length : integer := 
            horizontal_visible + horizontal_front_porch +
            horizontal_sync + horizontal_back_porch;

signal hcounter, hcounter_next : std_logic_vector(10 downto 0);
signal vcounter, vcounter_next : std_logic_vector(9 downto 0);

-- Sync signals are registered to avoid glitches
signal hsync_reg, hsync_next : std_logic;
signal vsync_reg, vsync_next : std_logic;

signal in_h_overscan, in_v_overscan : std_logic;

begin
    -- The clock is about twice the speed of a standard VGA pixel clock, so the beam x position is doubled.
    -- Drop the last bit to divide it by two.
    x <= hcounter(10 downto 1);		
    y <= vcounter;
    pixel_ena <= not hcounter(0);

    hsync <= hsync_reg;
    vsync <= vsync_reg;
    
    process(clk_50)
    begin
        if (clk_50'event and clk_50 = '1') then
            -- update every 20ns
            hcounter <= hcounter_next;
            vcounter <= vcounter_next;
            hsync_reg <= hsync_next;
            vsync_reg <= vsync_next;
        end if;
    end process;
    
    -- Logic for determining visible region
    in_h_overscan <= '1' when hcounter >= horizontal_visible else '0';
    in_v_overscan <= '1' when vcounter >= vertical_visible else '0';
    visible <= not (in_h_overscan or in_v_overscan);
    
    -- Counter logic
    hcounter_next <= (others => '0') when hcounter = horizontal_length - 1 else hcounter + 1;
    
    process(hcounter_next, vcounter)
    begin
        vcounter_next <= vcounter;		-- default
        if (hcounter_next = 0) then
            vcounter_next <= vcounter + 1;
            if (vcounter = vertical_length - 1) then
                vcounter_next <= (others => '0');
            end if;
        end if;
    end process;
        
    -- Sync pulse logic
    hsync_next <= '0' when (hcounter >= horizontal_visible + horizontal_front_porch - 1 and
                                    hcounter < horizontal_length - horizontal_back_porch) else '1';
    
    vsync_next <= '0' when (vcounter >= vertical_visible + vertical_front_porch - 1 and
                                   vcounter < vertical_length - vertical_back_porch) else '1';
        
    vblank_tick <= '1' when vcounter = vertical_visible and hcounter = 0 else '0';
    
end Behavioral;

