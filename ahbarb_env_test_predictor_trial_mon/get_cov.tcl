merge ./cov_work/scope/ahb_normal_test ./cov_work/scope/ahb_err_rsp_test -metrics covergroup:assertion -initial_model union_all -overwrite -out merged_cov
load -run ./cov_work/scope/merged_cov
report_metrics -out cov_rpt -title "My COV Report" -overwrite -detail -metrics covergroup:assertion