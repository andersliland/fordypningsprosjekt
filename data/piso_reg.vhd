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
-- Register used to left-shift the key_e.
-- 
----------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.ALL;

-- Parallel-in serial-out shift register.
entity piso_reg is
    generic( number_of_bits : natural);
    Port ( clk : in STD_LOGIC;
           load : in STD_LOGIC;
           pi : in STD_LOGIC_VECTOR ((number_of_bits - 1) downto 0);
           so : out STD_LOGIC);
end piso_reg;

architecture Behavioral of piso_reg is
    signal t   : std_logic;
    signal temp: std_logic_vector((number_of_bits - 1) downto 0);
begin
process (clk,pi,load)
begin
    if (clk'event and clk='1') then
        if (load='1') then
            temp <= pi;
        else
            t <= temp(number_of_bits - 1);
            temp <= temp((number_of_bits - 2) downto 0) & '0'; -- left shift
       end if;
    end if;
end process;
    so <= t;

end Behavioral;
