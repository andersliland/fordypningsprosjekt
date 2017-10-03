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
-- Testbench designed to test the RSACore as a complete system. 
-- The testbench load in keys and message.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity RSACore_tb is
end RSACore_tb;

architecture behavioral of RSACore_tb is

    --Constants
    constant RSA_WIDTH      : natural   := 128;
    constant CLK_PERIOD     : time      := 20 ns; -- 50MHz clock
    constant RESET_TIME     : time      := 20 ns;
    
    -- Clocks and resets
    signal clk              : std_logic := '0';
    signal Resetn          : std_logic := '0';
        
    -- Data input interface
    signal InitRsa          : std_logic := '0';
    signal StartRsa         : std_logic := '0';
    signal DataIn           : std_logic_vector (31 downto 0);
    
    -- Data output interface
    signal CoreFinished     : std_logic;
    signal DataOut          : std_logic_vector (31 downto 0);
    
    signal ExpectedResult   : std_logic_vector (127 downto 0);

begin
    -- DUT instantiation
    uut_RSACore: entity work.RSACore
        port map(
           -- Clocks and resets 
           clk            => clk, 
           Resetn        => Resetn, 
            
           -- Data input interface           
           InitRsa         => InitRsa, 
           StartRsa        => StartRsa,            
           DataIn          => DataIn,
                  
           -- Data output interface           
           CoreFinished    => CoreFinished,
           DataOut         => DataOut    
        );
        
    -- Clock generation
    clk <= not clk after CLK_PERIOD/2;
    
    -- Reset generation
    reset_proc: process
    begin
        Resetn <= '0';
        wait for RESET_TIME;
        Resetn <= '1';
        wait;
    end process;
       
    --Stimuli generation
    stimuli_proc: process
    begin
        ExpectedResult <= x"7637EA28188632D8F2D92845DB649D14";
        DataIn      <= x"00000000"; --hex, 32 bit

        --Send in first test vector
        wait for 5*CLK_PERIOD;
        InitRsa     <= '1';        
        DataIn      <= x"00010001"; --e0
        
        wait for 1*CLK_PERIOD;
        InitRsa     <= '0';
        DataIn      <= x"00000000"; --e1
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"00000000"; --e2
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"00000000"; --e3
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"D79555FD"; --n0
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"C8BC49CD"; --n1
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"574E12C3"; --n2
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"819DC6B2"; --n3
                
        wait for 1*CLK_PERIOD;
        DataIn      <= x"00000000"; --error signal
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"A0000000"; --error signal
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"B0000000"; --error signal 
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"C0000000"; --error signal 
               
        -- StartRsa       
        wait for 1*CLK_PERIOD;
        StartRsa <= '1';
        DataIn      <= x"AAAAAAAA"; -- m0
        
        wait for 1*CLK_PERIOD;
        DataIn      <= x"AAAAAAAA"; --m1
        StartRsa <= '0';
        
       wait for 1*CLK_PERIOD;
        DataIn      <= x"AAAAAAAA"; --m2 
        
       wait for 1*CLK_PERIOD;
       DataIn      <= x"0AAAAAAA"; --m3  
        
       wait for 1*CLK_PERIOD;
       DataIn      <= x"05000000"; --error
       
       wait for 1*CLK_PERIOD;
       DataIn      <= x"06000000"; --error       
       
       wait for 1*CLK_PERIOD;
       DataIn      <= x"07000000"; --error  
        
       wait;     
    end process;
    
    
    
end behavioral;
