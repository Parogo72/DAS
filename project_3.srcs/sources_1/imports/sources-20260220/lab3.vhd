---------------------------------------------------------------------
--
--  Fichero:
--    lab3.vhd  12/09/2023
--
--    (c) J.M. Mendias
--    Diseño Automático de Sistemas
--    Facultad de Informática. Universidad Complutense de Madrid
--
--  Propósito:
--    Laboratorio 3
--
--  Notas de diseño:
--
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lab3 is
port
(
  aRst   : in  std_logic;
  osc    : in  std_logic;
  coin   : in  std_logic;
  go     : in  std_logic;
  an_n   : out std_logic_vector(3 downto 0);  
  segs_n : out std_logic_vector(7 downto 0)
);
end lab3;

---------------------------------------------------------------------

library ieee;
use ieee.numeric_std.all;
use work.common.all;

architecture syn of lab3 is
  
  component asyncRstSynchronizer
      generic (
        STAGES : natural;
        XPOL   : std_logic
      );
      port (
        clk    : in  std_logic;
        rstIn  : in  std_logic;
        rstOut : out std_logic
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
  
  component freqSynthesizer
      generic (
        FREQ_KHZ : natural;
        MULTIPLY : natural range 1 to 64;
        DIVIDE   : natural range 1 to 128
      );
      port (
        clkIn  : in  std_logic;
        rdy    : out std_logic;
        clkOut : out std_logic
      );
  end component;
  
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
  
  component debouncer
      generic(
        FREQ_KHZ  : natural;
        BOUNCE_MS : natural;
        XPOL      : std_logic
      );
      port (
        clk  : in  std_logic;
        rst  : in  std_logic;
        x    : in  std_logic;
        xDeb : out std_logic
      );
  end component;
  
  component edgeDetector
      generic(
        XPOL  : std_logic         
      );
      port (
        clk   : in  std_logic;
        x     : in  std_logic;
        xFall : out std_logic;
        xRise : out std_logic
      );
  end component;
 
  constant OSC_KHZ   : natural := 100_000;     -- frecuencia del oscilador externo en KHz
  constant FREQ_KHZ  : natural := OSC_KHZ/10;  -- frecuencia de operacion en KHz
  constant BOUNCE_MS : natural := 50;          -- tiempo de rebote de los pulsadores en ms
  
  type reelType is array (2 downto 0) of unsigned(3 downto 0);

  -- Registros  
  signal credit : unsigned(3 downto 0) := (others => '0');
  signal reel   : reelType             := (others => (others => '0'));

  -- Señales 
  signal clk, rdy : std_logic;
  signal rstSync, rstAux  : std_logic;
  signal coinSync, coinDeb, coinRise : std_logic;
  signal goSync, goDeb, goRise       : std_logic;

  signal spin : std_logic_vector(2 downto 0);
  signal decCredit, incCredit, hasCredit : std_logic;
  signal cycleCntTC : std_logic;  
  
  signal segsBin : std_logic_vector(15 downto 0);
  
begin

  rstAux <= aRst or not rdy;
  
  resetSyncronizer : asyncRstSynchronizer
    generic map ( STAGES => 2, XPOL => '0' )
    port map (clk => clk, rstIn => rstAux, rstOut=> rstSync);
    
  clkGenerator : freqSynthesizer
    generic map ( FREQ_KHZ => OSC_KHZ, MULTIPLY => 1, DIVIDE => 10 )
    port map (clkIn=> osc, rdy => rdy, clkOut=> clk);
      
  ------------------  
  
  coinSynchronizer : synchronizer
    generic map (STAGES => 2, XPOL => '0')
    port map (clk => clk, x => coin, xSync => coinSync);
   
  coinDebouncer : debouncer
    generic map (FREQ_KHZ => FREQ_KHZ, BOUNCE_MS => BOUNCE_MS, XPOL => '0')
    port map (clk => clk, rst => rstSync, x => coinSync, xDeb => coinDeb);
   
  coinEdgeDetector : edgeDetector
    generic map (XPOL    => '0')
    port map (clk => clk, x => coinDeb, xRise => coinRise, xFall => open);
  
  ------------------  

  goSynchronizer : synchronizer
    generic map (STAGES => 2, XPOL => '0')
    port map (clk => clk, x => go, xSync => goSync);
   
  goDebouncer : debouncer
    generic map (FREQ_KHZ => FREQ_KHZ, BOUNCE_MS => BOUNCE_MS, XPOL => '0')
    port map (clk => clk, rst => rstSync, x => goSync, xDeb => goDeb);
   
  goEdgeDetector : edgeDetector
    generic map (XPOL    => '0')
    port map (clk => clk, x => goDeb, xRise => goRise, xFall => open);
  
  ------------------  
 
  fsm:
  process (rstSync, clk, goRise, hasCredit)
    type states is (initial, S1, S2, S3, reward); 
    variable state: states := initial;
  begin 
    decCredit <= '0';
    incCredit <= '0';
    spin      <= (others => '0');
    case state is
      when initial =>
        spin      <= (others => '0');
      when S1 => 
        spin      <= (others => '1');
      when S2 => 
        spin      <= "011";
      when S3 => 
        spin      <= "001";
      when reward => 
        spin      <= (others => '0');
    end case;
    if rstSync='1' then
      state := initial;
    elsif rising_edge(clk) then
      case state is
        when initial =>
          if goRise = '1' and hasCredit = '1' then
            decCredit <= '1';
            state := S1;
          end if;
        when S1 =>
          if goRise = '1' then
            state := S2;
          end if;
        when S2 =>
          if goRise = '1' then
            state := S3;
          end if;
        when S3 =>
          if goRise = '1' then
            state := reward;
          end if;
        when reward =>
          incCredit <= '1';
          state := initial;
      end case;
    end if;
  end process;  
  
  cycleCounter :  
  process (clk, rstSync)
    constant CYCLES : natural := ms2cycles(FREQ_KHZ, 50);
    variable count  : natural range 0 to CYCLES := 0;
  begin
    if rstSync='1' then
        count := 0;
        cycleCntTC <= '0';
    elsif rising_edge(clk) then
      if count = CYCLES-1 then
        count := 0;
        cycleCntTC <= '1';
      else
        count := count + 1;
        cycleCntTC <= '0';
      end if;
    end if;
  end process;
     
  reelRegisters : 
  for i in reel'range generate
  begin
    process (rstSync, clk)
    begin
      if rstSync='1' then
        reel(i) <= (others => '0');
      elsif rising_edge(clk) then
        if spin(i)='1' and cycleCntTC = '1' then
          if reel(i) = to_unsigned(5, 4) then
            reel(i) <= (others => '0');
          else
            reel(i) <= reel(i) + 1;
          end if;
        end if;
      end if;
    end process; 
  end generate;
 
  creditComparator: 
  hasCredit <= '1' when credit > 0 else '0';
  
  creditRegister :
  process (rstSync, clk)
  begin
    if rstSync='1' then
      credit <= (others => '0');    
    elsif rising_edge(clk) then
      if coinRise='1' then
        credit <= credit + 1;
      elsif decCredit='1' then
        credit <= credit - 1;
      elsif incCredit='1' then
        if reel(0) = reel(1) and reel(1) = reel(2) then
            credit <= credit + 3;
        elsif reel(0) = reel(1) or reel(0) = reel(2) or reel(1) = reel(2) then
            credit <= credit + 2;
        end if;
      end if;
   end if; 
  end process; 
  
  segsSignal:
  segsBin <= std_logic_vector(credit) & std_logic_vector(reel(0)) & std_logic_vector(reel(1)) & std_logic_vector(reel(2));
  
  displayInterface : segsBankRefresher
    generic map ( FREQ_KHZ => OSC_KHZ, SIZE => 4 )
    port map (clk => osc, ens => "1111", bins=> segsBin, dps => "1000", an_n => an_n, segs_n => segs_n);

end syn;
