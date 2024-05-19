"""

Copyright (c) 2020 Alex Forencich

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

"""
import itertools
import logging
import os
import random
import pytest
import cocotb
import cocotb_test.simulator  # Ensure the correct module is imported
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.regression import TestFactory
from cocotbext.axi import AxiBus, AxiMaster

class TB(object):
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        cocotb.start_soon(Clock(dut.clk, 10, units="ps").start())  # Changed units to "ps"
        self.axi_master = AxiMaster(AxiBus.from_prefix(dut, "s_axi"), dut.clk, dut.rst)

    def set_idle_generator(self, generator=None):
        if generator:
            self.axi_master.write_if.aw_channel.set_pause_generator(generator())
            self.axi_master.write_if.w_channel.set_pause_generator(generator())
            self.axi_master.read_if.ar_channel.set_pause_generator(generator())

    def set_backpressure_generator(self, generator=None):
        if generator:
            self.axi_master.write_if.b_channel.set_pause_generator(generator())
            self.axi_master.read_if.r_channel.set_pause_generator(generator())

async def run_test_write(dut, idle_inserter=None, backpressure_inserter=None, size=None):
    tb = TB(dut)
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    for length in range(1, 2**7):
        addr = random.randint(0, 2**7-1) & ~0xF
        test_data = [random.randint(0, 255) for _ in range(length)]
        await tb.axi_master.write(addr, test_data, size=size)
        data = await tb.axi_master.read(addr, length, size=size)
        tb.log.info(f"Address: {addr}, Written: {test_data}, Read: {data.data}")
        assert data.data == test_data, f"Data mismatch at address {addr}: {data.data} != {test_data}"
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

async def run_test_read(dut, idle_inserter=None, backpressure_inserter=None, size=None):
    tb = TB(dut)
    tb.set_idle_generator(idle_inserter)
    tb.set_backpressure_generator(backpressure_inserter)
    for length in range(1, 2**7):
        addr = random.randint(0, 2**7-1) & ~0xF
        test_data = [random.randint(0, 255) for _ in range(length)]
        await tb.axi_master.write(addr, test_data, size=size)
        data = await tb.axi_master.read(addr, length, size=size)
        tb.log.info(f"Address: {addr}, Written: {test_data}, Read: {data.data}")
        assert data.data == test_data, f"Data mismatch at address {addr}: {data.data} != {test_data}"
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

async def run_pim_test(dut):
    tb = TB(dut)
    # Add PIM-specific tests here
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

def cycle_pause():
    return itertools.cycle([1, 1, 1, 0])

if cocotb.SIM_NAME:
    factory = TestFactory(run_test_write)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

    factory = TestFactory(run_test_read)
    factory.add_option("idle_inserter", [None, cycle_pause])
    factory.add_option("backpressure_inserter", [None, cycle_pause])
    factory.generate_tests()

    factory = TestFactory(run_pim_test)
    factory.generate_tests()

# cocotb-test

tests_dir = os.path.abspath(os.path.dirname(__file__))
rtl_dir = os.path.abspath(os.path.join(tests_dir, '..', '..', 'rtl'))


@pytest.mark.parametrize("data_width", [8, 16, 32])
def test_axi_pim(request, data_width):
    dut = "axi_pim"
    module = os.path.splitext(os.path.basename(__file__))[0]
    toplevel = dut

    verilog_sources = [
        os.path.join(rtl_dir, f"{dut}.v"),
        os.path.join(rtl_dir, f"PIM_MODEL.v"),
    ]

    parameters = {}

    parameters['DATA_WIDTH'] = data_width
    parameters['ADDR_WIDTH'] = 16
    parameters['STRB_WIDTH'] = parameters['DATA_WIDTH'] // 8
    parameters['ID_WIDTH'] = 8
    parameters['PIPELINE_OUTPUT'] = 0

    extra_env = {f'PARAM_{k}': str(v) for k, v in parameters.items()}

    sim_build = os.path.join(tests_dir, "sim_build",
        request.node.name.replace('[', '-').replace(']', ''))

    cocotb_test.simulator.run(
        python_search=[tests_dir],
        verilog_sources=verilog_sources,
        toplevel=toplevel,
        module=module,
        parameters=parameters,
        sim_build=sim_build,
        extra_env=extra_env,
    )

