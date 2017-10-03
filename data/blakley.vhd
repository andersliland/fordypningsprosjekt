----------------------------------------------------------------------------------
-- Company: NTNU
-- Engineer: Adrian Ribe and Anders Liland
-- 
-- Create Date: Fall 2016
-- Design Name: RSA cryptosystem
-- Module Name: RSACore
-- Project Name: RSA implementation in hardware
-- Target Devices:
--  Local (only synthesis) : ZedBoard Zynq Evaluation and Development Kit (xc7z020clg484-1)
--  Remote (implementation): Altera Cyclone IV (EP4CE115F29C7N)
-- Tool Versions: Vivado 2016.3
-- Description: 
-- Module prefroming the Blakley algorithm
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity blakley is
    -- number of bits, mostly used during debugging to reduce number of bits.
    generic(    bit_width : natural := 128); 
    port (
    clk                 : in std_logic;  
    reset               : in std_logic;
  
    -- Data signals                       
    factor_a        : in std_logic_vector((bit_width - 1) downto 0);    -- loaded into shift register
    factor_b        : in std_logic_vector((bit_width - 1) downto 0);    -- continuously held on input
    key_n           : in std_logic_vector((bit_width - 1) downto 0);    -- continuously held on input     
    blakley_result  : out std_logic_vector((bit_width - 1) downto 0);   -- output signal from entity
    
    -- Controll signals
    blakley_finished    : out std_logic; -- high one clk cycle when module finish
    blakley_run         : in std_logic); -- needs to be held high for module to run
 end blakley;

architecture Behavioral of blakley is
    -- extra bit added to internal signals to accomodate the two's compliment bit when R<n
    constant twos_compliment_bit : natural := 1; 
    
    -- temporary signals used to describe combinatorial circuit of Blakley algorith, see block diagram in report  
    signal r_reg  : std_logic_vector((bit_width + twos_compliment_bit) downto 0) := (others => '0');
    signal a_i    : std_logic_vector((bit_width + twos_compliment_bit) downto 0) := (others => '0');
    signal b_i    : std_logic_vector((bit_width + twos_compliment_bit) downto 0) := (others => '0');
    signal c_i    : std_logic_vector((bit_width + twos_compliment_bit) downto 0) := (others => '0');
    signal d_i    : std_logic_vector((bit_width + twos_compliment_bit) downto 0) := (others => '0');
    signal e_i    : std_logic_vector((bit_width + twos_compliment_bit) downto 0) := (others => '0');
    signal f_i    : std_logic_vector((bit_width + twos_compliment_bit) downto 0) := (others => '0');
    signal g_i    : std_logic_vector((bit_width + twos_compliment_bit) downto 0) := (others => '0');
    
    signal key_a_msb : std_logic;
    -- 1 bit wider than key_n, to avoid register overflow during left-shift, and addition operations
    signal key_n_x2 : std_logic_vector((bit_width) downto 0) := (others => '0');

    -- index for counting loop increments    
    signal index : natural range 0 to 127; 

    -- controll signal for piso register
    signal load : std_logic;
    signal so   : std_logic;
    signal pi   : std_logic_vector((bit_width - 1) downto 0) := (others => '0');
    
    -- fsm state declaration
    type state_t is (idle, running, finished);
    signal state : state_t;


begin 
key_e_shift_reg : entity work.piso_reg
    generic map (number_of_bits   => bit_width)
    port map(
        clk         => clk,
        load        => load,
        pi          => pi,
        so          => so
 );

    -- combinatorial circuti preforming Blakley algorithm
    pi <= factor_a; -- load value factor_a into shift register.
    key_a_msb <= so; -- obtaing msb of factor_a
    key_n_x2 <= key_n((bit_width-1) downto 0) & '0';
    
    -- multiplt by 2, (left shift). 128 bit vector to accomodate the two's compliment bit when R<
    a_i <= r_reg(bit_width downto 0) & r_reg(bit_width + twos_compliment_bit);  
    
    -- add factor_b
    b_i <= std_logic_vector( unsigned(a_i) + unsigned(factor_b) ); 
    -- controll whether a_i og b_i shall continue, based on msb of 
    c_i <= b_i when key_a_msb = '1' else a_i;   
    
    -- operation (R-n), also used to check if R > n.
     d_i <= std_logic_vector( unsigned(c_i) - unsigned(key_n) );
     -- operation (R-2n) used to check if R > 2n.    
     f_i <= std_logic_vector( unsigned(c_i) - unsigned(key_n_x2) );    
                   

    g_i <=  f_i when (f_i(bit_width + twos_compliment_bit) = '0') else
            d_i when (d_i(bit_width + twos_compliment_bit) = '0') else
            c_i;   

-- ***************************************************************   
-- Sequiental part of blakley state machine
--  responisble for changing state, and preforming the needed logic
-- *************************************************************** 
sequ : process (clk, reset) is
begin
    if (reset = '0') then    -- active low reset
        state <= idle;

    elsif (clk'event and clk ='1')then
        case state is
            when idle =>
                if(blakley_run = '1') then
                    state <= running;
                    -- reset start register after each itteration
                    r_reg <= (others => '0'); 
                else
                    state <= idle;
                end if;
                -- determine number of itterations, based of number of bits. konstant K in the algorithm.                       
                index <= (bit_width-1); 
            
            when running =>
                if(blakley_run = '1') then
                    -- move result from last itteration to the start of next
                    r_reg <= g_i;       
                    if( index = 0) then                    
                        state <= finished;
                    else
                        index <= index - 1;
                        state <= running;
                    end if;
                else
                    state <= idle;
                end if;
                
            when finished =>
                state <= idle;  -- 1 clock cycle in this state 
            
        end case;
    end if;
end process;


comb : process (state, g_i) is 
begin
    load <= '0';    -- define values to all controllsignal, avoiding laches
    blakley_finished <= '0';
    blakley_result <= (others => '0');

    case state is    
    when idle =>
        load <= '1';
        blakley_finished <= '0';

    when running =>
        blakley_finished <= '0'; -- not finished, module working, RSACore waiting
        load <= '0';

    when finished =>
        -- module finished, send finish signal for one clk cycle, RSACore can continue
        blakley_finished <= '1'; 
        -- maps the result of blakly computation to output wire. RSACore read value on blakley_finished = 1
        blakley_result <= g_i((bit_width - 1) downto 0);    
        load <= '0';       
    end case;    
end process;
end Behavioral;
