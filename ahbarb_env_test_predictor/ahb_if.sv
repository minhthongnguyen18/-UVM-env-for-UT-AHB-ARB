`include "uvm_macros.svh"
import uvm_pkg::*;
import ahblite_pkg::*;

interface ahb_if #(
    parameter int SLAVE_SIDEB   = 1,
    parameter int AHB_AWIDTH    = 32,
    parameter int AHB_DWIDTH    = 32,
    parameter int SRAM_AWIDTH       = 10,
    parameter int SRAM_DWIDTH       = 32
)
(
    input logic clk_i,
    input logic rst_ni
);
    // AHB Lite Slave System BUS IF - TE interface
    logic [AHB_AWIDTH-1:0]   te_haddr_s_i;               // Address access
    logic [2:0]              te_hburst_s_i;              // SINGLE is only support: Fix0
    logic                    te_hmastlock_s_i;           // Not support slave MasterLock: Fix to 0
    logic [3:0]              te_hprot_s_i;               // AHB slave protect: Fix0
    logic [2:0]              te_hsize_s_i;               // Only word access
    logic [1:0]              te_htrans_s_i;              // BUSY and SEQUENTIAL are not supported because master support SINGLE only 
    logic                    te_hwrite_s_i;              // 1: write, 0: read
    logic [AHB_DWIDTH-1:0]   te_hwdata_s_i;              // Write data
    logic                    te_hready_s_i;              // Ready: fix 1
    logic [SLAVE_SIDEB-1:0]  te_hauser_s_i;              // bit0: Debug mode; Others are reserved

    logic [AHB_DWIDTH-1:0]   te_hrdata_s_o;              // Read data
    logic                    te_hready_s_o;              // A transfer has finished: fix 1
    logic                    te_hresp_s_o;               // Transfer response: fix 0

    //AHB Lite Slave System Bus IF - System Bus Interface
    logic [AHB_AWIDTH-1:0]   sbus_haddr_s_i;             // Address access
    logic [2:0]              sbus_hburst_s_i;            // Slave Busrt 
    logic                    sbus_hmastlock_s_i;         // Slave Master Lock
    logic [3:0]              sbus_hprot_s_i;             // AHB slave protect
    logic [2:0]              sbus_hsize_s_i;             // Byte, hword, word are supported
    logic [1:0]              sbus_htrans_s_i;            // BUSY and SEQUENTIAL are not supported because master support SINGLE only
    logic                    sbus_hwrite_s_i;            // 1: write, 0: read
    logic [AHB_DWIDTH-1:0]   sbus_hwdata_s_i;            // Write data
    logic                    sbus_hready_s_i;            // Ready
    logic                    sbus_hsel_s_i;              // AHB slave select
    logic [SLAVE_SIDEB-1:0]  sbus_hauser_s_i;            // Bit0: Debug mode; Others are reserved
    logic [AHB_DWIDTH-1:0]   sbus_hrdata_s_o;            // Read data
    logic                    sbus_hready_s_o;            // A transfer has finished
    logic                    sbus_hresp_s_o;             // Transfer response
        
    //Mode IF
    logic                    mode_sbus_require_dbgpriv_i; //Mode signal
    
    //skid buffer
    logic                    skid_state;  //1: buffer full, 0: buffer empty
    logic                    skid_enable;
    logic [2:0]              skbf_size;
    logic                    skbf_write;
    logic [SLAVE_SIDEB-1:0]  skbf_auser;
    logic [AHB_AWIDTH-1:0]   skbf_addr;
    
    //SRAM IF
    logic                    TRAM_CE;      //Chip select
    logic [3:0]              TRAM_BWE;     //Write Enable
    logic [SRAM_AWIDTH-1:2]  TRAM_A;       //Address
    logic [SRAM_DWIDTH-1:0]  TRAM_D;       //Write data
    logic [SRAM_DWIDTH-1:0]  TRAM_Q;       //Read data
    typedef enum logic [3:0]    {IDLE, 
                        SB_ERROR_W, 
                        SB_ERROR_D,
                        TE_WRITE_D_SB_ERROR_D,
                        SB_WRITE_D,
                        TE_WRITE_D_SB_SKID_W,
                        SB_READ_W,
                        TE_WRITE_D_SB_READ_D,
                        SB_READ_D,
                        TE_WRITE_D
                        }   fsm_state;
        fsm_state    state_o;
        logic [3:0]  state_i;
        assign state_o = state_i;

logic te_req;
logic sbus_req;

assign te_req = te_hready_s_i & (te_htrans_s_i == 2'b10 | te_htrans_s_i == 2'b11);
assign sbus_req = sbus_hready_s_i & sbus_hsel_s_i & ((sbus_htrans_s_i == 2'b10) | (sbus_htrans_s_i == 2'b11));

`ifdef ahb_err_rsp_2nd_cycle_test

    property p_item_8_1;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (te_req == 0 &&
        mode_sbus_require_dbgpriv_i == 1 &&  
        // sbus_req == 1 && sbus_hwrite_s_i == 1 &&  sbus_hauser_s_i[0] == 0 && sbus_hsize_s_i[1:0] == 2'b10 &&
        sbus_req == 1 && sbus_hwrite_s_i == 1 &&  sbus_hauser_s_i[0] == 0 &&
        state_o == IDLE)
        ##1 (te_req == 0) |->
        (TRAM_CE == 0 && 
        sbus_hready_s_o == 0 && sbus_hresp_s_o == 1 &&
        state_o == SB_ERROR_W)
        ##1 (TRAM_CE == 0 &&
        sbus_hready_s_o == 1 && sbus_hresp_s_o == 1 &&
        state_o == SB_ERROR_D);
    endproperty
    
    property p_item_8_2;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (te_req == 0 &&
        mode_sbus_require_dbgpriv_i == 1 &&  
        // sbus_req == 1 && sbus_hwrite_s_i == 0 &&  sbus_hauser_s_i[0] == 0 && sbus_hsize_s_i[1:0] == 2'b10 &&
        sbus_req == 1 && sbus_hwrite_s_i == 0 &&  sbus_hauser_s_i[0] == 0 &&
        state_o == IDLE)
        ##1 (te_req == 0) |->
        (TRAM_CE == 0 && 
        sbus_hready_s_o == 0 && sbus_hresp_s_o == 1 &&
        state_o == SB_ERROR_W)
        ##1 (TRAM_CE == 0 &&
        sbus_hready_s_o == 1 && sbus_hresp_s_o == 1 &&
        state_o == SB_ERROR_D);
    endproperty

    a_item_8_1                : assert property (p_item_8_1) else $display("Simulation is stopped by %m FAIL");
    a_item_8_2                : assert property (p_item_8_2) else $display("Simulation is stopped by %m FAIL"); 

    property p_item_9_1;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (!te_req &&
        mode_sbus_require_dbgpriv_i &&
        sbus_req && sbus_hwrite_s_i && !sbus_hauser_s_i[0] && sbus_hsize_s_i[1:0] == 2'b10 &&
        state_o == IDLE) 
        ##1 (te_req) |->
        (!TRAM_CE &&
        !sbus_hready_s_o && sbus_hresp_s_o &&
        state_o == SB_ERROR_W &&
        !skid_state)
        ##1
        (sbus_hready_s_o && sbus_hresp_s_o && TRAM_CE && 
        TRAM_BWE == 4'hf && 
        TRAM_A == $past(te_haddr_s_i[SRAM_AWIDTH-1:2]) && 
        TRAM_D == te_hwdata_s_i &&
        state_o == TE_WRITE_D_SB_ERROR_D &&
        !skid_state);
    endproperty
    
    property p_item_9_2;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (te_req &&
        !mode_sbus_require_dbgpriv_i &&
        sbus_req && sbus_hwrite_s_i && !sbus_hauser_s_i[0] && sbus_hsize_s_i[1:0] == 2'b10 &&
        state_o == TE_WRITE_D_SB_ERROR_D) 
        ##1 (te_req) |->
        (TRAM_CE &&
        TRAM_BWE == 4'hf && 
        TRAM_A == $past(te_haddr_s_i[SRAM_AWIDTH-1:2]) && 
        TRAM_D == te_hwdata_s_i &&
        !sbus_hready_s_o && !sbus_hresp_s_o &&
        state_o == TE_WRITE_D_SB_SKID_W &&
        skid_state && skbf_size == $past(sbus_hsize_s_i) && skbf_addr == $past(sbus_haddr_s_i) && skbf_write == $past(sbus_hwrite_s_i) && skbf_auser == $past(sbus_hauser_s_i))
        ##1
        (!sbus_hready_s_o && !sbus_hresp_s_o && TRAM_CE && 
        TRAM_BWE == 4'hf && 
        TRAM_A == $past(te_haddr_s_i[SRAM_AWIDTH-1:2]) && 
        TRAM_D == te_hwdata_s_i &&
        state_o == TE_WRITE_D_SB_SKID_W &&
        skid_state && skbf_size == $past(skbf_size) && skbf_addr == $past(skbf_addr) && skbf_write == $past(skbf_write) && skbf_auser == $past(skbf_auser));
    endproperty
    
        logic [3:0] bwe;
        always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            bwe <= 4'b0000;
        end 
        else if (skbf_size[1:0] == 2'b00 && skbf_addr[1:0] == 2'b00) begin
            bwe <= 4'b0001;      
        end
        else if (skbf_size[1:0] == 2'b00 && skbf_addr[1:0] == 2'b01) begin
            bwe <= 4'b0010;      
        end
        else if (skbf_size[1:0] == 2'b00 && skbf_addr[1:0] == 2'b10) begin
            bwe <= 4'b0100;      
        end
        else if (skbf_size[1:0] == 2'b00 && skbf_addr[1:0] == 2'b11) begin
            bwe <= 4'b1000;      
        end
        else if (skbf_size[1:0] == 2'b01 && skbf_addr[1:0] == 2'b00) begin
            bwe <= 4'b0011;      
        end
        else if (skbf_size[1:0] == 2'b01 && skbf_addr[1:0] == 2'b01) begin
            bwe <= 4'b0011;      
        end
        else if (skbf_size[1:0] == 2'b01 && skbf_addr[1:0] == 2'b10) begin
            bwe <= 4'b1100;      
        end
        else if (skbf_size[1:0] == 2'b01 && skbf_addr[1:0] == 2'b11) begin
            bwe <= 4'b1100;      
        end
        else if (skbf_size[1:0] == 2'b10) begin
            bwe <= 4'b1111;      
        end
        else if (skbf_size[1:0] == 2'b11) begin
            bwe <= 4'b1111;      
        end
        end
    
    property p_item_9_3; 
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (!te_req && skbf_write && !mode_sbus_require_dbgpriv_i &&
        state_o == TE_WRITE_D_SB_SKID_W) |->
        ##1
        (TRAM_CE && TRAM_BWE == bwe && 
        TRAM_A == $past(skbf_addr[SRAM_AWIDTH-1:2]) &&
        TRAM_D == sbus_hwdata_s_i &&
        sbus_hready_s_o && !sbus_hresp_s_o &&
        state_o == SB_WRITE_D &&
        !skid_state);
    endproperty

    a_item_9_1                : assert property (p_item_9_1) else $display("Simulation is stopped by %m FAIL");
    a_item_9_2                : assert property (p_item_9_2) else $display("Simulation is stopped by %m FAIL");
    a_item_9_3                : assert property (p_item_9_3) else $display("Simulation is stopped by %m FAIL");

`elsif ahb_TE_SB_simultaneous_test

    property p_item_3_1_2_1;
    @( posedge clk_i )
      1 |->  (te_hrdata_s_o == 32'h0);
    endproperty
    
    property p_item_3_1_2_2;
    @( posedge clk_i )
      1 |-> (te_hready_s_o);
    endproperty
    
    property p_item_3_1_2_3;
    @( posedge clk_i )
       1 |-> (!te_hresp_s_o);
    endproperty
    
    property p_item_3_1_4_2;
    @( posedge clk_i )
      1 |->  (te_haddr_s_i[1:0] == 2'b00);
    endproperty
    
    property p_item_3_1_5;
    @( posedge clk_i )
      1 |->  (te_haddr_s_i[31:12] == 20'h0);
    endproperty
    
    property p_item_3_3_2;
    @( posedge clk_i )
      1 |->  (te_hwrite_s_i);
    endproperty
    
    a_item_3_1_2_1 : assert property (p_item_3_1_2_1) else $display("Simulation is stopped by %m FAIL");
    a_item_3_1_2_2 : assert property (p_item_3_1_2_2) else $display("Simulation is stopped by %m FAIL");
    a_item_3_1_2_3 : assert property (p_item_3_1_2_3) else $display("Simulation is stopped by %m FAIL");
    a_item_3_1_4_2 : assert property (p_item_3_1_4_2) else $display("Simulation is stopped by %m FAIL");
    a_item_3_1_5   : assert property (p_item_3_1_5) else $display("Simulation is stopped by %m FAIL");
    a_item_3_3_2   : assert property (p_item_3_3_2) else $display("Simulation is stopped by %m FAIL");

    property p_item_4_1;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (te_req == 1 &&
        sbus_req == 0 && 
        state_o == IDLE) |->
        ##1   
        (TRAM_CE == 1 && TRAM_BWE == 4'hf && 
        TRAM_A == $past(te_haddr_s_i[SRAM_AWIDTH-1:2]) && 
        TRAM_D == te_hwdata_s_i &&
        state_o == TE_WRITE_D);
    endproperty
    
    a_item_4_1                : assert property (p_item_4_1) else $display("Simulation is stopped by %m FAIL");

    property p_item_5_1;
    @( posedge clk_i )
        (te_req == 0 &&
        mode_sbus_require_dbgpriv_i == 0 &&  
        sbus_req == 1 && sbus_hwrite_s_i == 1 &&  sbus_hauser_s_i[0] == 1 && sbus_hsize_s_i[1:0] == 2'b10 &&
        state_o == IDLE) |->
        ##1
        (TRAM_CE == 1 && TRAM_BWE == 4'hf && 
        TRAM_A == $past(sbus_haddr_s_i[SRAM_AWIDTH-1:2]) && 
        TRAM_D == sbus_hwdata_s_i &&
        sbus_hready_s_o == 1 && sbus_hresp_s_o == 0 &&
        state_o == SB_WRITE_D);
    endproperty
    
    property p_item_5_2;
    @( posedge clk_i )
        (te_req == 0 &&
        mode_sbus_require_dbgpriv_i == 0 &&  
        sbus_req == 1 && sbus_hwrite_s_i == 0 &&  sbus_hauser_s_i[0] == 1 && sbus_hsize_s_i[1:0] == 2'b10 &&
        state_o == IDLE) 
        ##1 (te_req == 0) |->
        (TRAM_CE == 1 && TRAM_BWE == 4'h0 && 
        TRAM_A == $past(sbus_haddr_s_i[SRAM_AWIDTH-1:2]) && 
        sbus_hready_s_o == 0 && sbus_hresp_s_o == 0 &&
        state_o == SB_READ_W) 
        ##1 
        (TRAM_CE == 0 &&
        sbus_hready_s_o == 1 && sbus_hresp_s_o == 0 && sbus_hrdata_s_o == TRAM_Q &&
        state_o == SB_READ_D);
    endproperty
    
    a_item_5_1                : assert property (p_item_5_1) else $display("Simulation is stopped by %m FAIL");
    a_item_5_2                : assert property (p_item_5_2) else $display("Simulation is stopped by %m FAIL");
    
    function logic [3:0] cal_bwe( logic [1:0] size, logic [1:0] addr);
        case (size)
            HSIZE_BYTE: begin
                case (addr)
                    2'b00: return 4'b0001;
                    2'b01: return 4'b0010;
                    2'b10: return 4'b0100;
                    2'b11: return 4'b1000;
                endcase
            end
            HSIZE_HWORD: begin
                case (addr[1])
                    1'b0:  return 4'b0011;
                    1'b1:  return 4'b1100;
                endcase
            end
            HSIZE_WORD, HSIZE_DWORD: begin
                return 4'b1111;
            end
            default: return 4'b0000;
        endcase
    endfunction
    
    logic [3:0] exp_bwe;
    always_comb begin
        exp_bwe = cal_bwe(skbf_size[1:0], skbf_addr[1:0]);
    end
    
    property p_item_6_1;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (te_req &&
        !mode_sbus_require_dbgpriv_i &&
        // sbus_req && sbus_hwrite_s_i && sbus_hauser_s_i[0] && sbus_hsize_s_i[1:0] == 2'b00 && sbus_haddr_s_i[1:0] == 2'b00 &&
        sbus_req && sbus_hwrite_s_i && sbus_hauser_s_i[0] &&
        state_o == IDLE) 
        ##1 !te_req |->
        (TRAM_CE &&
        TRAM_BWE == 4'hf && 
        TRAM_D == te_hwdata_s_i &&
        TRAM_A == $past(te_haddr_s_i[SRAM_AWIDTH-1:2]) &&
        !sbus_hready_s_o && !sbus_hresp_s_o &&
        state_o == TE_WRITE_D_SB_SKID_W &&
        skid_state)
        ##1
        (sbus_hready_s_o && !sbus_hresp_s_o && TRAM_CE && 
        TRAM_BWE == exp_bwe && 
        TRAM_D == sbus_hwdata_s_i &&
        TRAM_A == $past((sbus_haddr_s_i[SRAM_AWIDTH-1:2]),2) && 
        state_o == SB_WRITE_D &&
        !skid_state);
    endproperty
    
    property p_item_6_2;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (te_req &&
        !mode_sbus_require_dbgpriv_i &&
        // sbus_req && !sbus_hwrite_s_i && sbus_hauser_s_i[0] && sbus_hsize_s_i[1:0] == 2'b01 &&
        sbus_req && !sbus_hwrite_s_i && sbus_hauser_s_i[0] &&
        state_o == IDLE) 
        ##1 !te_req |->
        (TRAM_CE &&
        TRAM_BWE == 4'hf && 
        TRAM_D == te_hwdata_s_i &&
        TRAM_A == $past(te_haddr_s_i[SRAM_AWIDTH-1:2]) &&
        !sbus_hready_s_o && !sbus_hresp_s_o &&
        state_o == TE_WRITE_D_SB_SKID_W &&
        skid_state)
        ##1
        (!sbus_hready_s_o && !sbus_hresp_s_o && TRAM_CE && 
        TRAM_BWE == 4'h0 && 
        TRAM_A == $past((sbus_haddr_s_i[SRAM_AWIDTH-1:2]),2) && 
        state_o == SB_READ_W &&
        !skid_state);
    endproperty
    
    property p_item_6_3;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (!te_req && 
        state_o == SB_READ_W) |->
        ##1
        (sbus_hready_s_o && !sbus_hresp_s_o && !TRAM_CE &&
        sbus_hrdata_s_o == TRAM_Q && 
        state_o == SB_READ_D &&
        !skid_state);
    endproperty
    
    property p_item_7_1;
    @( posedge clk_i ) disable iff (rst_ni == 0)
        (!te_req &&
        !mode_sbus_require_dbgpriv_i &&
        // sbus_req && !sbus_hwrite_s_i && sbus_hauser_s_i[0] && sbus_hsize_s_i[1:0] == 2'b00 &&
        sbus_req && !sbus_hwrite_s_i && sbus_hauser_s_i[0] &&
        state_o == IDLE) 
        ##1 (te_req && !sbus_req) |->
        (TRAM_CE &&
        TRAM_BWE == 4'h0 && 
        TRAM_A == $past(sbus_haddr_s_i[SRAM_AWIDTH-1:2]) &&
        !sbus_hready_s_o && !sbus_hresp_s_o &&
        state_o == SB_READ_W)
        ##1
        (sbus_hready_s_o && !sbus_hresp_s_o && TRAM_CE && 
        TRAM_BWE == 4'hf && 
        TRAM_A == $past(te_haddr_s_i[SRAM_AWIDTH-1:2]) && 
        TRAM_D == te_hwdata_s_i &&
        state_o == TE_WRITE_D_SB_READ_D &&
        sbus_hrdata_s_o == TRAM_Q);
    endproperty
    
    a_item_6_1                : assert property (p_item_6_1) else $display("Simulation is stopped by %m FAIL");
    a_item_6_2                : assert property (p_item_6_2) else $display("Simulation is stopped by %m FAIL");
    a_item_6_3                : assert property (p_item_6_3) else $display("Simulation is stopped by %m FAIL");
    a_item_7_1                : assert property (p_item_7_1) else $display("Simulation is stopped by %m FAIL");
    
`endif

  task automatic reset_bus();
    te_haddr_s_i='0;
    te_hburst_s_i=3'b000;
    te_hmastlock_s_i=1'b0;
    te_hprot_s_i=4'h0;
    te_hsize_s_i=3'd2;
    te_htrans_s_i=2'b00;
    te_hwrite_s_i=1'b0;
    te_hwdata_s_i='0;
    te_hauser_s_i='0;

    sbus_haddr_s_i='0;
    sbus_hburst_s_i=3'b000;
    sbus_hmastlock_s_i=1'b0;
    sbus_hprot_s_i=4'h0;
    sbus_hsize_s_i=3'd2;
    sbus_htrans_s_i=2'b00;
    sbus_hwrite_s_i=1'b0;
    sbus_hwdata_s_i='0;
    sbus_hsel_s_i=1'b0;
    sbus_hauser_s_i='0;    
  endtask


///////////////////////////////////////////////////
    // clocking te_cb@(posedge clk_i);
    //     default input  #0;
    //     input te_haddr_s_i;   
    //     input te_hburst_s_i;   
    //     input te_hmastlock_s_i;
    //     input te_hprot_s_i;
    //     input te_hsize_s_i;    
    //     input te_htrans_s_i;   
    //     input te_hwrite_s_i;   
    //     input te_hwdata_s_i;   
    //     input te_hready_s_i;   
    //     input te_hauser_s_i;   

    //     input te_hrdata_s_o;   
    //     input te_hready_s_o;   
    //     input te_hresp_s_o;
    // endclocking

    //     logic cb_te_haddr_s_i;   
    //     logic cb_te_hburst_s_i;   
    //     logic cb_te_hmastlock_s_i;
    //     logic cb_te_hprot_s_i;
    //     logic cb_te_hsize_s_i;    
    //     logic cb_te_htrans_s_i;   
    //     logic cb_te_hwrite_s_i;   
    //     logic cb_te_hwdata_s_i;   
    //     logic cb_te_hready_s_i;   
    //     logic cb_te_hauser_s_i;   
        
    //     logic cb_te_hrdata_s_o;   
    //     logic cb_te_hready_s_o;   
    //     logic cb_te_hresp_s_o;
        
    //     assign cb_te_haddr_s_i = te_cb.te_haddr_s_i;   
    //     assign cb_te_hburst_s_i = te_cb.te_hburst_s_i;   
    //     assign cb_te_hmastlock_s_i = te_cb.te_hmastlock_s_i;
    //     assign cb_te_hprot_s_i = te_cb.te_hprot_s_i;
    //     assign cb_te_hsize_s_i = te_cb.te_hsize_s_i;    
    //     assign cb_te_htrans_s_i = te_cb.te_htrans_s_i;   
    //     assign cb_te_hwrite_s_i = te_cb.te_hwrite_s_i;   
    //     assign cb_te_hwdata_s_i = te_cb.te_hwdata_s_i;   
    //     assign cb_te_hready_s_i = te_cb.te_hready_s_i;   
    //     assign cb_te_hauser_s_i = te_cb.te_hauser_s_i;   

    //     assign cb_te_hrdata_s_o = te_cb.te_hrdata_s_o;   
    //     assign cb_te_hready_s_o = te_cb.te_hready_s_o;   
    //     assign cb_te_hresp_s_o = te_cb.te_hresp_s_o;
        
    // clocking sbus_cb@(posedge clk_i);
    //     default input #0;
    //     input sbus_haddr_s_i;
    //     input sbus_hburst_s_i;
    //     input sbus_hmastlock_s_i;
    //     input sbus_hprot_s_i;
    //     input sbus_hsize_s_i;
    //     input sbus_htrans_s_i;
    //     input sbus_hwrite_s_i;
    //     input sbus_hwdata_s_i;
    //     input sbus_hready_s_i;
    //     input sbus_hsel_s_i;
    //     input sbus_hauser_s_i;
    //     input sbus_hrdata_s_o;
    //     input sbus_hready_s_o;
    //     input sbus_hresp_s_o;
    //     input mode_sbus_require_dbgpriv_i;
    // endclocking

    // logic cb_sbus_haddr_s_i;
    // logic cb_sbus_hburst_s_i;
    // logic cb_sbus_hmastlock_s_i;
    // logic cb_sbus_hprot_s_i;
    // logic cb_sbus_hsize_s_i;
    // logic cb_sbus_htrans_s_i;
    // logic cb_sbus_hwrite_s_i;
    // logic cb_sbus_hwdata_s_i;
    // logic cb_sbus_hready_s_i;
    // logic cb_sbus_hsel_s_i;
    // logic cb_sbus_hauser_s_i;
    // logic cb_sbus_hrdata_s_o;
    // logic cb_sbus_hready_s_o;
    // logic cb_sbus_hresp_s_o;
    // logic cb_mode_sbus_require_dbgpriv_i;
    
    // assign cb_sbus_haddr_s_i = sbus_cb.sbus_haddr_s_i;
    // assign cb_sbus_hburst_s_i = sbus_cb.sbus_hburst_s_i;
    // assign cb_sbus_hmastlock_s_i = sbus_cb.sbus_hmastlock_s_i;
    // assign cb_sbus_hprot_s_i = sbus_cb.sbus_hprot_s_i;
    // assign cb_sbus_hsize_s_i = sbus_cb.sbus_hsize_s_i;
    // assign cb_sbus_htrans_s_i = sbus_cb.sbus_htrans_s_i;
    // assign cb_sbus_hwrite_s_i = sbus_cb.sbus_hwrite_s_i;
    // assign cb_sbus_hwdata_s_i = sbus_cb.sbus_hwdata_s_i;
    // assign cb_sbus_hready_s_i = sbus_cb.sbus_hready_s_i;
    // assign cb_sbus_hsel_s_i = sbus_cb.sbus_hsel_s_i;
    // assign cb_sbus_hauser_s_i = sbus_cb.sbus_hauser_s_i;
    // assign cb_sbus_hrdata_s_o = sbus_cb.sbus_hrdata_s_o;
    // assign cb_sbus_hready_s_o = sbus_cb.sbus_hready_s_o;
    // assign cb_sbus_hresp_s_o = sbus_cb.sbus_hresp_s_o;
    // assign cb_mode_sbus_require_dbgpriv_i = sbus_cb.mode_sbus_require_dbgpriv_i;

    // clocking sram_cb@(posedge clk_i);
    //     default input #0;
    //     input TRAM_CE;
    //     input TRAM_BWE;
    //     input TRAM_A;
    //     input TRAM_D;
    //     input TRAM_Q;
    // endclocking
    
    // logic cb_TRAM_CE;
    // logic cb_TRAM_BWE;
    // logic cb_TRAM_A;
    // logic cb_TRAM_D;
    // logic cb_TRAM_Q;
    
    // assign cb_TRAM_CE = sram_cb.TRAM_CE;
    // assign cb_TRAM_BWE = sram_cb.TRAM_BWE;
    // assign cb_TRAM_A = sram_cb.TRAM_A;
    // assign cb_TRAM_D = sram_cb.TRAM_D;
    // assign cb_TRAM_Q = sram_cb.TRAM_Q;

endinterface