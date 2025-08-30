///////////////////////////////////////////////////////////////////////////////////////////////// 
// File:  ahblite_pkg.sv
// Date:   15.7.2022
// Version    Date           Author           Description 
// v0.0       2022.07.15     DienHoang        New creation for AHB protocol parameter define library 
//
// Description: Define all parameter that need for AHB protocol
/////////////////////////////////////////////////////////////////////////////////////////////////

package ahblite_pkg;
  //HTRANS
  localparam logic [1:0] HTRANS_IDLE   = 2'b00;
  localparam logic [1:0] HTRANS_BUSY   = 2'b01;
  localparam logic [1:0] HTRANS_NONSEQ = 2'b10;
  localparam logic [1:0] HTRANS_SEQ    = 2'b11;

  //HSIZE
  localparam logic [2:0] HSIZE_B8    = 3'b000;
  localparam logic [2:0] HSIZE_B16   = 3'b001;
  localparam logic [2:0] HSIZE_B32   = 3'b010;
  localparam logic [2:0] HSIZE_B64   = 3'b011;
  localparam logic [2:0] HSIZE_B128  = 3'b100; //4-word line
  localparam logic [2:0] HSIZE_B256  = 3'b101; //8-word line
  localparam logic [2:0] HSIZE_B512  = 3'b110;
  localparam logic [2:0] HSIZE_B1024 = 3'b111;
  localparam logic [2:0] HSIZE_BYTE  = HSIZE_B8;
  localparam logic [2:0] HSIZE_HWORD = HSIZE_B16;
  localparam logic [2:0] HSIZE_WORD  = HSIZE_B32;
  localparam logic [2:0] HSIZE_DWORD = HSIZE_B64;

  //HBURST
  localparam logic [2:0] HBURST_SINGLE = 3'b000;
  localparam logic [2:0] HBURST_INCR   = 3'b001;
  localparam logic [2:0] HBURST_WRAP4  = 3'b010;
  localparam logic [2:0] HBURST_INCR4  = 3'b011;
  localparam logic [2:0] HBURST_WRAP8  = 3'b100;
  localparam logic [2:0] HBURST_INCR8  = 3'b101;
  localparam logic [2:0] HBURST_WRAP16 = 3'b110;
  localparam logic [2:0] HBURST_INCR16 = 3'b111;

  //HPROT
  localparam logic [3:0] HPROT_OPCODE         = 4'b0000;
  localparam logic [3:0] HPROT_DATA           = 4'b0001;
  localparam logic [3:0] HPROT_USER           = 4'b0000;
  localparam logic [3:0] HPROT_PRIVILEGED     = 4'b0010;
  localparam logic [3:0] HPROT_NON_BUFFERABLE = 4'b0000;
  localparam logic [3:0] HPROT_BUFFERABLE     = 4'b0100;
  localparam logic [3:0] HPROT_NON_CACHEABLE  = 4'b0000;
  localparam logic [3:0] HPROT_CACHEABLE      = 4'b1000;

  //HRESP
  localparam logic       HRESP_OKAY  = 1'b0;
  localparam logic       HRESP_ERROR = 1'b1;
  
  typedef enum {SRC_TE, SRC_SBUS} src_e;

endpackage
