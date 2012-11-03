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

entity ingame_screen is port ( 
    clk_50 : in  std_logic;
    reset : in std_logic;
    
    x, y : in std_logic_vector(9 downto 0);
    p1_up, p1_down, p2_up, p2_down, hit : in std_logic;
    vblank_tick : in std_logic;
    first_to_serve : in std_logic;
    
    p1_scores, p2_scores : out std_logic;
    p1_wins, p2_wins : out std_logic;
    
    col : out std_logic_vector(2 downto 0)
    );
end ingame_screen;
    
architecture behavioral of ingame_screen is

constant border_width : std_logic_vector(9 downto 0) := "00" & x"10";
constant ball_width : std_logic_vector(9 downto 0) := "00" & x"10";
constant screen_height : std_logic_vector(9 downto 0) := "01" & x"e0";	
constant paddle_width : std_logic_vector(9 downto 0) := "00" & x"60";
constant paddle_midscreen_pos : std_logic_vector(9 downto 0) := std_logic_vector(to_unsigned(192,10));
constant max_score : std_logic_vector(3 downto 0) := "0011";

constant initial_x_speed : std_logic_vector(4 downto 0) := "00101";
constant max_x_speed : std_logic_vector(4 downto 0) := "10101";


signal border_pixel : std_logic;
signal ball_pixel : std_logic;
signal p1_paddle_pixel : std_logic;
signal p2_paddle_pixel : std_logic;
signal p1_score_pixel : std_logic;
signal p2_score_pixel : std_logic;

signal p1_score_counter, p1_score_counter_next,
       p2_score_counter, p2_score_counter_next : std_logic_vector(3 downto 0);
       
signal ball_x_speed, ball_x_speed_next : std_logic_vector(4 downto 0);			-- 5 bits integer
signal ball_y_speed, ball_y_speed_next : std_logic_vector(4 downto 0);			-- 3 bits integer 2 bits fraction
signal ball_xpos, ball_xpos_next : std_logic_vector(9 downto 0);			-- 10 bits integer
signal ball_ypos, ball_ypos_next : std_logic_vector(11 downto 0); 			-- 10 bits integer 2 bits fraction
signal ball_x_direction, ball_x_direction_next : std_logic;
signal ball_y_direction, ball_y_direction_next : std_logic;

signal p1_paddle_ypos, p1_paddle_ypos_next,									-- 10 bits integer 
       p2_paddle_ypos, p2_paddle_ypos_next : std_logic_vector(9 downto 0); 
        
signal drawing_p1_paddle, drawing_p2_paddle, drawing_p1_paddle_next, drawing_p2_paddle_next : std_logic;

type ingame_states is (p1_serving, p2_serving, ball_loose); 
signal state, state_next : ingame_states;
signal serving_player, serving_player_next : std_logic;

signal will_hit_p1_paddle, will_hit_p2_paddle : std_logic;

signal p1_score_row, p2_score_row : std_logic_vector(2 downto 0);
signal p1_score_pixel_data, p2_score_pixel_data : std_logic_vector(2 downto 0);
signal p1_active_score_pixel, p2_active_score_pixel : std_logic;

signal ball_y_speed_after_hit : std_logic_vector(4 downto 0);
signal ball_y_direction_after_hit : std_logic;
signal paddle_ball_diff : std_logic_vector(9 downto 0);

-- Signals which indicate if either of the players score. Named _i because the entity outputs are already
-- called pX_scores and the signal is also needed inside this entity (and VHDL doesn't allow using output ports
-- for anything).
signal p1_scores_i, p2_scores_i : std_logic;

begin

    p1_scores <= p1_scores_i;
    p2_scores <= p2_scores_i;
    
    -- Border draw logic
    border_pixel <= '1' when y(9 downto 4) = "000000" or y(9 downto 4) = "011101" or
                        x(9 downto 3) = "0100111" or x(9 downto 3) = "0101000" else '0';
    
    
    p1_paddle_pixel <= 	'1' when x(9 downto 4) = "000001" and drawing_p1_paddle = '1' else '0';
    p2_paddle_pixel <= 	'1' when x(9 downto 4) = "100110" and drawing_p2_paddle = '1' else '0';
    
    
    ball_pixel <= '1' when x >= ball_xpos and x <= ball_xpos + ball_width and
                           y >= ball_ypos(11 downto 2) and y <= ball_ypos(11 downto 2) + ball_width else '0';
                                  
    drawing_p1_paddle_next <= '1' when y = p1_paddle_ypos else 
                              '0' when y = p1_paddle_ypos + paddle_width else
                              drawing_p1_paddle;
            
    drawing_p2_paddle_next <= '1' when y = p2_paddle_ypos else 
                              '0' when y = p2_paddle_ypos + paddle_width else
                              drawing_p2_paddle;
                                        
    p1_score_row <= y(5 downto 3);
    p2_score_row <= y(5 downto 3);
    
    
    p1_score_pixel <= '1' when x(9 downto 5) = "00101" and y(9 downto 6) = "0001" and 
                               p1_active_score_pixel = '1' else '0';		
                                
    p1_active_score_pixel <= p1_score_pixel_data(2) when x(4 downto 3) = "00" else
                             p1_score_pixel_data(1) when x(4 downto 3) = "01" else
                             p1_score_pixel_data(0) when x(4 downto 3) = "10" else '0';
    
    p2_score_pixel <= '1' when x(9 downto 5) = "01111" and y(9 downto 6) = "0001" and 
                               p2_active_score_pixel = '1' else '0';		
                                
    p2_active_score_pixel <= p2_score_pixel_data(2) when x(4 downto 3) = "00" else
                             p2_score_pixel_data(1) when x(4 downto 3) = "01" else
                             p2_score_pixel_data(0) when x(4 downto 3) = "10" else '0';	

    p1_score_lut : entity work.number_pixel_lut port map(
        number => p1_score_counter,
        row => p1_score_row,
        data => p1_score_pixel_data );
    
    p2_score_lut : entity work.number_pixel_lut port map(
        number => p2_score_counter,
        row => p2_score_row,
        data => p2_score_pixel_data );
            
    process(border_pixel, p1_paddle_pixel, p2_paddle_pixel, ball_pixel, 
            p1_score_pixel, p2_score_pixel)
    begin
        if (p1_paddle_pixel = '1' or p2_paddle_pixel = '1') then
            col <= "100";	-- red
        elsif (ball_pixel = '1') then
            col <= "111";	-- bright white
        elsif (border_pixel = '1') then
            col <= "011";	-- light grey
        elsif (p1_score_pixel = '1' or p2_score_pixel ='1') then
            col <= "011";	-- light grey
        else
            col <= "010";	-- green
        end if;
    end process;

    
    process(clk_50, reset, first_to_serve,
            ball_xpos_next, ball_ypos_next, ball_x_speed_next, ball_y_speed_next,
            p1_paddle_ypos_next, p2_paddle_ypos_next, p1_score_counter_next, p2_score_counter_next,
            drawing_p1_paddle_next, drawing_p2_paddle_next, serving_player_next, 
            ball_x_direction_next, ball_y_direction_next)
    begin
        if (reset = '1') then
            state <= p1_serving;
            serving_player <= '0';
            drawing_p1_paddle <= '0';
            drawing_p2_paddle <= '0';
            p1_paddle_ypos <= paddle_midscreen_pos;
            p2_paddle_ypos <= paddle_midscreen_pos;
            p1_score_counter <= (others => '0');
            p2_score_counter <= (others => '0');
            

        elsif (clk_50'event and clk_50 = '1') then
            state <= state_next;
            ball_xpos <= ball_xpos_next;
            ball_ypos <= ball_ypos_next;
            ball_x_speed <= ball_x_speed_next;
            ball_y_speed <= ball_y_speed_next;
            p1_paddle_ypos <= p1_paddle_ypos_next;
            p2_paddle_ypos <= p2_paddle_ypos_next;
            p1_score_counter <= p1_score_counter_next;
            p2_score_counter <= p2_score_counter_next;
            drawing_p1_paddle <= drawing_p1_paddle_next;
            drawing_p2_paddle <= drawing_p2_paddle_next;
            serving_player <= serving_player_next;
            ball_x_direction <= ball_x_direction_next;
            ball_y_direction <= ball_y_direction_next;
        end if;	
            
    end process;
    
    
    -- Combinational logic to produce the fsm state and output signals for the master fsm
    process(state, hit, ball_xpos, p1_score_counter, p2_score_counter, serving_player,
            ball_x_direction, p1_score_counter_next, p2_score_counter_next)
    begin
        state_next <= state;
        serving_player_next <= serving_player;
        p1_score_counter_next <= p1_score_counter;	
        p2_score_counter_next <= p2_score_counter;
        p1_scores_i <= '0';
        p2_scores_i <= '0';
        p1_wins <= '0';
        p2_wins <= '0';
        
        case state is
            when p1_serving =>
                if (hit = '1') then
                    state_next <= ball_loose;
                end if;
            
            when p2_serving =>
                if (hit = '1') then
                    state_next <= ball_loose;
                end if;
            
            when ball_loose =>
                if (ball_xpos > std_logic_vector(to_unsigned(640, 10))) then
                    if (ball_x_direction = '0') then
                        p1_score_counter_next <= p1_score_counter + 1;
                        p1_scores_i <= '1';
                        if (p1_score_counter_next = max_score) then
                            p1_wins <= '1';
                        end if;
                    else
                        p2_score_counter_next <= p2_score_counter + 1;
                        if (p2_score_counter_next = max_score) then
                            p2_wins <= '1';
                        end if;
                        p2_scores_i <= '1';
                    end if;
                    
                
                    -- Switch the serving player and move to the corresponding state
                    serving_player_next <= not serving_player;
                    if (serving_player = '0') then
                        state_next <= p2_serving;
                    else
                        state_next <= p1_serving;
                    end if;
                end if;
    
            when others => 
            
        end case;	
    end process;
    

    -- Logic for calculating the new vertical speed of the ball after hitting a paddle

    -- Hopefully the synthesizer can optimize this so that theres a mux in front of "- ball_ypos + 16" with
    -- paddle y positions feeding the mux.
    paddle_ball_diff <= ball_ypos_next(11 downto 2) - p1_paddle_ypos_next + 16 when ball_x_direction = '1' else
                        ball_ypos_next(11 downto 2) - p2_paddle_ypos_next + 16;
                
    ball_y_speed_after_hit <= "11111" when paddle_ball_diff(6 downto 3) = "0000" else 
                              "10101" when paddle_ball_diff(6 downto 3) = "0001" else 
                              "01100" when paddle_ball_diff(6 downto 3) = "0010" else 
                              "01010" when paddle_ball_diff(6 downto 3) = "0011" else 
                              "01000" when paddle_ball_diff(6 downto 3) = "0100" else 
                              "00110" when paddle_ball_diff(6 downto 3) = "0101" else 
                              "00100" when paddle_ball_diff(6 downto 3) = "0110" else 
                              "00000" when paddle_ball_diff(6 downto 3) = "0111" else 
                              "00100" when paddle_ball_diff(6 downto 3) = "1000" else 
                              "00110" when paddle_ball_diff(6 downto 3) = "1001" else 
                              "01000" when paddle_ball_diff(6 downto 3) = "1010" else 
                              "01010" when paddle_ball_diff(6 downto 3) = "1011" else
                              "01100" when paddle_ball_diff(6 downto 3) = "1100" else
                              "10101" when paddle_ball_diff(6 downto 3) = "1101" else
                              "11111";
                               
    ball_y_direction_after_hit <= '0' when paddle_ball_diff(6) = '0' else '1';
    
    -- Combinational logic to produce the ball location, direction and speed
    process(state, ball_xpos, ball_ypos, p1_paddle_ypos_next, p2_paddle_ypos_next,
            ball_x_direction, ball_y_direction, ball_y_speed, vblank_tick, ball_x_speed,
            ball_ypos_next, ball_y_direction_after_hit, ball_y_speed_after_hit
            )
    begin
        ball_xpos_next <= ball_xpos;
        ball_ypos_next <= ball_ypos;
        ball_x_direction_next <= ball_x_direction;
        ball_y_direction_next <= ball_y_direction;
        ball_x_speed_next <= ball_x_speed;
        ball_y_speed_next <= ball_y_speed;	
    
        case state is
            when p1_serving =>
                ball_xpos_next <= std_logic_vector(to_unsigned(32, 10));
                ball_ypos_next <= (p1_paddle_ypos_next & "00") + 160;
                ball_x_direction_next <= '0';		-- left to right
                ball_y_speed_next <= "00000";
                ball_x_speed_next <= initial_x_speed;
                
            when p2_serving =>
                ball_xpos_next <= std_logic_vector(to_unsigned(592, 10));
                ball_ypos_next <= (p2_paddle_ypos_next & "00") + 160;			
                ball_x_direction_next <= '1';		-- left to right
                ball_y_speed_next <= "00000";
                ball_x_speed_next <= initial_x_speed;
                
            when ball_loose =>
                if (vblank_tick = '1') then
                    
                    if (ball_y_direction = '0') then
                        -- Up to down
                        if (ball_ypos + ball_y_speed < std_logic_vector(to_unsigned(448, 10)) & "00" ) then
                            ball_ypos_next <= ball_ypos + ball_y_speed;
                        else
                            ball_ypos_next <=  std_logic_vector(to_unsigned(448, 10)) & "00";
                            ball_y_direction_next <= '1';
                        end if;
                    else
                        -- Down to up
                        if (ball_ypos - ball_y_speed > std_logic_vector(to_unsigned(16, 10)) & "00") then
                            ball_ypos_next <= ball_ypos - ball_y_speed;
                        else
                            ball_ypos_next <=  std_logic_vector(to_unsigned(16, 10) & "00");
                            ball_y_direction_next <= '0';
                        end if;
                    end if;
                    
                    if (ball_x_direction = '0') then
                        -- Left to right
                        if (ball_xpos + ball_x_speed < std_logic_vector(to_unsigned(592, 10))) then
                            ball_xpos_next <= ball_xpos + ball_x_speed;
                        else
                            if (ball_ypos_next(11 downto 2) < p2_paddle_ypos_next + paddle_width and
                                ball_ypos_next(11 downto 2) + ball_width >= p2_paddle_ypos_next) then
                                
                                ball_y_direction_next <= ball_y_direction_after_hit;
                                ball_y_speed_next <= ball_y_speed_after_hit;
                                
                                ball_xpos_next <= std_logic_vector(to_unsigned(592, 10));
                                ball_x_direction_next <= '1';
                                if (ball_x_speed = max_x_speed) then
                                    ball_x_speed_next <= initial_x_speed;
                                else
                                    ball_x_speed_next <= ball_x_speed + 1;
                                end if;
                            else
                                ball_xpos_next <= ball_xpos + ball_x_speed;
                            end if;
                        end if;
                    else	-- Right to left
                        -- Check will the ball go past left paddle's right edge on next update
                        if (ball_xpos - ball_x_speed > std_logic_vector(to_unsigned(32, 10))) then
                            ball_xpos_next <= ball_xpos - ball_x_speed;
                        else
                            -- It will go, so check will it hit the paddle
                            if (ball_ypos_next(11 downto 2) < p1_paddle_ypos_next + paddle_width and
                                ball_ypos_next(11 downto 2) + ball_width >= p1_paddle_ypos_next) then
                                
                                -- It's going to hit the paddle...
                                ball_y_direction_next <= ball_y_direction_after_hit;
                                ball_y_speed_next <= ball_y_speed_after_hit;
                                
                                -- Anchor it to right edge of the left paddle
                                ball_xpos_next <= std_logic_vector(to_unsigned(32, 10));
                                ball_x_direction_next <= '0';
                                                        
                                -- Increase the speed on every hit
                                if (ball_x_speed = max_x_speed) then
                                    ball_x_speed_next <= initial_x_speed;
                                else
                                    ball_x_speed_next <= ball_x_speed + 1;
                                end if;
                            else
                                -- Is going to miss the paddle
                                ball_xpos_next <= ball_xpos - ball_x_speed;
                            end if;
                        end if;
                        
                    end if;
                end if;
            
            when others =>
            
        end case;	
    end process;
    
    
    -- Combinational logic to produce the paddle locations
    process(p1_paddle_ypos, p2_paddle_ypos, vblank_tick, p1_up, p1_down, p2_up, p2_down,
            p1_scores_i, p2_scores_i)
    begin
        p1_paddle_ypos_next <= p1_paddle_ypos;
        p2_paddle_ypos_next <= p2_paddle_ypos;
        
        -- Reset the paddle positions to the middle of the screen
        if (p1_scores_i = '1' or p2_scores_i = '1') then
            p1_paddle_ypos_next <= paddle_midscreen_pos;
            p2_paddle_ypos_next <= paddle_midscreen_pos;
        elsif (vblank_tick = '1') then
            if (p1_up = '1') then
                if (p1_paddle_ypos /= border_width) then
                    p1_paddle_ypos_next <= p1_paddle_ypos - 8;
                end if;
            elsif (p1_down = '1') then
                if (p1_paddle_ypos /= (screen_height - border_width - paddle_width ) ) then
                    p1_paddle_ypos_next <= p1_paddle_ypos + 8;
                end if;
            end if;
            
            -- Similar logic for player 2
            if (p2_up = '1') then
                if (p2_paddle_ypos /= border_width) then
                    p2_paddle_ypos_next <= p2_paddle_ypos - 8;
                end if;
            elsif (p2_down = '1') then
                if (p2_paddle_ypos /= (screen_height - border_width - paddle_width ) ) then
                    p2_paddle_ypos_next <= p2_paddle_ypos + 8;
                end if;
            end if;
        end if;
    end process;
    
end behavioral;