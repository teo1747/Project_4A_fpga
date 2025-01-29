
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY TOP IS
GENERIC (
CLKFREQ		: INTEGER := 100_000_000;
I2C_BUS_CLK	: INTEGER := 400_000;
DEVICE_ADDR	: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1001011"
);
PORT ( 
CLK 	: IN STD_LOGIC;
RST_N 	: IN STD_LOGIC;
SDA 	: INOUT STD_LOGIC;
SCL 	: INOUT STD_LOGIC;
TX 		: OUT STD_LOGIC;
LED 	: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
anodes : out  STD_LOGIC_VECTOR (7 downto 0);
cathods : out  STD_LOGIC_VECTOR (7 downto 0)

);
END TOP;

architecture Behavioral of top is

    signal digit0 : INTEGER range 0 to 9 := 0;  -- Units digit
    signal digit1 : INTEGER range 0 to 9 := 0;  -- Tens digit
    signal digit2 : INTEGER range 0 to 9 := 0;  -- Hundreds digit
    signal is_negative : BOOLEAN := false;      -- Sign flag

    signal anodeval : STD_LOGIC_VECTOR (7 downto 0); -- Active-low anode signal
    signal cathodeval : STD_LOGIC_VECTOR (7 downto 0) := (others => '1'); -- Default cathode value (blank)

    signal clk_counter : INTEGER range 0 to 100000 := 0; -- Clock divider counter
    signal digit_number : INTEGER range 0 to 3 := 0;     -- Current digit being displayed



COMPONENT ADT7420 IS
GENERIC (
	CLKFREQ			: INTEGER := 100_000_000;
	I2C_BUS_CLK		: INTEGER := 400_000;
	DEVICE_ADDR		: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1001011"
);
PORT ( 
	CLK 			: IN STD_LOGIC;
	RST_N 			: IN STD_LOGIC;
	SCL 			: INOUT STD_LOGIC;
	SDA 			: INOUT STD_LOGIC;
	INTERRUPT 		: OUT STD_LOGIC;
	TEMP 			: OUT STD_LOGIC_VECTOR (12 DOWNTO 0)
);
END COMPONENT;

COMPONENT UART_TX IS
GENERIC (
CLK_FREQ			: INTEGER := 100_000_000;
BAUD				: INTEGER := 115_200;
DBIT				: INTEGER := 8;
SB_TICK				: INTEGER := 2
);
PORT (
CLK					: IN STD_LOGIC;
TX_START			: IN STD_LOGIC;
DIN					: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
TX_DONE_TICK		: OUT STD_LOGIC;
TX					: OUT STD_LOGIC
);
END COMPONENT;

-- UART_TX signals
signal TX_START 	: std_logic := '0';
signal TX_DONE_TICK : std_logic := '0';
signal DIN 			: std_logic_vector (7 downto 0) := (others => '0');

-- ADT7420 signals
signal INTERRUPT 	: std_logic := '0';
signal TEMP		 	: std_logic_vector (12 downto 0) := (others => '0');
signal sign		 	: std_logic_vector (2 downto 0) := (others => '0');

signal temp_celsius : INTEGER  := 0;

-- signal cntr 		: integer range 0 to 255 := 0;

begin
-----------------------------------------------------------------------------------------------

ADT7420_i : ADT7420
GENERIC MAP(
	CLKFREQ		=> CLKFREQ		,
	I2C_BUS_CLK	=> I2C_BUS_CLK	,
	DEVICE_ADDR	=> DEVICE_ADDR	
)
PORT MAP( 
	CLK 		=> CLK 		    ,
	RST_N 		=> RST_N 		,
	SCL 		=> SCL 		    ,
	SDA 		=> SDA 		    ,
	INTERRUPT 	=> INTERRUPT 	,
	TEMP 		=> TEMP 		
);

UART_TX_i : UART_TX
GENERIC MAP(
CLK_FREQ		=> CLKFREQ,
BAUD			=> 115_200,
DBIT			=> 8,
SB_TICK			=> 1
)
PORT MAP(
CLK				=> CLK			 ,
TX_START		=> TX_START	     ,
DIN				=> DIN			 ,
TX_DONE_TICK	=> TX_DONE_TICK  ,
TX				=> TX			
);

sign 	<= TEMP(12) & TEMP(12) & TEMP(12);


process (CLK) begin
if (rising_edge(CLK)) then

	DIN	<= TEMP(7 downto 0);
	

	if (INTERRUPT = '1') then
		DIN			<= sign & TEMP(12 downto 8);
		TX_START	<= '1';
	end if;		
	
	if (TX_DONE_TICK = '1') then
		TX_START	<= '0';
	end if;
	
end if;
end process;

process(TEMP)
        variable temp_decimal : integer;
    begin
        
        if TEMP(12) = '1' then  
            temp_decimal := to_integer(signed(TEMP));  
        else
            temp_decimal := to_integer(unsigned(TEMP));  
        end if;

        
        temp_celsius <= temp_decimal * 625 / 10000;  
    end process;
    
-- Clock Divider and Multiplexing Control
    process(CLK)
    begin 
        if rising_edge(CLK) then 
            clk_counter <= clk_counter + 1; 
            if clk_counter >= 100000 then -- Adjust for 1 kHz refresh rate
                clk_counter <= 0;
                digit_number <= (digit_number + 1) mod 4; -- Cycle through the digits
            end if; 
        end if; 
    end process;
    
    process(temp_celsius)
        variable abs_val : INTEGER;
    begin
        -- Determine the sign and absolute value
        if temp_celsius < 0 then
            is_negative <= true;
            abs_val := -temp_celsius; -- Take absolute value for digit extraction
        else
            is_negative <= false;
            abs_val := temp_celsius;
        end if;

        -- Extract individual digits
        digit2 <= abs_val / 100;                -- Hundreds digit
        digit1 <= (abs_val / 10) mod 10;       -- Tens digit
        digit0 <= abs_val mod 10;               -- Units digit
    end process; 
    
     -- Set Anodes based on the active digit
    process(digit_number)
    begin
        case digit_number is
            when 0 => anodeval <= "11111110"; -- Activate digit 0 (Units)
            when 1 => anodeval <= "11111101"; -- Activate digit 1 (Tens)
            when 2 => anodeval <= "11111011"; -- Activate digit 2 (Hundreds)
            when 3 => anodeval <= "11110111"; -- Activate digit 3 (Sign or blank)
            when others => anodeval <= "11111111"; -- Blank
        end case;
    end process;
    
    
    -- Set Cathodes for the current digit
    process(digit_number)
    begin
        case digit_number is
            when 0 => 
                case digit0 is
                    when 0 => cathodeval <= "11000000"; -- 0
                    when 1 => cathodeval <= "11111001"; -- 1
                    when 2 => cathodeval <= "10100100"; -- 2
                    when 3 => cathodeval <= "10110000"; -- 3
                    when 4 => cathodeval <= "10011001"; -- 4
                    when 5 => cathodeval <= "10010010"; -- 5
                    when 6 => cathodeval <= "10000010"; -- 6
                    when 7 => cathodeval <= "11111000"; -- 7
                    when 8 => cathodeval <= "10000000"; -- 8
                    when 9 => cathodeval <= "10010000"; -- 9
                    when others => cathodeval <= "11111111"; -- Blank
                end case;
            when 1 => 
                case digit1 is
                    -- Same pattern as digit0, applied to digit1
                    when 0 => cathodeval <= "11000000";
                    when 1 => cathodeval <= "11111001";
                    when 2 => cathodeval <= "10100100";
                    when 3 => cathodeval <= "10110000";
                    when 4 => cathodeval <= "10011001";
                    when 5 => cathodeval <= "10010010";
                    when 6 => cathodeval <= "10000010";
                    when 7 => cathodeval <= "11111000";
                    when 8 => cathodeval <= "10000000";
                    when 9 => cathodeval <= "10010000";
                    when others => cathodeval <= "11111111";
                end case;
            when 2 => 
                case digit2 is
                    -- Same pattern as digit0, applied to digit2
                    when 0 => cathodeval <= "11000000";
                    when 1 => cathodeval <= "11111001";
                    when 2 => cathodeval <= "10100100";
                    when 3 => cathodeval <= "10110000";
                    when 4 => cathodeval <= "10011001";
                    when 5 => cathodeval <= "10010010";
                    when 6 => cathodeval <= "10000010";
                    when 7 => cathodeval <= "11111000";
                    when 8 => cathodeval <= "10000000";
                    when 9 => cathodeval <= "10010000";
                    when others => cathodeval <= "11111111";
                end case;
            when 3 => 
                if is_negative then
                    cathodeval <= "10111111"; -- Display '-' sign
                else
                    cathodeval <= "11111111"; -- Blank
                end if;
            when others =>
                cathodeval <= "11111111"; -- Blank
        end case;
    end process;

    -- Assign outputs
       

anodes <= anodeval; -- Active-low anodes
cathods <= cathodeval; 
LED(12 downto 0)	<= TEMP;
LED(15)				<= '0';
LED(14 downto 13)	<= "00";

end Behavioral;
