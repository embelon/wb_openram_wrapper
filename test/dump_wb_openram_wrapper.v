module dump();
	initial begin
		$dumpfile ("wb_openram_wrapper.vcd");
		$dumpvars (0, wb_openram_wrapper);
		#1;
	end
endmodule
