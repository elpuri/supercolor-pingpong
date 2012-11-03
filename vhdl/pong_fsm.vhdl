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

entity pong_fsm is port ( 
    clk_50 : in  std_logic;
    reset : in std_logic;
    
    any_key_tick : in std_logic;
    vblank_tick : in std_logic;
    
    ingame_reset : out std_logic;
    
    p1_scores, p1_wins, p2_scores, p2_wins : in std_logic;
    
    bitmap_screen_selector : out std_logic_vector(1 downto 0);
    bitmap_screen_active : out std_logic;
    
    enable_controls : out std_logic
    );
end pong_fsm;

architecture behavioral of pong_fsm is

type pong_states is (logo_screen, ingame, oh_shit, p1_won, p2_won);
signal state, state_next : pong_states;
signal delay_counter, delay_counter_next : std_logic_vector(7 downto 0);

begin
    
    process(state, any_key_tick, delay_counter, p1_scores, p2_scores, vblank_tick, p1_wins, p2_wins)
    begin
        state_next <= state;
        ingame_reset <= '0';

        -- Assign default values to avoid latches
        bitmap_screen_selector <= "00";
        bitmap_screen_active <= '1';
        enable_controls <= '0';
        
        if (vblank_tick = '1') then					-- 60hz
            delay_counter_next <= delay_counter + 1;
        else
            delay_counter_next <= delay_counter;
        end if;
        
        case state is
            when logo_screen =>
                bitmap_screen_selector <= "00";
                ingame_reset <= '1';
                if (any_key_tick = '1') then
                    state_next <= ingame;
                end if;
                    
            when ingame =>
                bitmap_screen_active <= '0';
                enable_controls <= '1';
                delay_counter_next <= (others => '0');
                
                -- Check game control signal from the ingame fsm
                if (p1_wins = '1') then
                    state_next <= p1_won;
                elsif (p2_wins = '1') then
                    state_next <= p2_won;
                elsif (p1_scores = '1' or p2_scores = '1') then
                    state_next <= oh_shit;
                end if;
                
            when oh_shit =>
                bitmap_screen_selector <= "01";
        
                if (delay_counter = x"5a") then				-- 1,5s delay
                    state_next <= ingame;
                end if;
                
                
            when p1_won =>
                bitmap_screen_active <= '1';
                bitmap_screen_selector <= "10";
                
                if (delay_counter = x"ff"  or any_key_tick = '1') then				-- 4,25s delay
                    state_next <= logo_screen;
                end if;
                
            when p2_won =>
                bitmap_screen_active <= '1';
                bitmap_screen_selector <= "11";
            
                if (delay_counter = x"ff" or any_key_tick = '1') then				-- 4,25s delay
                    state_next <= logo_screen;
                end if;
                
            when others =>
        end case;
    end process;
    

    process(reset, clk_50)
    begin
        if (reset = '1') then
            state <= logo_screen;
        elsif (clk_50'event and clk_50 = '1') then
            state <= state_next;
            delay_counter <= delay_counter_next;
        end if;
    end process;
    
end behavioral;