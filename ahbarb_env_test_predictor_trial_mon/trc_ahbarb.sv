////--------------------------------------------------------------------------------------------- 
//  File name:   trc_ahbarb.sv
//
//  Version    Date           Author           Description
//  v0.1       2023.04.09     ThinhNguyen2     Fist creation for dm_arb.
//  v0.2       2023.05.10     ThinhNguyen2     Update after internal review - RVC:
//                                              -Remove port te_hsel_s_i
//                                              -Update port TRAM_WE to TRAM_BWE[3:0]
//  v0.3       2023.05.15     ThinhNguyen2     Update after the 1st review with REL.
//                                              -Remove port sbus_require_priv_i
//                                              -Add input port trc_sbus_dbgmd_i
//                                              -Add skid buffer
//  v0.4       2023.05.16     ThinhNguyen2     Remove ERROR case of misalign access.
//                                             Add enable gate for skid buffer FF
//  v0.5       2023.05.17     ThinhNguyen2     Change mode signal and its function.
//                                             Update PARAMETER.
//  v0.6       2023.05.22     ThinhNguyen2     Update since FSM was used instead of normal logic.
//  v0.7       2023.06.29     ThinhNguyen2     Add FFs for ahb_bwe and ahb_addr (update FSM).
//  v0.8       2023.08.09     ThinhNguyen2     Change parameter SRAM_AWIDTH to 10.
//  v0.9       2023.11.28     ThinhNguyen2     Power optimization.
//                                            
//
////--------------------------------------------------------------------------------------------- 
//  Description: AHB Arbiter - recieve AHB request from SRAM SINK and System Bus 
//               then select and foward them to SRAM in SRAM IF.
// 
////--------------------------------------------------------------------------------------------- 

module trc_ahbarb #(
    parameter int           SLAVE_SIDEB     = 1,
    parameter int           AHB_AWIDTH      = 32,      
    parameter int           AHB_DWIDTH      = 32,      
    parameter int           SRAM_AWIDTH      = 10,      
    parameter int           SRAM_DWIDTH      = 32
)(
    input  logic                             clk_i,       // Clock
    input  logic                             rst_ni,      // debug module reset

    //AHB Lite Slave System Bus IF - TE Interface
    input  logic [AHB_AWIDTH-1:0]   te_haddr_s_i,               // Address access
    input  logic [2:0]              te_hburst_s_i,              // SINGLE is only support: Fix0
    input  logic                    te_hmastlock_s_i,           // Not support slave MasterLock: Fix to 0
    input  logic [3:0]              te_hprot_s_i,               // AHB slave protect: Fix0
    input  logic [2:0]              te_hsize_s_i,               // Only word access
    input  logic [1:0]              te_htrans_s_i,              // BUSY and SEQUENTIAL are not supported because master support SINGLE only 
    input  logic                    te_hwrite_s_i,              // 1: write, 0: read
    input  logic [AHB_DWIDTH-1:0]   te_hwdata_s_i,              // Write data
    input  logic                    te_hready_s_i,              // Ready: fix 1
    input  logic [SLAVE_SIDEB-1:0]  te_hauser_s_i,              // bit0: Debug mode; Others are reserved
    output logic [AHB_DWIDTH-1:0]   te_hrdata_s_o,              // Read data
    output logic                    te_hready_s_o,           // A transfer has finished: fix 1
    output logic                    te_hresp_s_o,               // Transfer response: fix 0

    //AHB Lite Slave System Bus IF - System Bus Interface
    input  logic [AHB_AWIDTH-1:0]   sbus_haddr_s_i,               // Address access
    input  logic [2:0]              sbus_hburst_s_i,              // Slave Busrt 
    input  logic                    sbus_hmastlock_s_i,           // Slave Master Lock
    input  logic [3:0]              sbus_hprot_s_i,               // AHB slave protect
    input  logic [2:0]              sbus_hsize_s_i,               // Byte, hword, word are supported
    input  logic [1:0]              sbus_htrans_s_i,              // BUSY and SEQUENTIAL are not supported because master support SINGLE only
    input  logic                    sbus_hwrite_s_i,              // 1: write, 0: read
    input  logic [AHB_DWIDTH-1:0]   sbus_hwdata_s_i,              // Write data
    input  logic                    sbus_hready_s_i,              // Ready
    input  logic                    sbus_hsel_s_i,                // AHB slave select
    input  logic [SLAVE_SIDEB-1:0]  sbus_hauser_s_i,              // Bit0: Debug mode; Others are reserved
    output logic [AHB_DWIDTH-1:0]   sbus_hrdata_s_o,              // Read data
    output logic                    sbus_hready_s_o,              // A transfer has finished
    output logic                    sbus_hresp_s_o,               // Transfer response

    //SRAM IF
    output logic                    TRAM_CE,      //Chip select
    output logic [3:0]              TRAM_BWE,     //Write Enable
    output logic [SRAM_AWIDTH-1:2]  TRAM_A,       //Address
    output logic [SRAM_DWIDTH-1:0]  TRAM_D,       //Write data
    input  logic [SRAM_DWIDTH-1:0]  TRAM_Q,       //Read data
    
    //Mode IF
    input  logic           mode_sbus_require_dbgpriv_i //Mode signal
    
);
    
    //--Internal signal
    //AHB request
    logic                           sbus_req;
    logic                           te_req;
    //skid buffer
    logic                           skid_state;  //1: buffer full, 0: buffer empty
    logic                           skid_state_next;  
    logic                           skid_enable;
    logic [2:0]                     skbf_size;
    logic                           skbf_write;
    logic [SLAVE_SIDEB-1:0]         skbf_auser;
    logic [AHB_AWIDTH-1:0]          skbf_addr;
    logic [2:0]                     ahb_size;
    logic                           ahb_write;
    logic [SLAVE_SIDEB-1:0]         ahb_auser;
    logic [AHB_AWIDTH-1:0]          ahb_addr;
    logic [AHB_AWIDTH-1:0]          ahb_addr_q;
    logic                           ahb_req;
    //AHB error
    logic                           ahb_error_d;
    //Byte Write Enable
    logic [3:0]                     ahb_bwe;
    logic [3:0]                     ahb_bwe_q;
    //FSM
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
    fsm_state                       state_next;
    fsm_state                       state;
    
    //Power
    logic                           state_reg_EN;

    //------------------------------------------------//
    //--TE IF output signal
    //------------------------------------------------//
    assign te_hresp_s_o = 1'b0;
    assign te_hrdata_s_o = 32'h0;
    assign te_hready_s_o = 1'b1;
    //------------------------------------------------//
    //--AHB request
    //------------------------------------------------//
    assign sbus_req = sbus_hready_s_i & sbus_hsel_s_i & ((sbus_htrans_s_i == 2'b10) | (sbus_htrans_s_i == 2'b11));
    assign te_req = te_hready_s_i & (te_htrans_s_i == 2'b10 | te_htrans_s_i == 2'b11);
    assign skid_state_next = (sbus_req & te_req) | (te_req & skid_state); 
    assign ahb_req = te_req | sbus_req | skid_state;
    
    //Power - EN signal
    assign state_reg_EN = state != IDLE | te_req | sbus_req;

    //Generate skid buffer request  
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            skid_state <= 1'b0;
        end
        else if (state_reg_EN) begin
            skid_state <= skid_state_next;
        end
    end
    
    //Skid buffer data storage  
    assign skid_enable = te_req & sbus_req & !skid_state;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            skbf_size  <= 3'h0;  
            skbf_write <= 1'h0; 
            skbf_auser <= {SLAVE_SIDEB{1'b0}}; 
            skbf_addr  <= {AHB_AWIDTH{1'b0}};
        end
        else if (skid_enable) begin
            skbf_size  <= sbus_hsize_s_i;  
            skbf_write <= sbus_hwrite_s_i; 
            skbf_auser <= sbus_hauser_s_i; 
            skbf_addr  <= sbus_haddr_s_i;
        end
    end
    
    //Generate AHB data in address phase
    always_comb begin
        case ({te_req, sbus_req, skid_state})
            3'b000: begin
                    ahb_size  = 3'h0;            
                    ahb_write = 1'h0; 
                    ahb_auser = {SLAVE_SIDEB{1'b0}};
                    ahb_addr  = {AHB_AWIDTH{1'b0}};
                end//statement 0
            3'b001: begin
                    ahb_size  = skbf_size; 
                    ahb_write = skbf_write;
                    ahb_auser = skbf_auser;
                    ahb_addr  = skbf_addr; 
                end//statement 1
            3'b010: begin
                    ahb_size  = sbus_hsize_s_i;
                    ahb_write = sbus_hwrite_s_i;
                    ahb_auser = sbus_hauser_s_i;
                    ahb_addr  = sbus_haddr_s_i;
                end//statement 2
            3'b011: begin
                    ahb_size  = skbf_size; 
                    ahb_write = skbf_write;
                    ahb_auser = skbf_auser;
                    ahb_addr  = skbf_addr; 
                end//statement 3
            3'b100: begin
                    ahb_size  = te_hsize_s_i;
                    ahb_write = te_hwrite_s_i;
                    ahb_auser = te_hauser_s_i;
                    ahb_addr  = te_haddr_s_i;
                end//statement 4
            3'b101: begin
                    ahb_size  = te_hsize_s_i;  
                    ahb_write = te_hwrite_s_i; 
                    ahb_auser = te_hauser_s_i; 
                    ahb_addr  = te_haddr_s_i;
                end//statement 5
            3'b110: begin
                    ahb_size  = te_hsize_s_i;
                    ahb_write = te_hwrite_s_i;
                    ahb_auser = te_hauser_s_i;
                    ahb_addr  = te_haddr_s_i;
                end//statement 6
            3'b111: begin
                    ahb_size  =  te_hsize_s_i;
                    ahb_write =  te_hwrite_s_i;
                    ahb_auser =  te_hauser_s_i;
                    ahb_addr  =  te_haddr_s_i;
                end//statement 7
            default: begin//All case is covered by case items
                    ahb_size  = 3'hX;            
                    ahb_write = 1'hX; 
                    ahb_auser = {SLAVE_SIDEB{1'bX}};
                    ahb_addr  = {AHB_AWIDTH{1'bX}};
                end//statement 7
        endcase
    end//end always_comb

    //FF of ahb_addr
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ahb_addr_q  <= {AHB_AWIDTH{1'b0}};
        end
        else if (ahb_req && !ahb_error_d) begin
            ahb_addr_q <= ahb_addr;
        end
    end

    //ByteWriteEnable logic
    always_comb begin
        case ({ahb_write,ahb_size[1:0], ahb_addr[1:0]})
            ////Read access
            //Access BYTE
            5'b00000: ahb_bwe = 4'b0000;
            5'b00001: ahb_bwe = 4'b0000;
            5'b00010: ahb_bwe = 4'b0000;
            5'b00011: ahb_bwe = 4'b0000;
            //Access HALFWORD
            5'b00100: ahb_bwe = 4'b0000;
            5'b00101: ahb_bwe = 4'b0000;
            5'b00110: ahb_bwe = 4'b0000;
            5'b00111: ahb_bwe = 4'b0000;
            //Access WORD
            5'b01000: ahb_bwe = 4'b0000;
            5'b01001: ahb_bwe = 4'b0000;
            5'b01010: ahb_bwe = 4'b0000;
            5'b01011: ahb_bwe = 4'b0000;
            //Access DOUBLEWORD
            5'b01100: ahb_bwe = 4'b0000;
            5'b01101: ahb_bwe = 4'b0000;
            5'b01110: ahb_bwe = 4'b0000;
            5'b01111: ahb_bwe = 4'b0000;

            ////Write access
            //Access BYTE
            5'b10000: ahb_bwe = 4'b0001;
            5'b10001: ahb_bwe = 4'b0010;
            5'b10010: ahb_bwe = 4'b0100;
            5'b10011: ahb_bwe = 4'b1000;
            //Access HALFWORD
            5'b10100: ahb_bwe = 4'b0011;
            5'b10101: ahb_bwe = 4'b0011;
            5'b10110: ahb_bwe = 4'b1100;
            5'b10111: ahb_bwe = 4'b1100;
            //Access WORD
            5'b11000: ahb_bwe = 4'b1111;
            5'b11001: ahb_bwe = 4'b1111;
            5'b11010: ahb_bwe = 4'b1111;
            5'b11011: ahb_bwe = 4'b1111;
            //Access DOUBLEWORD
            5'b11100: ahb_bwe = 4'b1111;
            5'b11101: ahb_bwe = 4'b1111;
            5'b11110: ahb_bwe = 4'b1111;
            5'b11111: ahb_bwe = 4'b1111;
            default:  ahb_bwe = 4'hX; //All case is covered by case items
        endcase
    end//always_comb

    //FF of ahb_bwe
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ahb_bwe_q  <= 4'h0;
        end
        else if (ahb_req && !ahb_error_d) begin
            ahb_bwe_q <= ahb_bwe;
        end
    end

    //Generate error signal
    assign ahb_error_d = mode_sbus_require_dbgpriv_i & !ahb_auser & ahb_req;

    //--------------------------------------------------------------------------------------------------
    //--FSM
    //--------------------------------------------------------------------------------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            state <= IDLE;
        end
        else if (state_reg_EN) begin
            state <= state_next;
        end
    end// always_ff

    //State transition
    always_comb begin
        // state_next = state;
        case (state)
            IDLE, 
            SB_WRITE_D,
            SB_READ_D,
            SB_ERROR_D,
            TE_WRITE_D,
            TE_WRITE_D_SB_READ_D,
            TE_WRITE_D_SB_ERROR_D:  
                    begin
                        case ({te_req,  sbus_req,   ahb_error_d,    ahb_write})
                            4'b0000: state_next = IDLE;
                            4'b0001: state_next = IDLE;
                            4'b0010: state_next = IDLE;
                            4'b0011: state_next = IDLE;
                            4'b0100: state_next = SB_READ_W;
                            4'b0101: state_next = SB_WRITE_D;
                            4'b0110: state_next = SB_ERROR_W;
                            4'b0111: state_next = SB_ERROR_W;
                            4'b1000: state_next = TE_WRITE_D;
                            4'b1001: state_next = TE_WRITE_D;
                            4'b1010: state_next = TE_WRITE_D;
                            4'b1011: state_next = TE_WRITE_D;
                            4'b1100: state_next = TE_WRITE_D_SB_SKID_W;
                            4'b1101: state_next = TE_WRITE_D_SB_SKID_W;
                            4'b1110: state_next = TE_WRITE_D_SB_SKID_W;
                            4'b1111: state_next = TE_WRITE_D_SB_SKID_W;
                            default: ;
                        endcase
                    end//Statement 0
            SB_ERROR_W:
                    begin
                        if (!te_req)
                            state_next = SB_ERROR_D;
                        else 
                            state_next = TE_WRITE_D_SB_ERROR_D;
                    end//Statement 1
            TE_WRITE_D_SB_SKID_W:
                    begin
                        case ({te_req,  ahb_error_d,    ahb_write})
                            3'b000: state_next = SB_READ_W;
                            3'b001: state_next = SB_WRITE_D;
                            3'b010: state_next = SB_ERROR_W;
                            3'b011: state_next = SB_ERROR_W;
                            3'b100: state_next = TE_WRITE_D_SB_SKID_W;
                            3'b101: state_next = TE_WRITE_D_SB_SKID_W;
                            3'b110: state_next = TE_WRITE_D_SB_SKID_W;
                            3'b111: state_next = TE_WRITE_D_SB_SKID_W;
                            default: ;
                        endcase
                    end//Statement 2
            SB_READ_W:
                    begin
                        if (te_req)
                            state_next = TE_WRITE_D_SB_READ_D;
                        else
                            state_next = SB_READ_D;
                    end//Statement 3
            default : state_next = IDLE;
        endcase
    end// always_comb

    //Output control in each state
    always_comb begin
        case (state)
            IDLE:
                begin
                    sbus_hready_s_o = 1'b1;
                    sbus_hresp_s_o = 1'b0;
                    TRAM_CE = 1'b0;
                    //D.C
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'b0}};
                    TRAM_BWE = 4'h0;
                    TRAM_D = {SRAM_DWIDTH{1'b0}};
                    TRAM_A = {(SRAM_AWIDTH-2){1'b0}};
                end//statement 0
            SB_ERROR_W:
                begin
                    sbus_hready_s_o = 1'b0;
                    sbus_hresp_s_o = 1'b1;
                    TRAM_CE = 1'b0;
                    //D.C
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'b0}};
                    TRAM_BWE = 4'h0;
                    TRAM_D = {SRAM_DWIDTH{1'b0}};
                    TRAM_A = {(SRAM_AWIDTH-2){1'b0}};
                end//statement 1
            SB_ERROR_D:
                begin
                    sbus_hready_s_o = 1'b1;
                    sbus_hresp_s_o = 1'b1;
                    TRAM_CE = 1'b0;
                    //D.C
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'b0}};
                    TRAM_BWE = 4'h0;
                    TRAM_D = {SRAM_DWIDTH{1'b0}};
                    TRAM_A = {(SRAM_AWIDTH-2){1'b0}};
                end//statement 2
            TE_WRITE_D_SB_ERROR_D:
                begin
                    sbus_hready_s_o = 1'b1;
                    sbus_hresp_s_o = 1'b1;
                    TRAM_CE = 1'b1;
                    TRAM_BWE = ahb_bwe_q;
                    TRAM_D = te_hwdata_s_i;
                    TRAM_A = ahb_addr_q[SRAM_AWIDTH -1:2];
                    //D.C
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'b0}};
                end//statement 3
            SB_WRITE_D:
                begin
                    sbus_hready_s_o = 1'b1;
                    sbus_hresp_s_o = 1'b0;
                    // sbus_hresp_s_o = 1'b1;
                    TRAM_CE = 1'b1;
                    TRAM_BWE = ahb_bwe_q;
                    TRAM_D = sbus_hwdata_s_i;
                    TRAM_A = ahb_addr_q[SRAM_AWIDTH -1:2];
                    //D.C
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'b0}};
                end//statement 4
            TE_WRITE_D_SB_SKID_W:
                begin
                    sbus_hready_s_o = 1'b0;
                    sbus_hresp_s_o = 1'b0;
                    TRAM_CE = 1'b1;
                    TRAM_BWE = ahb_bwe_q;
                    TRAM_D = te_hwdata_s_i;
                    TRAM_A = ahb_addr_q[SRAM_AWIDTH -1:2];
                    //D.C
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'b0}};
                end//statement 5
            SB_READ_W:
                begin
                    sbus_hready_s_o = 1'b0;
                    sbus_hresp_s_o = 1'b0;
                    TRAM_CE = 1'b1;
                    TRAM_BWE = ahb_bwe_q;
                    TRAM_A = ahb_addr_q[SRAM_AWIDTH -1:2];
                    //D.C
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'b0}};
                    TRAM_D = {SRAM_DWIDTH{1'b0}};
                end//statement 6
            TE_WRITE_D_SB_READ_D:
                begin
                    sbus_hready_s_o = 1'b1;
                    sbus_hresp_s_o = 1'b0;
                    sbus_hrdata_s_o = TRAM_Q;
                    TRAM_CE = 1'b1;
                    TRAM_BWE = ahb_bwe_q;
                    TRAM_D = te_hwdata_s_i;
                    TRAM_A = ahb_addr_q[SRAM_AWIDTH -1:2];
                end//statement 7
            SB_READ_D:
                begin
                    sbus_hready_s_o = 1'b1;
                    sbus_hresp_s_o = 1'b0;
                    sbus_hrdata_s_o = TRAM_Q;
                    //D.C
                    TRAM_CE = 1'b0;
                    TRAM_BWE = 4'h0;
                    TRAM_D = {SRAM_DWIDTH{1'b0}};
                    TRAM_A = {(SRAM_AWIDTH-2){1'b0}};
                end//statement 8
            TE_WRITE_D:
                begin
                    sbus_hready_s_o = 1'b1;
                    sbus_hresp_s_o = 1'b0;
                    TRAM_CE = 1'b1;
                    TRAM_BWE = ahb_bwe_q;
                    TRAM_D = te_hwdata_s_i;
                    TRAM_A = ahb_addr_q[SRAM_AWIDTH -1:2];
                    //D.C
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'b0}};
                end//statement 9
            default: 
                begin
                    sbus_hready_s_o = 1'bX;
                    sbus_hresp_s_o = 1'bX;
                    sbus_hrdata_s_o = {AHB_DWIDTH{1'bX}};
                    TRAM_CE = 1'bX;
                    TRAM_BWE = 4'hX;
                    TRAM_D = {SRAM_DWIDTH{1'bX}};
                    TRAM_A = {(SRAM_AWIDTH-2){1'bX}};
                end
        endcase
    end//always_comb
endmodule
