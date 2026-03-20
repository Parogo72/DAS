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

entity rs232transmitter_datos is
  Port ( 
    rst: in STD_LOGIC;
    clk: in STD_LOGIC;
    bit_done: out STD_LOGIC;
    TxD: out STD_LOGIC;
    stateCE: in STD_LOGIC;
    data: in STD_LOGIC_VECTOR (7 downto 0);
    TxDld: in STD_LOGIC;
    TxDsh: in STD_LOGIC
  );
end rs232transmitter_datos;

architecture Behavioral of rs232transmitter_datos is
    signal dataShift: STD_LOGIC_VECTOR (9 downto 0);
    signal TxDdata: STD_LOGIC_VECTOR(9 downto 0);
    signal bit_count : integer range 0 to 7;
begin
    dataShift <= '1' & data & '0';

    p_stateCount: process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
                bit_count <= 0;
            else
                if stateCE='1' then
                    if bit_count=7 then
                        bit_count <= 0;
                    else
                        bit_count <= bit_count + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    p_dataShifter: process (clk) 
    begin
        if rising_edge(clk) then
            if rst = '1' then
                TxDdata <= (others => '1');
            elsif TxDld = '1' then
                TxDdata <= dataShift;
            elsif TxDsh = '1' then
                TxDdata <= '1' & TxDdata(9 downto 1);
            end if; 
        end if;
    end process;

    bit_done <= '1' when (stateCE = '1' and bit_count = 7) else '0';
    TxD <= TxDdata(0);
    
end Behavioral;