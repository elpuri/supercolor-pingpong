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

entity palette_lut is port ( 
    col : in std_logic_vector(2 downto 0);
    r, g, b : out std_logic_vector(7 downto 0)
    );
end palette_lut;

architecture behavioral of palette_lut is
begin
    process(col)
    begin
        case col is
            when "000" =>
                r <= x"00";
                g <= x"00";
                b <= x"00";
            
            when "001" =>
                r <= x"00";
                g <= x"01";
                b <= x"af";
                
            when "010" =>
                r <= x"00";
                g <= x"8f";
                b <= x"00";
                
            when "011" =>
                r <= x"d3";
                g <= x"d3";
                b <= x"d3";
                
            when "100" =>
                r <= x"ff";
                g <= x"00";
                b <= x"00";
                
            when "101" =>
                r <= x"ff";
                g <= x"90";
                b <= x"00";
                
            when "110" =>
                r <= x"e2";
                g <= x"e2";
                b <= x"3a";
                
            when "111" =>
                r <= x"ff";
                g <= x"ff";
                b <= x"ff";			
        end case;																					
    end process;
end behavioral;