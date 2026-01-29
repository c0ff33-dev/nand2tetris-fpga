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

    // No need to implement this chip
    assign out = sel?b:a;

endmodule
