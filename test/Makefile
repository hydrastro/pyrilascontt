# SPDX-License-Identifier: Apache-2.0

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

PWD := $(shell pwd)
REPO_ROOT := $(abspath $(PWD)/..)

TOPLEVEL = tt_um_hydrastro_pyrilascon
MODULE = test

VERILOG_SOURCES = \
	$(REPO_ROOT)/src/project.v \
	$(REPO_ROOT)/src/ascon/tt_ascon_sbox5.sv \
	$(REPO_ROOT)/src/ascon/tt_ascon_perm.sv \
	$(REPO_ROOT)/src/ascon/tt_ascon_pad.sv \
	$(REPO_ROOT)/src/ascon/tt_ascon_core.sv

COMPILE_ARGS += -Wall -g2012

COCOTB_RESULTS_FILE ?= $(PWD)/results.xml
export COCOTB_RESULTS_FILE

.PHONY: results.xml
results.xml: sim
	@test -f results.xml || { \
	  echo '<?xml version="1.0" encoding="UTF-8"?>' > results.xml; \
	  echo '<testsuite name="fallback" tests="1" failures="1" errors="0" skipped="0">' >> results.xml; \
	  echo '<testcase classname="ci" name="missing-cocotb-results"><failure message="cocotb did not create results.xml"/></testcase>' >> results.xml; \
	  echo '</testsuite>' >> results.xml; \
	}

include $(shell cocotb-config --makefiles)/Makefile.sim
