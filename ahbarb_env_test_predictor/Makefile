SHELL := /bin/bash
#BS  = bs -os RHEL7 -M 8000  -source /common/appl/Env/Synopsys/vcs_vP-2019.06
BS  = bs -os RHEL7 -M 8000  -source /common/appl/Env/Synopsys/vcs_vQ-2020.03-SP1-1
#BS  = bs -os RHEL7 -M 8000  -source /common/appl/Env/Synopsys/vcs_vW-2024.09-SP1

UVM_VERBOSITY = UVM_MEDIUM
#TEST = apb_random_test
FILELIST = lst.f
TESTLIST = testlist.f

all: clean comp run

comp:
	$(BS) vcs -full64 -debug_access+all +vcs+lic+wait +define+$(SVA) -sverilog -partcomp=modautopart -timescale=1ns/1ns \
	+incdir+. -f $(FILELIST) -ntb_opts uvm-1.2 -l comp.log

run:
	$(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) \
	+UVM_TESTNAME=$(TEST) +UVM_TIMEOUT=5000 +ntb_random_seed_automatic +ntb_random_seed_verbose +UVM_NO_RELNOTES -l run.log

clean:
	rm -rf csrc simv* *.log *.key ucli.key DVEfiles novas* *.vpd *.fsdb *.h

run_filelist:
	@echo "Running all tests from $(TESTLIST)"
	@for test in $$(cat $(TESTLIST)); do \
		echo "Running $$test..."; \
		$(BS) simv +UVM_VERBOSITY=$(UVM_VERBOSITY) +UVM_TIMEOUT=5000 +ntb_random_seed_automatic +ntb_random_seed_verbose +UVM_TESTNAME=$$test +UVM_NO_RELNOTES -l run_$$test.log || exit 1; \
	done

regression: clean comp run_filelist
