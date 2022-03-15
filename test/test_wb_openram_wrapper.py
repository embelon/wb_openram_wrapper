import cocotb
from cocotb.clock import Clock
from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles, with_timeout
from cocotbext.wishbone.driver import WishboneMaster, WBOp
from cocotbext.wishbone.monitor import WishboneSlave
from wb_ram import WishboneRAM

async def reset_a(dut):
    dut.wb_a_rst_i = 1
    dut.wb_a_rst_i = 0
    await ClockCycles(dut.wb_a_clk_i, 10)
    dut.wb_a_rst_i = 0
    await ClockCycles(dut.wb_a_clk_i, 10)

async def reset_b(dut):
    dut.wb_b_rst_i = 1
    dut.wb_b_rst_i = 0
    await ClockCycles(dut.wb_b_clk_i, 10)
    dut.wb_b_rst_i = 0
    await ClockCycles(dut.wb_b_clk_i, 10)

async def wbm_write(wbm_bus, addr, value):
    await wbm_bus.send_cycle([WBOp(addr, value)])

async def wbm_read(wbm_bus, addr):
    res_list = await wbm_bus.send_cycle([WBOp(addr)])
    rvalues = [entry.datrd for entry in res_list]
    return rvalues[0]


def init_ram(ram_bus, size, prefix): 
    for addr in range(size-1):
        ram_bus.data[addr] = addr | prefix


@cocotb.test()
async def test_wb_openram_wrapper(dut):

    clock = Clock(dut.wb_a_clk_i, 10, units="us")

    cocotb.fork(clock.start())

    dut.writable_port_req = 0

    wbma_signals_dict = {
        "cyc"   :   "wbs_a_cyc_i",
        "stb"   :   "wbs_a_stb_i",
        "we"    :   "wbs_a_we_i",
        "adr"   :   "wbs_a_adr_i",
        "datwr" :   "wbs_a_dat_i",
        "datrd" :   "wbs_a_dat_o",
        "ack"   :   "wbs_a_ack_o",
        "sel"   :   "wbs_a_sel_i",
    }

    wbmb_signals_dict = {
        "cyc"   :   "wbs_b_cyc_i",
        "stb"   :   "wbs_b_stb_i",
        "we"    :   "wbs_b_we_i",
        "adr"   :   "wbs_b_adr_i",
        "datwr" :   "wbs_b_dat_i",
        "datrd" :   "wbs_b_dat_o",
        "ack"   :   "wbs_b_ack_o",
        "sel"   :   "wbs_b_sel_i"
    }

    wbma_bus = WishboneMaster(dut, "", dut.wb_a_clk_i, width=32, timeout=10, signals_dict=wbma_signals_dict)
    wbmb_bus = WishboneMaster(dut, "", dut.wb_b_clk_i, width=32, timeout=10, signals_dict=wbmb_signals_dict)

    await reset_a(dut)    

    await wbm_write(wbma_bus, 0x44, 0xdeadbeef)

    await wbm_write(wbma_bus, 0, 0xc00ffeee)

    read = await wbm_read(wbma_bus, 0x44)
    assert read == 0xdeadbeef

    read = await wbm_read(wbma_bus, 0)
    assert read == 0xc00ffeee
    
