---------------------------------------------------------------------
--
--  Fichero:
--    lab4.vhd  12/09/2023
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 4
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab4 is
  port
  (
    clk     : in  std_logic;
    rst     : in  std_logic;
    ps2Clk  : in  std_logic;
    ps2Data : in  std_logic;
    speaker : out std_logic;
    an_n    : out std_logic_vector (3 downto 0);
    segs_n  : out std_logic_vector(7 downto 0)
  );
end lab4;

---------------------------------------------------------------------

use work.common.all;

architecture syn of lab4 is
  
  component synchronizer
      generic (
        STAGES : natural;
        XPOL   : std_logic
      );
      port (
        clk   : in  std_logic;
        x     : in  std_logic;
        xSync : out std_logic
      );
  end component;
  
  component ps2receiver
      port (
        -- host side
        clk        : in  std_logic;   -- reloj del sistema
        rst        : in  std_logic;   -- reset síncrono del sistema      
        dataRdy    : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
        data       : out std_logic_vector (7 downto 0);  -- dato recibido
        -- PS2 side
        ps2Clk     : in  std_logic;   -- entrada de reloj del interfaz PS2
        ps2Data    : in  std_logic    -- entrada de datos serie del interfaz PS2
      );
  end component;
  
  component segsBankRefresher
      generic(
        FREQ_KHZ : natural;
        SIZE     : natural    
      );
      port (
        clk    : in std_logic;
        ens    : in std_logic_vector (SIZE-1 downto 0);
        bins   : in std_logic_vector (4*SIZE-1 downto 0);
        dps    : in std_logic_vector (SIZE-1 downto 0);
        an_n   : out std_logic_vector (SIZE-1 downto 0);
        segs_n : out std_logic_vector (7 downto 0)
      );
  end component;
  
  constant FREQ_KHZ : natural := 100_000;        -- frecuencia de operacion en KHz
  constant FREQ_HZ  : natural := FREQ_KHZ*1000;  -- frecuencia de operacion en Hz
  
  -- Registros  

  signal code       : std_logic_vector(7 downto 0) := (others => '0');
  signal speakerTFF : std_logic := '0';
  
  -- Señales
  
  signal rstSync     : std_logic;
  signal dataRdy     : std_logic;
  signal ldCode      : std_logic;
  signal halfPeriod  : natural;
  signal data        : std_logic_vector(7 downto 0);
  signal soundEnable : std_logic;
  signal segsBin     : std_logic_vector(15 downto 0);
  -- Descomentar para instrumentar el diseño
  -- attribute mark_debug : string;
  -- attribute mark_debug of ps2Clk  : signal is "true";
  -- attribute mark_debug of ps2Data : signal is "true";
  -- attribute mark_debug of dataRdy : signal is "true";
  -- attribute mark_debug of data    : signal is "true";

begin

   resetSynchronizer : synchronizer
     generic map (STAGES => 2, XPOL => '0')
     port map (clk => clk, x => rst, xSync => rstSync);

 ------------------
 
  ps2KeyboardInterface : ps2receiver
     port map (clk => clk, rst => rstSync, dataRdy => dataRdy, data => data, ps2Clk => ps2Clk, ps2Data => ps2Data);

  codeRegister :
  process (clk)
  begin
    if rising_edge(clk) then
      if rstSync = '1' then
        code <= (others => '0');
      else
        code <= data; 
      end if;
    end if; 
  end process;
   
  halfPeriodROM :
  with code select
      halfPeriod <=
        FREQ_HZ/(2*262) when X"1C", -- A  Do
        FREQ_HZ/(2*277) when X"1D", -- W  Do#
        FREQ_HZ/(2*294) when X"1B", -- S  Re
        FREQ_HZ/(2*311) when X"24", -- E  Re#
        FREQ_HZ/(2*330) when X"23", -- D  Mi
        FREQ_HZ/(2*349) when X"2B", -- F  Fa
        FREQ_HZ/(2*370) when X"2C", -- T  Fa#
        FREQ_HZ/(2*392) when X"34", -- G  Sol
        FREQ_HZ/(2*415) when X"35", -- Y  Sol#
        FREQ_HZ/(2*440) when X"33", -- H  La
        FREQ_HZ/(2*466) when X"3C", -- U  La#
        FREQ_HZ/(2*494) when X"3B", -- J  Si
        FREQ_HZ/(2*523) when X"42", -- K  Do
        0 when others;  
    
  cycleCounter :
    process (clk)
      variable count : natural := 0;
    begin
      if rising_edge(clk) then
        if rstSync = '1' or soundEnable = '0' or halfPeriod = 0 then
          count := 0;
          speakerTFF <= '0';
        elsif count = halfPeriod then
          count := 0;
          speakerTFF <= not speakerTFF;
        else
          count := count + 1;
        end if;
      end if;
    end process;
  
  fsm:
  process (clk, dataRdy, data, code)
    type states is (S0, S1, S2, S3); 
    variable state: states := S0;
  begin 
    soundEnable <= '0';
    ldCode <= '0';
    case state is
      when S0 =>
        soundEnable <= '0';
        if dataRdy = '1' and data /= "11110000" then
          ldCode <= '1';
        end if;
      when S1 => 
        soundEnable <= '1';
      when S2 => 
        soundEnable <= '1';
      when S3 => 
        soundEnable <= '0';
    end case;
   
    if rising_edge(clk) then
      if rstSync='1' then
        state := S0;
      else 
          case state is
            when S0 =>
              if dataRdy = '1' and data /= "11110000" then
                state := S1;
              elsif dataRdy = '1' and data = "11110000" then
                state := S3;
              end if;
            when S1 =>
              if dataRdy = '1' and data = "11110000" then
                state := S2;
              end if;
            when S2 =>
              if dataRdy = '1' and data = code then
                state := S0;
              end if;
            when S3 =>
              if dataRdy = '1' then
                state := S0;
              end if;
          end case;
      end if;
    end if;
  end process;  
  
  speaker <= speakerTFF when soundEnable = '1' else '0';
  
  
  segsBin <= "0000" & code & "0000";
  displayInterface : segsBankRefresher
    generic map ( FREQ_KHZ => FREQ_KHZ, SIZE => 4 )
    port map (clk => clk, ens => "0110", bins=> segsBin, dps => "0000", an_n => an_n, segs_n => segs_n);
  
end syn;
