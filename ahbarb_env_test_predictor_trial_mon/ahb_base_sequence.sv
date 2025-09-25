class ahb_base_sequence extends uvm_sequence #(ahb_transaction);
    `uvm_object_utils(ahb_base_sequence)
    
    function new(string name = "ahb_base_sequence");
        super.new(name);
    endfunction
endclass
