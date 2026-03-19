-------------------------------------------------------------------
--
--  Fichero:
--    rs232receiver.vhd  12/09/2023
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Conversor elemental de una linea serie RS-232 a paralelo con 
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

entity rs232receiver is
  generic (
    FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
    BAUDRATE : natural   -- velocidad de comunicacion
  );
  port (
    -- host side
    clk     : in  std_logic;   -- reloj del sistema
    rst     : in  std_logic;   -- reset síncrono del sistema
    dataRdy : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
    data    : out std_logic_vector (7 downto 0);   -- dato recibido
    -- RS232 side
    RxD     : in  std_logic    -- entrada de datos serie del interfaz RS-232
  );
end rs232receiver;

-------------------------------------------------------------------

use work.common.all;

architecture syn of rs232receiver is
  
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
  
  component rs232receiver_control
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
  end component;
  
  component rs232receiver_datos
      Port ( 
        rst: in STD_LOGIC;
        clk: in STD_LOGIC;
        RxDSync: in STD_LOGIC;
        bit_done: out STD_LOGIC;
        data: out STD_LOGIC_VECTOR(7 downto 0);
        stateCE: in STD_LOGIC;
        RxDsh: in STD_LOGIC
      );
  end component;
  signal RxDSync : std_logic;
  signal readRxD, baudCntCE, bit_done, stateCE, RxDsh : std_logic;

begin

  RxDSynchronizer : synchronizer
    generic map ( STAGES => 2, XPOL => '1' )
    port map ( clk => clk, x => RxD, xSync => RxDSync );
    
baudCnt:
  process (clk)
    constant CYCLES : natural := (FREQ_KHZ*1000)/BAUDRATE;
    variable count  : natural range 0 to CYCLES-1 := 0;
  begin
    readRxD <= '1' when count = CYCLES/2-1 else '0';
    if rising_edge(clk) then
      if rst = '1' then
        count := 0;
      elsif baudCntCE = '1' then
            if count = CYCLES-1 then
                count := 0;
            else
                count := count + 1;
            end if;
      else 
            count := 0;
      end if;
    end if;
  end process;
  
  datos : rs232receiver_datos
    port map ( 
        clk => clk, 
        rst => rst, 
        RxDSync => RxDSync,
        bit_done => bit_done,
        data => data,
        stateCE => stateCE,
        RxDsh => RxDsh
        );
        
   control : rs232receiver_control
    port map ( 
        clk => clk, 
        rst => rst, 
        RxDSync => RxDSync,
        dataRdy => dataRdy,
        readRxD => readRxD,
        bit_done => bit_done,
        stateCE => stateCE,
        baudCntCE => baudCntCE,
        RxDsh => RxDsh
        );
  
  
end syn;
