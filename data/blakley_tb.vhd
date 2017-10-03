----------------------------------------------------------------------------------
-- Company: NTNY
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
-- Testbench for Blakley module. Loads in a,b,n parameters and starts module.
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 


entity blakley_tb is
end blakley_tb;

architecture Behavioral of blakley_tb is
    
    constant NUMBER_OF_BITS : integer := 128;

    signal clk_tb            : std_logic := '0';
    signal reset_tb          : std_logic := '0';
    
    signal a_tb                 : std_logic_vector ((NUMBER_OF_BITS-1) downto 0);
    signal b_tb                 : std_logic_vector ((NUMBER_OF_BITS-1) downto 0);
    signal key_n_tb             : std_logic_vector ((NUMBER_OF_BITS-1) downto 0);    
    signal blakley_result_tb    : std_logic_vector ((NUMBER_OF_BITS-1) downto 0);
    
    
    signal blakley_run_tb       : std_logic; 
    signal blakley_finished_tb  : std_logic; 

    constant CLK_PERIOD     : time      := 20 ns; -- 50MHz clock
    constant RESET_TIME     : time      := 9 ns;
    
begin

   -- DUT instantiation
    dut: entity work.blakley
        port map(
           -- Clocks and resets 
           clk              => clk_tb,
           reset            => reset_tb, 
           factor_a         => a_tb, 
           factor_b         => b_tb,            
           key_n            => key_n_tb,
           blakley_result   => blakley_result_tb,           
           blakley_finished => blakley_finished_tb,     
           blakley_run      => blakley_run_tb
          );
        
    -- Clock generation
        clk_tb <= not clk_tb after CLK_PERIOD/2;
    
    -- Reset generation
        reset_proc: process
        begin
            reset_tb <= '0';
            wait for RESET_TIME;
            reset_tb <= '1';
            wait;
        end process;
        
  --Stimuli generation
    stimuli : process
    begin
    wait for RESET_TIME;
      
    a_tb      <= x"00000000000000000000000000000002";
    b_tb      <= x"00000000000000000000000000000003";
    key_n_tb  <= x"00000000000000000000000000000007";
    blakley_run_tb <= '1';
    
    
    wait for 3000ns;
    blakley_run_tb <= '0';
    
      
    a_tb      <= x"00000000000000000000000000000002";
    b_tb      <= x"00000000000000000000000000000003";
    key_n_tb  <= x"00000000000000000000000000000007";
    wait for 200ns;
    blakley_run_tb <= '1';
    
    wait for 3000ns;
    blakley_run_tb <= '0';
    
    a_tb      <= x"00000000000000030000000000300000";
    b_tb      <= x"00000000300000000000000000400003";
    key_n_tb  <= x"00000040000000300004000000000007";
    wait for 200ns;
    blakley_run_tb <= '1';
    
    wait for 3000ns;
    blakley_run_tb <= '0';
    
    a_tb      <= x"10004005000000030000000000300000";
    b_tb      <= x"10030000300000000000000000400003";
    key_n_tb  <= x"FF000040000000300004000000000007";
    wait for 200ns;
    blakley_run_tb <= '1';
    
    wait for 3000ns;
    blakley_run_tb <= '0';    

    wait; 
    end process;
  
  
end Behavioral;
