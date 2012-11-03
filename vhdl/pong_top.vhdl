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

-- This top is for the Terasic DE2 board
entity pong_top is port ( 
    clk_50 : in  std_logic;
    
    btn : in std_logic_vector(3 downto 3);
    
    -- VGA DAC and sync signals
    vga_hs : out std_logic;
    vga_vs : out std_logic;
    vga_r : out std_logic_vector(9 downto 0);
    vga_g : out std_logic_vector(9 downto 0);
    vga_b : out std_logic_vector(9 downto 0);
    vga_clk : out std_logic;
    vga_blank : out std_logic;
    vga_sync : out std_logic;
    
    -- PS2 keyboard port signals
    ps2_clk : in std_logic;
    ps2_dat : in std_logic
    
    );
end pong_top;

architecture behavioral of pong_top is
signal reset : std_logic;

-- VGA related signals
signal vga_x, vga_y : std_logic_vector(9 downto 0);				-- beam position
signal vga_visible : std_logic;									-- beam in visible region
signal vblank_tick : std_logic;									-- asserted for one clk_50 cycle ~60Hz
signal pixel_ena : std_logic;									-- enabled once per pixel

-- Main FSM output signals
signal ingame_reset : std_logic;								-- resets the gameplay FSM
signal bitmap_screen_selector : std_logic_vector(1 downto 0);	-- selects the bitmap displayed by the bitmap screen generator

-- Bitmap screen generator rgb signals
signal bmp_r, bmp_g, bmp_b : std_logic_vector(1 downto 0);

-- Color signal from different screens and the multiplexed signal
signal ingame_color : std_logic_vector(2 downto 0);
signal bitmap_color : std_logic_vector(2 downto 0);
signal active_screen_color : std_logic_vector(2 downto 0);

signal bitmap_screen_active : std_logic;

-- Rgb signals from the palette LUT
signal r, g, b : std_logic_vector(7 downto 0);

-- Keyboard control signals and the gated versions of them
signal p1_up, p1_down, p2_up, p2_down, hit, any_key_tick : std_logic;
signal gated_p1_up, gated_p1_down, gated_p2_up, gated_p2_down, gated_hit : std_logic;
signal enable_controls : std_logic;

signal p1_scores, p1_wins, p2_scores, p2_wins : std_logic;


begin
    reset <= not btn(3);
    
    vga_blank <= vga_visible;
    vga_sync <= '1';
    vga_clk <= clk_50;

    -- Enable/disable controls to the ingame screen according to a control signal from the master fsm
    -- This disables the controls during bitmap screens to avoid accidental movement of the paddles and
    -- hitting the ball
    gated_p1_up <= p1_up and enable_controls;
    gated_p1_down <= p1_down and enable_controls;
    gated_p2_up <= p2_up and enable_controls;
    gated_p2_down <= p2_down and enable_controls;
    gated_hit <= hit and enable_controls;

    controls : entity work.keyboard_controller port map (
        clk_50 => clk_50,
        reset => reset,
        ps2_clk => ps2_clk,
        ps2_data => ps2_dat,
        p1_down => p1_down,
        p1_up => p1_up,
        p2_down => p2_down,
        p2_up => p2_up,
        any_key_tick => any_key_tick,
        hit => hit );
        
    vga_sync_generator : entity work.vga_sync_generator port map (
        clk_50 => clk_50,
        hsync => vga_hs,
        vsync => vga_vs,
        visible => vga_visible,
        x => vga_x,
        y => vga_y,
        vblank_tick => vblank_tick,
        pixel_ena => pixel_ena );

    ingame_screen_generator : entity work.ingame_screen port map (
        clk_50 => clk_50,
        reset => ingame_reset,
        vblank_tick => vblank_tick,
        col => ingame_color,
        p1_down => gated_p1_down,
        p1_up => gated_p1_up,
        p2_down => gated_p2_down,
        p2_up => gated_p2_up,
        hit => gated_hit,
        first_to_serve => '0',
        p1_scores => p1_scores,
        p2_scores => p2_scores,
        p1_wins => p1_wins,
        p2_wins => p2_wins,
        x => vga_x,
        y => vga_y
        );
        

    bitmap_screen_generator : entity work.bitmap_screen port map (
        clk_50 => clk_50,
        reset => reset,
        selector => bitmap_screen_selector,
        x => vga_x,
        y => vga_y,
        col => bitmap_color,
        pixel_ena => pixel_ena,
        vblank_tick => vblank_tick );


    active_screen_color <= bitmap_color when bitmap_screen_active = '1' else ingame_color;

    palette_lut : entity work.palette_lut port map (
        col => active_screen_color,
        r => r,
        g => g,
        b => b );
        
    vga_r <= r & "00";
    vga_g <= g & "00";
    vga_b <= b & "00";
    
    
    pong_fsm : entity work.pong_fsm port map (
        clk_50 => clk_50,
        reset => reset,
        vblank_tick => vblank_tick,
        bitmap_screen_selector => bitmap_screen_selector,
        bitmap_screen_active => bitmap_screen_active,
        any_key_tick => any_key_tick,
        ingame_reset => ingame_reset,
        p1_scores => p1_scores,
        p2_scores => p2_scores,
        p1_wins => p1_wins,
        p2_wins => p2_wins,
        enable_controls => enable_controls );

end behavioral;