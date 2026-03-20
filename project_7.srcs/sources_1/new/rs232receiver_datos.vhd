---------------------------------------------------------------------------------- 
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2023 19:36:31
-- Design Name: 
-- Module Name: datos - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rs232receiver_datos is
  Port ( 
    rst: in STD_LOGIC;
    clk: in STD_LOGIC;
    RxDSync: in STD_LOGIC;
    bit_done: out STD_LOGIC;
    data: out STD_LOGIC_VECTOR(7 downto 0);
    stateCE: in STD_LOGIC;
    RxDsh: in STD_LOGIC
  );
end rs232receiver_datos;

architecture Behavioral of rs232receiver_datos is
    signal dataShift: STD_LOGIC_VECTOR (9 downto 0);
    signal RxDdata: STD_LOGIC_VECTOR(9 downto 0);
    signal bit_count : integer range 0 to 8;
begin
    p_stateCount: process(clk,rst)
    begin
        if rst='1' then
            bit_count <= 0;
        elsif rising_edge(clk) then
            if stateCE='1' then
                if bit_count=8 then
                    bit_count <= 0;
                else
                    bit_count <= bit_count + 1;
                end if;
            end if;
        end if;
    end process;
    
    p_dataShifter: process (rst, clk) 
    begin
        if rst = '1' then
            RxDdata <= (others => '0');
        elsif rising_edge(clk) then
            if RxDsh = '1' then
                RxDdata <= RxDSync & RxDdata(9 downto 1);
            end if; 
        end if;
    end process;

    data <= RxDdata(8 downto 1);
    bit_done <= '1' when (stateCE = '1' and bit_count = 8) else '0';
    
end Behavioral;