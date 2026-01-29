/** 
 * Multiplexor:
 * out = a if sel == 0
 *       b otherwise
 */

`default_nettype none
module Mux(
    input a,
    input b,
    input sel,
    output out
);

    // Put your code here:
    // condition ? value_if_true : value_if_false
    assign out = sel ? b : a;

endmodule
