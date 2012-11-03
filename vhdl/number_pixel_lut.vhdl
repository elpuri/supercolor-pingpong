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

entity number_pixel_lut is port ( 
    number : in std_logic_vector(3 downto 0);
    row : in std_logic_vector(2 downto 0);
    data : out std_logic_vector(2 downto 0)
    );
end number_pixel_lut;
    
architecture behavioral of number_pixel_lut is
begin

    process (number, row)
    begin
        case number is
            when "0000" =>
                case row is
                    when "000" =>		data <= "111";
                    when "001" =>		data <= "101";
                    when "010" =>		data <= "101";
                    when "011" =>		data <= "101";
                    when "100" => 		data <= "111";
                    when others => 		data <= "000";
                end case;
                
            when "0001" =>
                case row is
                    when "000"  =>		data <= "010";
                    when "001"  =>		data <= "010";
                    when "010" 	=>		data <= "010";
                    when "011" 	=>		data <= "010";
                    when "100" => 		data <= "010";
                    when others => 		data <= "000";
                end case;
                                    
            when "0010" =>
                case row is
                    when "000" 	=>		data <= "111";
                    when "001" 	=>		data <= "001";
                    when "010" 	=>		data <= "111";
                    when "011" 	=>		data <= "100";
                    when "100" => 		data <= "111";
                    when others => 		data <= "000";
                end case;
                                    
            when "0011" =>
                case row is
                    when "000" 	=>		data <= "111";
                    when "001" 	=>		data <= "001";
                    when "010" 	=>		data <= "011";
                    when "011" 	=>		data <= "001";
                    when "100" => 		data <= "111";
                    when others => 		data <= "000";
                end case;
                                    
            when "0100" =>
                case row is
                    when "000" 	=>		data <= "101";
                    when "001" 	=>		data <= "101";
                    when "010" 	=>		data <= "111";
                    when "011" 	=>		data <= "001";
                    when "100" => 		data <= "001";
                    when others => 		data <= "000";
                end case;
                                    
            when "0101" =>
                case row is
                    when "000" 	=>		data <= "111";
                    when "001" 	=>		data <= "100";
                    when "010" 	=>		data <= "111";
                    when "011" 	=>		data <= "001";
                    when "100" => 		data <= "111";
                    when others => 		data <= "000";
                end case;
                                    
            when "0110" =>
                case row is
                    when "000" 	=>		data <= "111";
                    when "001" 	=>		data <= "100";
                    when "010" 	=>		data <= "111";
                    when "011" 	=>		data <= "101";
                    when "100" => 		data <= "111";	
                    when others => 		data <= "000";	
                end case;
                                    
            when "0111" =>
                case row is
                    when "000" 	=>		data <= "111";
                    when "001" 	=>		data <= "001";
                    when "010" 	=>		data <= "011";
                    when "011" 	=>		data <= "001";
                    when "100" => 		data <= "001";
                    when others => 		data <= "000";
                end case;
                                    
            when "1000" =>
                case row is
                    when "000" 	=>		data <= "111";
                    when "001" 	=>		data <= "101";
                    when "010" 	=>		data <= "111";
                    when "011" 	=>		data <= "101";
                    when "100" => 		data <= "111";
                    when others => 		data <= "000";
                end case;
                                    
            when "1001" =>
                case row is
                    when "000" 	=>		data <= "111";
                    when "001" 	=>		data <= "101";
                    when "010" 	=>		data <= "111";
                    when "011" 	=>		data <= "001";
                    when "100" => 		data <= "111";
                    when others => 		data <= "000";
                end case;
                                    
            when others =>
                data <= "000";
                
        end case;
    end process;

end behavioral;