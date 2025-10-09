
TOOL = vcs
# TOOL = xrun

# Environment setup
XRUN = bs -os RHEL7 -M 8000  -source /common/appl/Env/Cadence/XCELIUM24.09.048
IMC  = bs -os RHEL7 -M 16000 -source /common/appl/Env/Cadence/cadence.CSHRC_VMANAGERMAIN24.03.002:/common/appl/Env/Cadence/XCELIUM24.09.048
BS   = bs -os RHEL7 -M 8000  -source /common/appl/Env/Synopsys/vcs_vQ-2020.03-SP1-1

# Common variables
UVM_VERBOSITY = UVM_MEDIUM
FILELIST = lst.f
TESTLIST = testlist.f

# Tool-specific settings
ifeq ($(TOOL),vcs)
  COMP_CMD = $(BS) vcs -full64 -debug_access+all -cm assert -cm_dir ./$(TEST) +vcs+lic+wait +define+$(SVA) -sverilog -timescale=1ns/1ns +incdir+. -f $(FILELIST) -ntb_opts uvm-1.2 -l comp.log
  RUN_CMD  = $(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) -cm assert +UVM_TESTNAME=$(TEST) +ntb_random_seed_automatic +ntb_random_seed_verbose +UVM_TIMEOUT=1000000 +UVM_NO_RELNOTES -l run.log
  COV_CMD  = $(BS) urg -dir $(TEST).vdb -format both
else ifeq ($(TOOL),xrun)
  COMP_CMD = 
  RUN_CMD  = $(XRUN) xrun -64bit -sv -uvmhome /common/appl/Cadence/XCELIUM24.09.048/tools/methodology/UVM/CDNS-1.2 -access +rwc -covtest $(TEST) -coverage all -cov_cgsample -svseed random -f $(FILELIST) +define+$(SVA) +UVM_VERBOSITY=$(UVM_VERBOSITY) +UVM_NO_RELNOTES +UVM_TESTNAME=$(TEST) +UVM_TIMEOUT=1000000 -l run.log
  COV_CMD  = $(IMC) imc -exec ./get_cov.tcl
endif

all: clean comp run cov

comp:
	$(COMP_CMD)

run:
	$(RUN_CMD)

cov:
	$(COV_CMD)

cov_gui:
	$(IMC) imc -gui

clean:
	rm -rf csrc simv* *.log *.key ucli.key DVEfiles novas* *.vpd *.fsdb *.h *.vdb urgReport INCA_libs *.shm xcelium.d *.history cov_work *.ucdb *covReport cov_rpt

run_filelist:
	@echo "Running all tests from $(TESTLIST)"
	@for test in $$(cat $(TESTLIST)); do \
		echo "Running $$test..."; \
		if [ "$(TOOL)" = "vcs" ]; then \
			$(BS) vcs -full64 -debug_access+all -cm assert -cm_dir ./$$test +vcs+lic+wait +define+$$test -sverilog -timescale=1ns/1ns +incdir+. -f $(FILELIST) -ntb_opts uvm-1.2 -l comp_$$test.log || exit 1; \
			$(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) -cm assert +UVM_TIMEOUT=1000000 +UVM_TESTNAME=$$test +ntb_random_seed_automatic +ntb_random_seed_verbose +UVM_NO_RELNOTES -l run_$$test.log || exit 1; \
			$(BS) urg -dir *.vdb -format both || exit 1; \
		else \
			$(XRUN) xrun -64bit -sv -uvmhome /common/appl/Cadence/XCELIUM24.09.048/tools/methodology/UVM/CDNS-1.2 -access +rwc -covtest $$test -coverage all -cov_cgsample -svseed random -f $(FILELIST) +define+$$test +UVM_VERBOSITY=$(UVM_VERBOSITY) +UVM_NO_RELNOTES +UVM_TESTNAME=$$test +UVM_TIMEOUT=1000000 -l run_$$test.log || exit 1; \
			$(IMC) imc -exec ./get_cov.tcl || exit 1; \
		fi \
	done
	
regression: clean run_filelist