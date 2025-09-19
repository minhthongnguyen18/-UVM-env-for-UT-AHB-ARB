#SHELL := /bin/bash
BS  = bs -os RHEL7 -M 8000  -source /common/appl/Env/Synopsys/vcs_vQ-2020.03-SP1-1

#$(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) +UVM_TESTNAME=$(TEST) +UVM_TIMEOUT=50000 +ntb_random_seed_automatic +ntb_random_seed_verbose +UVM_NO_RELNOTES -l run.log
#$(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) +UVM_TESTNAME=$(TEST) +UVM_TIMEOUT=50000 +ntb_random_seed_verbose +UVM_NO_RELNOTES -l run.log
#$(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) +UVM_TESTNAME=$(TEST) +UVM_TIMEOUT=50000 +ntb_random_seed=1393404468 +UVM_NO_RELNOTES -l run.log
#$(BS) vcs -full64 -debug_access+all +vcs+lic+wait +define+$$test -sverilog -timescale=1ns/1ns +incdir+. -f $(FILELIST) -ntb_opts uvm-1.2 -l comp_$$test.log || exit 1; \

UVM_VERBOSITY = UVM_MEDIUM
#TEST = apb_random_test
FILELIST = lst.f
TESTLIST = testlist.f

all: clean comp run cov

comp:
	$(BS) vcs -full64 -debug_access+all -cm assert +vcs+lic+wait +define+$(SVA) -sverilog -timescale=1ns/1ns +incdir+. -f $(FILELIST) -ntb_opts uvm-1.2 -l comp.log

run:
	$(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) -cm assert +UVM_TESTNAME=$(TEST) +ntb_random_seed_automatic +ntb_random_seed_verbose +UVM_TIMEOUT=1000000 +UVM_NO_RELNOTES -l run.log

clean:
	rm -rf csrc simv* *.log *.key ucli.key DVEfiles novas* *.vpd *.fsdb *.h *.vdb urgReport

run_filelist:
	@echo "Running all tests from $(TESTLIST)"
	@for test in $$(cat $(TESTLIST)); do \
		echo "Running $$test..."; \
		$(BS) vcs -full64 -debug_access+all +vcs+lic+wait +define+$$test -sverilog -timescale=1ns/1ns +incdir+. -f $(FILELIST) -ntb_opts uvm-1.2 -l comp_$$test.log || exit 1; \
		$(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) +UVM_TIMEOUT=1000000 +UVM_TESTNAME=$$test +UVM_NO_RELNOTES -l run_$$test.log || exit 1; \
	done

regression: clean run_filelist

cov:
	 $(BS) urg -dir simv.vdb -format both
