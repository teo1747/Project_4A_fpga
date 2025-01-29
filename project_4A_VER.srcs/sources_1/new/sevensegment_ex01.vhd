library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sevensegment_ex01 is
    Port (
        anodes : out  STD_LOGIC_VECTOR (7 downto 0);  -- Anode control for the 8-digit display
        clk    : in  STD_LOGIC;                       -- Clock input
        cathods : out  STD_LOGIC_VECTOR (7 downto 0); -- Cathode control for segments
        input_val : in  INTEGER range -999 to 999     -- 3-digit signed integer input
    );
end sevensegment_ex01;

architecture Behavioral of sevensegment_ex01 is
    signal digit0 : INTEGER range 0 to 9 := 0;  -- Units digit
    signal digit1 : INTEGER range 0 to 9 := 0;  -- Tens digit
    signal digit2 : INTEGER range 0 to 9 := 0;  -- Hundreds digit
    signal is_negative : BOOLEAN := false;      -- Sign flag

    signal anodeval : STD_LOGIC_VECTOR (7 downto 0); -- Active-low anode signal
    signal cathodeval : STD_LOGIC_VECTOR (7 downto 0) := (others => '1'); -- Default cathode value (blank)

    signal clk_counter : INTEGER range 0 to 100000 := 0; -- Clock divider counter
    signal digit_number : INTEGER range 0 to 3 := 0;     -- Current digit being displayed
begin

    -- Clock Divider and Multiplexing Control
    process(clk)
    begin 
        if rising_edge(clk) then 
            clk_counter <= clk_counter + 1; 
            if clk_counter >= 100000 then -- Adjust for 1 kHz refresh rate
                clk_counter <= 0;
                digit_number <= (digit_number + 1) mod 4; -- Cycle through the digits
            end if; 
        end if; 
    end process;

    -- Convert the input value to individual digits
    process(input_val)
        variable abs_val : INTEGER;
    begin
        -- Determine the sign and absolute value
        if input_val < 0 then
            is_negative <= true;
            abs_val := -input_val; -- Take absolute value for digit extraction
        else
            is_negative <= false;
            abs_val := input_val;
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
    cathods <= cathodeval; -- Active-low cathodes

end Behavioral;
