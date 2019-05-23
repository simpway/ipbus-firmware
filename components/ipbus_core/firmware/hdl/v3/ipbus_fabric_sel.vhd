---------------------------------------------------------------------------------
--
--   Copyright 2017 - Rutherford Appleton Laboratory and University of Bristol
--
--   Licensed under the Apache License, Version 2.0 (the "License");
--   you may not use this file except in compliance with the License.
--   You may obtain a copy of the License at
--
--       http://www.apache.org/licenses/LICENSE-2.0
--
--   Unless required by applicable law or agreed to in writing, software
--   distributed under the License is distributed on an "AS IS" BASIS,
--   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--   See the License for the specific language governing permissions and
--   limitations under the License.
--
--                                     - - -
--
--   Additional information about ipbus-firmare and the list of ipbus-firmware
--   contacts are available at
--
--       https://ipbus.web.cern.ch/ipbus
--
---------------------------------------------------------------------------------


-- The ipbus bus fabric, address select logic, data multiplexers
--
-- This version selects the addressed slave depending on the state
-- of incoming control lines
--
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.ipbus_v3.ALL;


entity ipbus_v3_fabric_sel is
  generic(
    NSLV: positive;
    STROBE_GAP: boolean := false;
    SEL_WIDTH: natural
   );
  port(
  	sel: in std_logic_vector(SEL_WIDTH - 1 downto 0);
    ipb_in: in ipb_wbus;
    ipb_out: out ipb_rbus;
    ipb_to_slaves: out ipb_wbus_array(NSLV - 1 downto 0);
    ipb_from_slaves: in ipb_rbus_array(NSLV - 1 downto 0) := (others => IPB_RBUS_NULL)
   );

end ipbus_v3_fabric_sel;


architecture rtl of ipbus_v3_fabric_sel is

	signal sel_i: integer range 0 to NSLV := 0;
	signal ored_ack, ored_err: std_logic_vector(NSLV downto 0);
	signal qstrobe: std_logic;

begin

	sel_i <= to_integer(unsigned(sel)) when NSLV > 1 else 0;

	ored_ack(NSLV) <= '0';
	ored_err(NSLV) <= '0';
	
	qstrobe <= ipb_in.strobe when STROBE_GAP = false else
	 ipb_in.strobe and not (ored_ack(0) or ored_err(0));

	busgen: for i in NSLV - 1 downto 0 generate
	begin

		ipb_to_slaves(i).addr <= ipb_in.addr;
		ipb_to_slaves(i).data <= ipb_in.data;
		ipb_to_slaves(i).strobe <= qstrobe when sel_i = i else '0';
		ipb_to_slaves(i).write <= ipb_in.write;
		ipb_to_slaves(i).width <= ipb_in.width;
		ored_ack(i) <= ored_ack(i+1) or ipb_from_slaves(i).ack;
		ored_err(i) <= ored_err(i+1) or ipb_from_slaves(i).err;		

	end generate;

  ipb_out.data <= ipb_from_slaves(sel_i).data when sel_i /= NSLV else (others => '0');
  ipb_out.ack <= ored_ack(0);
  ipb_out.err <= ored_err(0);
  ipb_out.rdy <= '0';
  
end rtl;