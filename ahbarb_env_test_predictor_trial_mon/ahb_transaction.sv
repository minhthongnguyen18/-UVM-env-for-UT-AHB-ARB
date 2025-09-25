class ahb_transaction extends uvm_sequence_item;
    //Declare transactions fields
    rand src_e          src_i              ;
    
    rand bit            te_hauser          ;
    rand bit [31:0]     te_haddr           ;
    rand bit [31:0]     te_hwdata          ;
    rand bit [2:0]      te_hsize           ;
    rand bit            te_hwrite          ;
    rand bit [1:0]      te_htrans          ;
    rand bit            te_hready_i        ;

    rand bit [2:0]      sbus_hsize         ;
    rand bit            sbus_hwrite        ; //1 = write, 0 = read
    rand bit            sbus_hauser        ;
    rand bit [31:0]     sbus_haddr         ;
    rand bit [31:0]     sbus_hwdata        ;
    rand bit [1:0]      sbus_htrans        ;
    rand bit            sbus_hready_i      ;
    rand bit            sbus_hsel          ;
    rand bit            mode_sbus          ;
    rand bit [31:0]     sram_rdata         ;
    
    bit [31:0]          te_hrdata          ;
    bit                 te_hready_o        ;
    bit                 te_hresp           ;

    bit [31:0]          sbus_hrdata        ;
    bit                 sbus_hready_o      ;
    bit                 sbus_hresp         ;
    
    bit                 sram_ce            ;
    bit [3:0]           sram_bwe           ;
    bit [31:0]          sram_addr          ;
    bit [31:0]          sram_wdata         ;

    bit                 last_sbus_hready_o ;
    bit                 last_sbus_hresp    ;
    
    bit                 last_sram_ce       ;
    bit [3:0]           last_sram_bwe      ;
    bit [31:0]          last_sram_addr     ;
    bit [31:0]          last_sram_wdata    ;
     
    bit [3:0]           state              ;
    bit                 skid_en            ;
    
    `uvm_object_utils_begin(ahb_transaction)
        `uvm_field_enum ( src_e, src_i          , UVM_ALL_ON )
        `uvm_field_int  ( te_hauser             , UVM_ALL_ON )
        `uvm_field_int  ( te_haddr              , UVM_ALL_ON )
        `uvm_field_int  ( te_hwdata             , UVM_ALL_ON )
        `uvm_field_int  ( te_hsize              , UVM_ALL_ON )
        `uvm_field_int  ( te_hwrite             , UVM_ALL_ON )
        `uvm_field_int  ( te_htrans             , UVM_ALL_ON )
        `uvm_field_int  ( te_hready_i           , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hsize            , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hwrite           , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hauser           , UVM_ALL_ON )
        `uvm_field_int  ( sbus_haddr            , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hwdata           , UVM_ALL_ON )
        `uvm_field_int  ( sbus_htrans           , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hready_i         , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hsel             , UVM_ALL_ON )
        `uvm_field_int  ( mode_sbus             , UVM_ALL_ON )
        `uvm_field_int  ( sram_rdata            , UVM_ALL_ON )
        `uvm_field_int  ( te_hrdata             , UVM_ALL_ON )
        `uvm_field_int  ( te_hready_o           , UVM_ALL_ON )
        `uvm_field_int  ( te_hresp              , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hrdata           , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hready_o         , UVM_ALL_ON )
        `uvm_field_int  ( sbus_hresp            , UVM_ALL_ON )
        `uvm_field_int  ( sram_ce               , UVM_ALL_ON )
        `uvm_field_int  ( sram_bwe              , UVM_ALL_ON )
        `uvm_field_int  ( sram_addr             , UVM_ALL_ON )
        `uvm_field_int  ( sram_wdata            , UVM_ALL_ON )
        `uvm_field_int  ( last_sram_ce          , UVM_ALL_ON )
        `uvm_field_int  ( last_sram_bwe         , UVM_ALL_ON )
        `uvm_field_int  ( last_sram_addr        , UVM_ALL_ON )
        `uvm_field_int  ( last_sram_wdata       , UVM_ALL_ON )
        `uvm_field_int  ( last_sbus_hready_o    , UVM_ALL_ON )
        `uvm_field_int  ( last_sbus_hresp       , UVM_ALL_ON )
        `uvm_field_int  ( state                 , UVM_ALL_ON )
        `uvm_field_int  ( skid_en               , UVM_ALL_ON )
    `uvm_object_utils_end
    
    //Contructor
    function new(string name = "ahb_transaction");
        super.new();
    endfunction
    
    constraint common_constraint {
        te_hwrite         == 1'b1;
        te_hauser         == 1'b1;
        te_hsize          == 3'h2;
        te_haddr[31:10]   == 20'h0;
        te_haddr[1:0]     == 2'h0;
        te_htrans   inside {HTRANS_NONSEQ, HTRANS_IDLE};
        sbus_htrans inside {HTRANS_NONSEQ, HTRANS_IDLE};
        sbus_haddr[31:10] == 20'h0;
        sbus_hsize inside {0,2};
    }

endclass