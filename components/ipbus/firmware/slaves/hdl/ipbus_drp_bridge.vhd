-- ipbus_drp_bridge
--
-- Interfaces ipbus master to Xilinx DRP slave (for access to MGT, MAC, etc)
--
-- Dave Newbold, September 2013

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus.all;
use work.drp_decl.all;

entity ipbus_drp_bridge is
	port(
		clk: in std_logic;
		rst: in std_logic;
		ipb_in: in ipb_wbus;
		ipb_out: out ipb_rbus;
		drp_out: out drp_wbus;
		drp_in: in drp_rbus
	);
	
end ipbus_drp_bridge;

architecture rtl of ipbus_drp_bridge is

	signal busy, cyc, stb, stb_d: std_logic;

begin

	process(clk)
	begin
		if rising_edge(clk) then
			busy <= (busy or cyc) and not (drp_in.rdy or rst);
			stb_d <= stb;
		end if;
	end process;
	
	stb <= ipb_in.ipb_strobe and not busy;
	cyc <= stb and not stb_d;

	drp_out.addr <= ipb_in.ipb_addr(8 downto 0);
	drp_out.en <= cyc;
	drp_out.data <= ipb_in.ipb_wdata(15 downto 0);
	drp_out.we <= cyc and ipb_in.ipb_write;

	ipb_out.ipb_ack <= drp_in.rdy and stb;
	ipb_out.ipb_err <= '0';
	ipb_out.ipb_rdata <= X"0000" & drp_in.data;

end rtl;
