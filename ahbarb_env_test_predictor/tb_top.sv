module tb_top;
    import uvm_pkg::*;
    import ahblite_pkg::*;
    
    // Parameters
    localparam int SLAVE_SIDEB = 1;
    localparam int AHB_AWIDTH  = 32;
    localparam int AHB_DWIDTH  = 32;
    localparam int SRAM_AWIDTH = 10;
    localparam int SRAM_DWIDTH = 32;
    
    // Clock and reset
    logic clk_i = 0;
    logic rst_ni = 0;
    
    // Clock generation
    always #5 clk_i = ~clk_i; // 100MHz clock
    
    // Reset generation
    initial begin
        rst_ni = 0;
        #5 rst_ni = 1;
    end
    
    ahb_if #(
        .SLAVE_SIDEB(SLAVE_SIDEB),
        .AHB_AWIDTH(AHB_AWIDTH),
        .AHB_DWIDTH(AHB_DWIDTH),
        .SRAM_AWIDTH(SRAM_AWIDTH),
        .SRAM_DWIDTH(SRAM_DWIDTH)
    ) ahb_interface (.clk_i(clk_i), .rst_ni(rst_ni));
    
    // DUT (simple slave) instance
    trc_ahbarb #(
        .SLAVE_SIDEB(SLAVE_SIDEB),
        .AHB_AWIDTH(AHB_AWIDTH),
        .AHB_DWIDTH(AHB_DWIDTH),
        .SRAM_AWIDTH(SRAM_AWIDTH),
        .SRAM_DWIDTH(SRAM_DWIDTH)
        ) dut(
        .clk_i              (clk_i),
        .rst_ni             (rst_ni),
        .te_haddr_s_i       (ahb_interface.te_haddr_s_i),
        .te_hburst_s_i      (ahb_interface.te_hburst_s_i),
        .te_hmastlock_s_i   (ahb_interface.te_hmastlock_s_i),
        .te_hprot_s_i       (ahb_interface.te_hprot_s_i),
        .te_hsize_s_i       (ahb_interface.te_hsize_s_i),
        .te_htrans_s_i      (ahb_interface.te_htrans_s_i),
        .te_hwrite_s_i      (ahb_interface.te_hwrite_s_i),
        .te_hwdata_s_i      (ahb_interface.te_hwdata_s_i),
        .te_hready_s_i      (ahb_interface.te_hready_s_i),
        .te_hauser_s_i      (ahb_interface.te_hauser_s_i),
        .te_hrdata_s_o      (ahb_interface.te_hrdata_s_o),
        .te_hready_s_o      (ahb_interface.te_hready_s_o),
        .te_hresp_s_o       (ahb_interface.te_hresp_s_o),
        .sbus_haddr_s_i     (ahb_interface.sbus_haddr_s_i),
        .sbus_hburst_s_i    (ahb_interface.sbus_hburst_s_i),
        .sbus_hmastlock_s_i (ahb_interface.sbus_hmastlock_s_i),
        .sbus_hprot_s_i     (ahb_interface.sbus_hprot_s_i),
        .sbus_hsize_s_i     (ahb_interface.sbus_hsize_s_i),
        .sbus_htrans_s_i    (ahb_interface.sbus_htrans_s_i),
        .sbus_hwrite_s_i    (ahb_interface.sbus_hwrite_s_i),
        .sbus_hwdata_s_i    (ahb_interface.sbus_hwdata_s_i),
        .sbus_hready_s_i    (ahb_interface.sbus_hready_s_i),
        .sbus_hsel_s_i      (ahb_interface.sbus_hsel_s_i),
        .sbus_hauser_s_i    (ahb_interface.sbus_hauser_s_i),
        .sbus_hrdata_s_o    (ahb_interface.sbus_hrdata_s_o),
        .sbus_hready_s_o    (ahb_interface.sbus_hready_s_o),
        .sbus_hresp_s_o     (ahb_interface.sbus_hresp_s_o),
        .mode_sbus_require_dbgpriv_i (ahb_interface.mode_sbus_require_dbgpriv_i),
        .TRAM_CE            (ahb_interface.TRAM_CE),
        .TRAM_BWE           (ahb_interface.TRAM_BWE),
        .TRAM_A             (ahb_interface.TRAM_A),
        .TRAM_D             (ahb_interface.TRAM_D),
        .TRAM_Q             (ahb_interface.TRAM_Q)
    );
    
    assign ahb_interface.state_i = dut.state;
    // UVM testbench
    initial begin
        // Store interface in config database
        uvm_config_db#(virtual ahb_if)::set(null, "*", "vif", ahb_interface);
        // Run the test
        run_test();
    end
    initial begin
        $vcdplusfile ("dump.vpd");
        $vcdpluson ();
    end
endmodule