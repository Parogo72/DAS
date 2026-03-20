---------------------------------------------------------------------
--
--  Fichero:
--    lab5.vhd  12/09/2023
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 5: Loopback con FIFO
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab5 is
  port (
    clk    :  in std_logic;
    rst    :  in std_logic;
    RxD    :  in std_logic; 
    TxD    : out std_logic;
    TxEn   :  in  std_logic;
    leds   : out std_logic_vector(15 downto 0);
    an_n   : out std_logic_vector (3 downto 0);   -- selector de display  
    segs_n : out std_logic_vector(7 downto 0)     -- código 7 segmentos
  );
END lab5;

-----------------------------------------------------------------
library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab5 is
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
  
  component rs232receiver
      generic (
        FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
        BAUDRATE : natural   -- velocidad de comunicacion
      );
      port (
        -- host side
        clk     : in  std_logic;   -- reloj del sistema
        rst     : in  std_logic;   -- reset s?ncrono del sistema
        dataRdy : out std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato recibido
        data    : out std_logic_vector (7 downto 0);   -- dato recibido
        -- RS232 side
        RxD     : in  std_logic    -- entrada de datos serie del interfaz RS-232
      );
  end component;
  
  component rs232transmitter
      generic (
        FREQ_KHZ : natural;  -- frecuencia de operacion en KHz
        BAUDRATE : natural   -- velocidad de comunicacion
      );
      port (
        -- host side
        clk     : in  std_logic;   -- reloj del sistema
        rst     : in  std_logic;   -- reset s?ncrono del sistema
        dataRdy : in  std_logic;   -- se activa durante 1 ciclo cada vez que hay un nuevo dato a transmitir
        data    : in  std_logic_vector (7 downto 0);   -- dato a transmitir
        busy    : out std_logic;   -- se activa mientras esta transmitiendo
        -- RS232 side
        TxD     : out std_logic    -- salida de datos serie del interfaz RS-232
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
  
  component fifo_generator_0
  PORT (
    clk : IN STD_LOGIC;
    srst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    data_count : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
  END component;

  constant FREQ_KHZ : natural := 100_000;  -- frecuencia de operacion en KHz
  constant BAUDRATE : natural := 1200;     -- vaelocidad de transmisión
  
  signal dataRx, dataTx: std_logic_vector (7 downto 0);
  signal dataRdyTx, dataRdyRx, busy, empty, full: std_logic;
  
  signal rstSync, TxEnSync : std_logic;
  signal fifoStatus : std_logic_vector (3 downto 0);
  
  signal numData : std_logic_vector (3 downto 0);
  signal en : std_logic;
  
begin

  rstSynchronizer : synchronizer
    generic map ( STAGES => 2, XPOL => '0' )
    port map ( clk => clk, x => rst, xSync => rstSync );
    
  TxEnSynchronizer : synchronizer
    generic map ( STAGES => 2, XPOL => '0' )
    port map ( clk => clk, x => TxEn, xSync => TxEnSync );

  receiver: rs232receiver
    generic map ( FREQ_KHZ => FREQ_KHZ, BAUDRATE => BAUDRATE )
    port map ( clk => clk, rst => rstSync, dataRdy => dataRdyRx, data => dataRx, RxD => RxD );

  fifo : fifo_generator_0
    port map ( clk => clk, srst => rstSync, wr_en => dataRdyRx, din => dataRx, rd_en => dataRdyTx, dout => dataTx, data_count => numData, full => full, empty => empty );

  dataRdyTx <= not busy and not empty and TxEnSync;
   
  transmitter: rs232transmitter 
    generic map ( FREQ_KHZ => FREQ_KHZ, BAUDRATE => BAUDRATE )
    port map ( clk => clk, rst => rstSync, dataRdy => dataRdyTx, data => dataTx, busy => busy, TxD => TxD );

  fifoStatus <= X"F" when full='1' else X"E";
  
  en <= full or empty;

  numDataDecoder:
  process( numData, full )
    variable value : integer;
  begin
      if full='1' then
        leds <= ( others => '1' );
      else
        value := to_integer(unsigned(numData));
        for i in 0 to 15 loop
          if i < value then
            leds(i) <= '1';
          else
            leds(i) <= '0';
          end if;
        end loop;
       end if;
  end process;
  
  displayInterface : segsBankRefresher
    generic map ( FREQ_KHZ => FREQ_KHZ, SIZE => 4 )
    port map ( clk => clk, ens => "110"&en, bins => dataRx(7 downto 4) & dataRx(3 downto 0) & "0000" & fifoStatus, dps => "0000", an_n => an_n, segs_n => segs_n ); 
    
end syn;