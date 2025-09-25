class te_sequencer extends uvm_sequencer#(ahb_transaction);
    `uvm_component_utils(te_sequencer)
    
    function
        new(string name = "te_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

class sbus_sequencer extends uvm_sequencer#(ahb_transaction);
    `uvm_component_utils(sbus_sequencer)
    
    function
        new(string name = "sbus_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction
endclass