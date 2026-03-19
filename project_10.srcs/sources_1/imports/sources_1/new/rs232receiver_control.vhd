----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.11.2023 19:36:31
-- Design Name: 
-- Module Name: control - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rs232receiver_control is
  Port ( 
    rst: in STD_LOGIC;
    clk: in STD_LOGIC;
    RxDSync: in STD_LOGIC;
    readRxD: in STD_LOGIC;
    bit_done : in STD_LOGIC;
    stateCE: out STD_LOGIC;
    baudCntCE: out STD_LOGIC;
    dataRdy: out STD_LOGIC;
    RxDSh: out STD_LOGIC
  );
end rs232receiver_control;

architecture Behavioral of rs232receiver_control is
    type states is (s0, s1, s2, s3);
    signal next_state, curr_state: states;
begin
    p_reg: process (clk, rst) 
    begin
        if rising_edge(clk) then
            if rst = '1' then
                curr_state <= s0;
            else
                curr_state <= next_state;
            end if;
        end if;
    end process p_reg;
    
    p_state: process(curr_state, bit_done, RxDSync, readRxD)  
    begin
        case curr_state is 
            when s0 => 
                if RxDSync = '0' then
                    next_state <= s1;
                else 
                    next_state <= s0;
                end if;
            when s1 => 
                if readRxD = '1' then
                    next_state <= s2;
                else 
                    next_state <= s1;
                end if;
            when s2 => 
                if readRxD = '1' then
                    next_state <= s3;
                else 
                    next_state <= s2;
                end if;
            when s3 => 
                if bit_done = '1' then
                    next_state <= s0;
                else
                    next_state <= s3;
                end if;
            when others => next_state <= s0;
        end case; 
    end process p_state;
    
    p_sal: process (curr_state, readRxD, bit_done) 
    begin
        case curr_state is
            when s0 =>
                stateCE <= '0';
                baudCntCE <= '0';
                dataRdy <= '0';
                RxDSh <= '0';
            when s1 =>
                stateCE <= readRxD;
                baudCntCE <= '1';
                dataRdy <= '0';
                RxDSh <= readRxD;
            when s2 =>
                stateCE <= readRxD;
                baudCntCE <= '1';
                dataRdy <= '0';
                RxDSh <= readRxD;
            when s3 =>
                stateCE <= readRxD;
                baudCntCE <= '1';
                dataRdy <= bit_done;
                RxDSh <= readRxD;
            when others =>
                stateCE <= '0';
                baudCntCE <= '0';
                dataRdy <= '0';
                RxDSh <= '0';
            end case;
    end process;
end Behavioral;