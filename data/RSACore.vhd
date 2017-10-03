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
-- Top module initiatin all sub modules, and performs the RSA encryption.
-- A FSM handles the control signals and logic.
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity RSACore is
    Port (
    -- Clocks and resets
    clk             : in std_logic;
    Resetn         : in std_logic;
    
    -- Control signals for the input inteface   
    InitRsa         : in std_logic; 
    StartRsa        : in STD_LOGIC;
    DataIn          : in STD_LOGIC_VECTOR (31 downto 0);
           
    -- Control signals for the ou inteface   
    DataOut         : out std_logic_vector (31 downto 0);
    CoreFinished    : out std_logic);   
end RSACore;

architecture rtl of RSACore is

type state_t is(idle, init, getM, core_start, core, core2, output_result);
 
-- Signal Declaration
signal state : state_t;    
signal index : natural range 0 to 128;                 -- index controlling processes              
signal key_e, key_n : std_logic_vector(127 downto 0);  -- RSA keys
signal key_e_save   : std_logic_vector(127 downto 0);  
signal data_m, data_c : std_logic_vector(127 downto 0);-- RSA data registers
signal blakley_b : std_logic_vector( 127 downto 0);    --Blakley module parameter B
signal blakley_a : std_logic_vector (127 downto 0);    --Blakley module parameter A
signal blakley_result : std_logic_vector (127 downto 0); -- Buffer storing Blakley result
 
signal blakley_finished : std_logic;                     -- controllsignal from and to blakley
signal blakley_run : std_logic;                          -- high starts blakley module 
signal data_out_reg : std_logic_vector (127 downto 0);   -- Output buffer

constant NUMBER_OF_BITS    : natural := 128;

begin
blakley_comp : entity work.blakley
    generic map(
        bit_width => NUMBER_OF_BITS
        )
    port map(
        clk               => clk,
        reset             => Resetn,
        factor_a          => blakley_a,
        factor_b          => blakley_b,
        key_n             => key_n,
        blakley_run       => blakley_run,
        blakley_finished  => blakley_finished,
        blakley_result    => blakley_result
    );
 
   
    blakley_b <= data_c; -- data_c is hardwired to blakley_b input
-- ***************************************************************   
-- Combinatorial part of the controller state machine
-- toggles all controll signals, determined from input interface, and between RSACore and blakley module.
-- the different states are thoroughly commented in the sequential part
-- ***************************************************************   
process(StartRsa, InitRsa, DataIn , state, blakley_finished, blakley_result, key_e, data_c, data_m) 
begin
   -- Define values to controll signal to avoid latches  
   blakley_a <= (others => '0'); 
   blakley_run <= '0';
case state is
    -- waits for input to InitRsa or StartRsa
    when idle =>
        blakley_run <= '0';
        CoreFinished <= '1'; 
        
    -- loads key_e and key_n into register         
    when init =>  
        blakley_run <= '0';
        CoreFinished <= '0'; 
    
    -- loads data_m and continues to core_start
    when getM =>
        CoreFinished <= '0'; 
        blakley_run <= '0'; -- continue to load M data
        
    -- sets init values for C according to Binary Method, run 1 clk cycle    
    when core_start =>
        CoreFinished <= '0';
         
    -- corresponds to "C=C*C mod n" from Binary Method      
    when core =>                            
        CoreFinished <= '0'; 
        blakley_run <= '1';
        blakley_a <= data_c; -- Load value C, according to Binary Method line 2a
        if(blakley_finished = '1') then
            blakley_run <= '0';
        end if;    
    
    -- corresponds to "C=C*M mod n" from Binary Method        
    when core2 =>                          
        CoreFinished <= '0'; 
        blakley_a <= data_m; -- Load value M, according to Binary Method line 2b
        if(blakley_finished = '1') then
            blakley_run <= '0';
        else
            -- Determines whether Binary Method line 2b is executed    
            if( key_e(127) = '1') then 
                blakley_run <= '1';               
            else
                blakley_run <= '0';    
            end if;
        end if;
        
    -- outputs the result, 4 clk cycles     
    when output_result =>
        CoreFinished <= '1';
        blakley_run <= '0'; 
    end case;
end process; --combinatorial
          
-- ***************************************************************   
-- Sequiental part of state machine
-- asynchron reset to determine initial state of system
-- 
-- ***************************************************************   
process(clk, Resetn)
begin
    -- active low reset
    if (Resetn = '0') then 
        state <= idle;          
        index <= 0;
        data_out_reg <= (others => '0');
        key_e <= (others => '0');
        key_n <= (others => '0');
        data_m <= (others => '0');
        data_c <= (others => '0');
        data_out_reg <= (others => '0');    
                
    elsif (clk'event and clk ='1')then
    case state is
    -- waiting for input signal on initRsa or StartRsa
    -- start operation imideatly accoring to project interface
    when idle =>
        if(initRsa = '1') then
            state <= init;
            -- 8 cycles to load key_e and key_n
            -- (6 +first + last)-> the firs and last are preformed while switching state
            index <= 6; 
            -- start to load values here, to shift on the same clk period as initRSA-> 1
            -- place DataIn at the 32 MSB of key_n, the 96 MSB are shifted 32 bit down                
            key_n <= DataIn & key_n( 127 downto 32);
            -- shift end of key_n into start of key_e
            key_e <= key_n (31 downto 0) & key_e(127 downto 32);    
            key_e_save <= key_n (31 downto 0) & key_e(127 downto 32);
            
        elsif(StartRsa = '1') then
            state <= getM;
             -- 4 cycles to load data_m
             -- (2+first+last)
            index <= 2;                            
            -- start to load values here, to shift on the same clk period as initRSA-> 1
            -- place DataIn at data_m 32 MSB
            data_m <= DataIn & data_m(95 downto 0); 
        else
            -- no input, stay in idle                                                    
            index <= 0;                                        
            state <= idle;                                   
        end if;        
    
    -- loads key_e and key_n into named registers 
    -- similar to idle code       
    when init =>
        key_n <= DataIn & key_n(127 downto 32);
        key_e <= key_n(31 downto 0) & key_e(127 downto 32);
        key_e_save <= key_n (31 downto 0) & key_e(127 downto 32);
        -- finished, go back to idle
        if (index = 0) then
            state <= idle;
        else 
        -- not finished, continue to load keys
            state <= init;
            index <= index - 1; --decrement counte until all keys have bee loaded    
        end if;
        
    -- loads data_m, 4 cycles   
    when getM =>
        data_m <= DataIn & data_m(127 downto 32);
        
         -- data_m finished loading, jump to next state
        if (index = 0) then           
            state <= core_start;   
        else
        -- not finished loading data_m, stay in present state
            state <= getM;           
            index <= index - 1; 
        end if;
        
    -- checks first line in binary method
    -- sets initial value on data_c, based in MSB of key_e
    -- k = number of bits in key_e
    when core_start =>      
        state <= core;
        index <= 126;   -- index = k-2 -> according to Binary Method
        -- left shift key_e, to always read the e(i) bit
        key_e <= key_e(126 downto 0) & key_e(127); 
        -- set M as initial value for C
        if (key_e(127) = '1' ) then
            data_c <= data_m;
        else
        -- set 1 as initial value for C
            data_c(0) <= '1';
            data_c(127 downto 1) <= (others => '0');
        end if;
        
        
    -- corresponds to "C=C*C mod n" from Binary Method      
    when core =>
        -- waiting for Blakley to finish computation                
        if(blakley_finished = '1') then
            -- checing in Binary Method have computed all its itterations 
            if(index = 0) then
                -- checking if core2 shall not run on the last index. Dependent on e(i).
                -- core2 shall not run, Binary Method finish, load output values
                if(key_e(127) = '0') then               
                    state <= output_result;
                    data_c <= blakley_result;
                    data_out_reg <= blakley_result;
                    DataOut <= blakley_result(31 downto 0);
                
                -- core2 shall run, Binary Method not finished
                else
                    data_c <= blakley_result;
                    state <= core2;
                end if;
            -- index not 0, continue Binary Method
            else
                data_c <= blakley_result;
                state <= core2;
            end if;
        else
        -- Blakley not finished, continue waiting
            state <= core;   
        end if;
        

    -- corresponds to "C=C*M mod n" from Binary Method, runs if e(i) = 1
    when core2 => 
        -- waiting for Blakley to finish computation                
        if(blakley_finished = '1') then
            -- checing in Binary Method have computed all its itterations 
            -- index = 0, Binary Method finished
            if(index = 0) then
                state <= output_result;  
                index <= 32;             -- ofest in DataOut register, vector index
                data_c <= blakley_result;
                data_out_reg <= blakley_result;
                DataOut <= blakley_result(31 downto 0);
                
            -- index != 0, continue Binary Method
            else
                -- pass pressent result, to next itteration
                data_c <= blakley_result;
                -- left shift key_e   
                key_e <= key_e(126 downto 0) & key_e(127); 
                state <= core;
                index <= index -1;
            end if;
        -- Blakley not finished
        else
            -- run core2 based on e(i) value
            if(key_e(127) = '1') then
                state <= core2;
            -- do not run core2, jump back to core after 1 clk cycle
            else
                -- left shift key_e
                key_e <= key_e(126 downto 0) & key_e(127); 
                state <= core;
                index <= index -1;
            end if;
        end if;
        
        
    -- output the final result in 32bit block, uses 4 clk cycles    
    when output_result =>
        -- checks when to stop, based in vector index used to determine output values from data_out_reg
        -- not finished outputing values, continue
        if(index <= 96) then
            -- increment by block length
            index <= index + 32;
            DataOut <= data_out_reg((31 + index) downto (0 + index));
        
        -- finished outputing values, jump to idle and wait for new input
        else
            state <= idle;
            key_e <= key_e_save;
        end if;       
    end case;
end if;      
end process; -- sequential
end rtl; --RSACore
