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
    type states is (idle, wait_first_sample, receive_bits, data_ready_pulse);
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
    
    p_state: process(curr_state, bit_done, RxDSync, readRxD)  
    begin
        case curr_state is 
            when idle => 
                if RxDSync = '0' then
                    next_state <= wait_first_sample;
                else 
                    next_state <= idle;
                end if;
            when wait_first_sample => 
                if readRxD = '1' then
                    next_state <= receive_bits;
                else 
                    next_state <= wait_first_sample;
                end if;
            when receive_bits => 
                if bit_done = '1' then
                    next_state <= data_ready_pulse;
                else 
                    next_state <= receive_bits;
                end if;
            when data_ready_pulse => 
                next_state <= idle;
            when others => next_state <= idle;
        end case; 
    end process p_state;
    
    p_sal: process (curr_state, readRxD) 
    begin
        case curr_state is
            when idle =>
                stateCE <= '0';
                baudCntCE <= '0';
                dataRdy <= '0';
                RxDSh <= '0';
            when wait_first_sample =>
                stateCE <= '0';
                baudCntCE <= '1';
                dataRdy <= '0';
                RxDSh <= '0';
            when receive_bits =>
                stateCE <= readRxD;
                baudCntCE <= '1';
                dataRdy <= '0';
                RxDSh <= readRxD;
            when data_ready_pulse =>
                stateCE <= '0';
                baudCntCE <= '0';
                dataRdy <= '1';
                RxDSh <= '0';
            when others =>
                stateCE <= '0';
                baudCntCE <= '0';
                dataRdy <= '0';
                RxDSh <= '0';
            end case;
    end process;
end Behavioral;