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

entity rs232transmitter_control is
  Port ( 
    rst: in STD_LOGIC;
    clk: in STD_LOGIC;
    dataRdy: in STD_LOGIC;
    writeTxD: in STD_LOGIC;
    bit_done : in STD_LOGIC;
    stateCE: out STD_LOGIC;
    baudCntCE: out STD_LOGIC;
    busy: out STD_LOGIC;
    TxDld: out STD_LOGIC;
    TxDsh: out STD_LOGIC
  );
end rs232transmitter_control;

architecture Behavioral of rs232transmitter_control is
    type states is (idle, load_frame, wait_baud_tick, shift_bits);
    signal next_state, curr_state: states;
begin
     p_reg: process (clk) 
    begin
        if rising_edge(clk) then
            if rst = '1' then
                curr_state <= idle;
            else
                curr_state <= next_state;
            end if;
        end if;
    end process p_reg;
    
    p_state: process(curr_state, bit_done, dataRdy, writeTxD)  
    begin
        case curr_state is 
            when idle => 
                if dataRdy = '1' then
                    next_state <= load_frame;
                else 
                    next_state <= idle;
                end if;
            when load_frame => 
                next_state <= wait_baud_tick;
            when wait_baud_tick => 
                if writeTxD = '1' then
                    next_state <= shift_bits;
                else 
                    next_state <= wait_baud_tick;
                end if;
            when shift_bits => 
                if bit_done = '1' then
                    next_state <= idle;
                else
                    next_state <= shift_bits;
                end if;
            when others => next_state <= idle;
        end case; 
    end process p_state;
    
    p_sal: process (curr_state, writeTxD, dataRdy) 
    begin
        case curr_state is
            when idle =>
                stateCE <= '0';
                baudCntCE <= '0';
                busy <= '0';
                TxDld <= dataRdy;
                TxDsh <= '0';
            when wait_baud_tick =>
                stateCE <= '0';
                baudCntCE <= '1';
                busy <= '1';
                TxDld <= '0';
                TxDsh <= writeTxD;
            when shift_bits =>
                stateCE <= writeTxD;
                baudCntCE <= '1';
                busy <= '1';
                TxDld <= '0';
                TxDsh <= writeTxD;
            when others =>
                stateCE <= '0';
                baudCntCE <= '0';
                busy <= '0';
                TxDld <= '0';
                TxDsh <= '0';
            end case;
    end process;
end Behavioral;