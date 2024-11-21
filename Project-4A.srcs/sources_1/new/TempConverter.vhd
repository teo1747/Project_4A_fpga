library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;  -- Ensure correct numeric operations

entity TempConverter is
    Port ( 
           temp_bin : in  std_logic_vector(12 downto 0);  
           temp_celsius : out integer); 
end TempConverter;

architecture Behavioral of TempConverter is
begin
    process(temp_bin)
        variable temp_decimal : integer;
    begin
        
        if temp_bin(12) = '1' then  
            temp_decimal := to_integer(signed(temp_bin));  
        else
            temp_decimal := to_integer(unsigned(temp_bin));  
        end if;

        
        temp_celsius <= temp_decimal * 625 / 10000;  
    end process;
end Behavioral;
