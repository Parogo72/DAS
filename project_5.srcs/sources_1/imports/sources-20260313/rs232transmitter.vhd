-------------------------------------------------------------------
--
--  Fichero:
--    rs232transmitter.vhd  15/7/2015
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Conversor elemental de paralelo a una linea serie RS-232 con 
--    protocolo de strobe
--
--  Notas de diseño:
--    - Parity: NONE
--    - Num data bits: 8
--    - Num stop bits: 1
--
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity rs232transmitter is
  generic (
    FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
    BAUDRATE : natural   -- velocidad de comunicacion
  );
  port (
    -- host side
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset síncrono del sistema
    dataRdy : in  std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato a transmitir
    data    : in  std_logic_vector (7 downto 0);   -- dato a transmitir
    busy    : out std_logic;   -- se activa mientras esta transmitiendo
    -- RS232 side
    TxD     : out std_logic    -- salida de datos serie del interfaz RS-232
  );
end rs232transmitter;

-------------------------------------------------------------------

use work.common.all;

architecture syn of rs232transmitter is
  component rs232transmitter_control
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
  end component;
  
  component rs232transmitter_datos
      Port ( 
        rst: in STD_LOGIC;
        clk: in STD_LOGIC;
        bit_done: out STD_LOGIC;
        busy: out STD_LOGIC;
        TxD: out STD_LOGIC;
        stateCE: in STD_LOGIC;
        data: in STD_LOGIC_VECTOR (7 downto 0);
        TxDld: in STD_LOGIC;
        TxDsh: in STD_LOGIC
      );
  end component;

  signal baudCntCE, writeTxD, bit_done, stateCE, TxDld, TxDsh: STD_LOGIC;
begin

  baudCnt:
  process (clk)
    constant CYCLES : natural := (FREQ_KHZ*1000)/BAUDRATE;
    variable count  : natural range 0 to CYCLES-1 := 0;
  begin
    writeTxD <= '1' when count = CYCLES-1 else '0';
    if rising_edge(clk) then
      if rst = '1' then
        count := 0;
      else 
          if baudCntCE = '1' then
            if count = CYCLES-1 then
                count := 0;
            else
                count := count + 1;
            end if;
          end if;
      end if;
    end if;
  end process;
  
  datos : rs232transmitter_datos
    port map ( 
        clk => clk, 
        rst => rst, 
        bit_done => bit_done,
        busy => busy,
        TxD => TxD,
        stateCE => stateCE,
        data => data,
        TxDld => TxDld,
        TxDsh => TxDsh
        );
        
   control : rs232transmitter_control
    port map ( 
        clk => clk, 
        rst => rst, 
        dataRdy => dataRdy,
        writeTxD => writeTxD,
        bit_done => bit_done,
        stateCE => stateCE,
        baudCntCE => baudCntCE,
        busy => busy,
        TxDld => TxDld,
        TxDsh => TxDsh
        );
  
end syn;

