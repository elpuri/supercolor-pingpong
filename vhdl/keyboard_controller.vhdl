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

entity keyboard_controller is port ( 
    clk_50 : in std_logic;
    reset : in std_logic;
    ps2_clk : in std_logic;
    ps2_data : in std_logic;
    
    p1_up, p1_down, p2_up, p2_down, hit : out std_logic;
    any_key_tick : out std_logic

    );
end keyboard_controller;
    
    
architecture behavioral of keyboard_controller is

signal rx_data : std_logic_vector(7 downto 0);		-- scan code data received from the keyboard
signal rx_tick : std_logic;							-- one clock length pulse when a new byte is received

-- registers for holding the state of keys and the input signals for the registers
-- hitting the ball is not an continuous action so no register is needed
signal p1_up_reg, p1_down_reg, p2_up_reg, p2_down_reg, 		
       p1_up_next, p1_down_next, p2_up_next, p2_down_next : std_logic;	 

-- Registers and their next state signals for internal state
signal extended_code_received, break_code_received, 
       extended_code_received_next, break_code_received_next : std_logic;	
    
-- Scan code constants
constant extended_code : std_logic_vector(7 downto 0) := x"e0";
constant break_code : std_logic_vector(7 downto 0) := x"f0";
constant hit_key_code : std_logic_vector(7 downto 0) := x"29";			-- space (not extended code)
constant hit_key_code_extended : std_logic := '0';						
constant p1_up_key_code : std_logic_vector(7 downto 0) := x"1c";   		-- a (not extended code)
constant p1_up_key_code_extended : std_logic := '0';
constant p1_down_key_code : std_logic_vector(7 downto 0) := x"1a";		-- z (not extended code)
constant p1_down_key_code_extended : std_logic := '0';
constant p2_up_key_code : std_logic_vector(7 downto 0) := x"75";		-- up arrow (extended code)
constant p2_up_key_code_extended : std_logic := '1';
constant p2_down_key_code : std_logic_vector(7 downto 0) := x"72";		-- down arrow (extended code)
constant p2_down_key_code_extended : std_logic := '1';

begin
    -- Map the registers to outputs
    p1_up <= p1_up_reg;
    p1_down <= p1_down_reg;
    p2_up <= p2_up_reg;
    p2_down <= p2_down_reg;
    
    -- Reset logic and updating of the state register on rising clock
    process(clk_50, reset)
    begin
        if (reset='1') then
            extended_code_received <= '0';
            break_code_received <= '0';
            p1_up_reg <= '0';
            p1_down_reg <= '0';
            p2_up_reg <= '0';
            p2_down_reg <= '0';
        elsif (clk_50'event and clk_50 = '1') then
            p1_up_reg <= p1_up_next;
            p1_down_reg <= p1_down_next;
            p2_up_reg <= p2_up_next;
            p2_down_reg <= p2_down_next;
            extended_code_received <= extended_code_received_next;
            break_code_received <= break_code_received_next;
        end if;
    end process;
    
    -- Combinational logic for producing the next state and key register inputs and mealy outputs
    process (rx_tick, rx_data, p1_up_reg, p1_down_reg, p2_up_reg, p2_down_reg, extended_code_received,
             break_code_received)
    begin
        -- Maintain the state of registers unless specifically assigned in the case statement
        p1_up_next <= p1_up_reg;
        p1_down_next <= p1_down_reg;
        p2_up_next <= p2_up_reg;
        p2_down_next <= p2_down_reg;	
        extended_code_received_next <= extended_code_received;
        break_code_received_next <= break_code_received;
        
        -- Other defaults
        any_key_tick <= '0';
        hit <= '0';			
        
        if (rx_tick = '1') then
            if (rx_data = extended_code) then
                extended_code_received_next <= '1';
            elsif (rx_data = break_code) then
                break_code_received_next <= '1';
            else
                -- This is a real key code so reset the flip flops so that they don't affect the next 
                -- received key code. 
                extended_code_received_next <= '0';		
                break_code_received_next <= '0';
                
                if (break_code_received = '0' and rx_data /= extended_code and rx_data /= break_code) then
                    any_key_tick <= '1';
                end if;
                
                case rx_data is
                    when p1_up_key_code =>
                        if (extended_code_received = p1_up_key_code_extended) then
                            -- set if this was a make code, clear if this was a break code
                            p1_up_next <= not break_code_received;		
                        end if;
                        
                    when p1_down_key_code =>
                        if (extended_code_received = p1_down_key_code_extended) then
                            -- set if this was a make code, clear if this was a break code
                            p1_down_next <= not break_code_received;		
                        end if;
                        
                    when p2_up_key_code =>
                        if (extended_code_received = p2_up_key_code_extended) then
                            -- set if this was a make code, clear if this was a break code
                            p2_up_next <= not break_code_received;		
                        end if;
                        
                    when p2_down_key_code =>
                        if (extended_code_received = p2_down_key_code_extended) then
                            -- set if this was a make code, clear if this was a break code
                            p2_down_next <= not break_code_received;		
                        end if;		
                        
                    when hit_key_code =>
                        if (extended_code_received = hit_key_code_extended) then
                            -- set if this was a make code, clear if this was a break code
                            hit <= not break_code_received;		
                        end if;	
                    
                    when others =>
                        
                        
                end case;	
            end if;
        end if;
    
    end process;
    
    -- PS/2 receiver unit
    ps2_rx : entity work.ps2rx port map(
        clk => clk_50,
        ps2clk => ps2_clk,
        ps2data => ps2_data,
        data => rx_data,
        data_tick => rx_tick );
        
    
end behavioral;