`include "neuron_define.v"
// `define SIM_MEM_INIT
// `define QUARTUS_SYN_INIT
// `define NULL 0
// `define DUMP_MEMORY


module StatusMem_FPGA
#(

	
	parameter STOP_STEP = 5,
	
	parameter NUM_NURNS = 256  ,
	parameter NUM_AXONS = 256  ,

	parameter DSIZE = 16 ,
	parameter WEIGHT_SIZE = 12,

	parameter NURN_CNT_BIT_WIDTH = 8 ,
	parameter AXON_CNT_BIT_WIDTH = 8 ,

	parameter STDP_WIN_BIT_WIDTH = 8,

    parameter DATA_BIT_WIDTH_INT = 8,
    parameter DATA_BIT_WIDTH_FRAC = 8 ,

	
	parameter X_ID = "1",
	parameter Y_ID = "1",
	parameter DIR_ID = {X_ID, "_", Y_ID},
	parameter SIM_PATH = "D:/code/data",
	parameter SYNTH_PATH = "D:/code/synth/data"

)
(
	input												start_i,
	input 												clk_i,
	input 												rst_n_i,
	input												ce,

	//read port A
	input [NURN_CNT_BIT_WIDTH-1:0] 					    Addr_StatRd_A_i,
	input 												read_enable_bias_i,
    input                                               read_enable_potential_i,
    input                                               read_enable_threshold_i,
    input                                               read_enable_posthistory_i,

    input [DSIZE-1:0]                                   data_wr_bias_i,
    input [DSIZE-1:0]                                   data_wr_potential_i,
    input [DSIZE-1:0]                                   data_wr_threshold_i,
    input [STDP_WIN_BIT_WIDTH-1:0]                      data_wr_posthistory_i,

    input                                               write_enable_bias_i,
    input                                               write_enable_potential_i,
    input                                               write_enable_threshold_i,
    input                                               write_enable_posthistory_i,

    output [DSIZE-1:0]                                  data_rd_bias_o,
    output [DSIZE-1:0]                                  data_rd_potential_o,
    output [DSIZE-1:0]                                  data_rd_threshold_o,
    output [STDP_WIN_BIT_WIDTH-1:0]                     data_rd_posthistory_o,

	input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_bias_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_potential_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_threshold_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						read_addr_posthistory_i,

	input [NURN_CNT_BIT_WIDTH-1:0]						write_addr_bias_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						write_addr_potential_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						write_addr_threshold_i,
	input [NURN_CNT_BIT_WIDTH-1:0]						write_addr_posthistory_i,

	//write port B
	input [NURN_CNT_BIT_WIDTH-1:0] 						Addr_StatWr_B_i,
	
	//read port C
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatRd_C_i,
	input 												rdEn_StatRd_C_i,

	output [STDP_WIN_BIT_WIDTH-1:0]						data_StatRd_C_o,

	//write port D
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatWr_D_i,
	input 												wrEn_StatWr_D_i,
	input [STDP_WIN_BIT_WIDTH-1:0]						data_StatWr_D_i,

	input [1:0]											Axon_scaling_i,
	
	//read port E
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatRd_E_i,
	input 												rdEn_StatRd_E_i,

	output [DSIZE-1:0]									data_StatRd_E_o,
	
	//read port F
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatRd_F_i,
	input 												rdEn_StatRd_F_i,

	output [DSIZE-1:0]									data_StatRd_F_o,

	//write port G
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatWr_G_i,
	input 												wrEn_StatWr_G_i,
	input [DSIZE-1:0]									data_StatWr_G_i,

	input 												en_config

);


	//MEMORY DECLARATION
        reg [DSIZE-1:0] 			 Mem_Bias           [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [DSIZE-1:0] 			 Mem_Potential      [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [DSIZE-1:0] 			 Mem_Threshold      [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PostHistory    [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        
		reg /*sparse*/ [STDP_WIN_BIT_WIDTH-1:0] Mem_PreHistory     [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];
        reg /*sparse*/ [DSIZE-1:0] 			 	Mem_Weight         [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];

    //initial memory
	`ifdef SIM_MEM_INIT
		reg [100*8:1] file_name;
		integer idx, file;
		reg [DSIZE-1:0] data;
		initial begin
			file_name = {SIM_PATH, "data", DIR_ID, "/Bias.txt"};				$readmemh (file_name,Mem_Bias);
			file_name = {SIM_PATH, "data", DIR_ID, "/MembPot.txt"};			    $readmemh (file_name,Mem_Potential);
			file_name = {SIM_PATH, "data", DIR_ID, "/Th.txt"};				    $readmemh (file_name,Mem_Threshold);
			file_name = {SIM_PATH, "data", DIR_ID, "/PostSpikeHistory.txt"};	$readmemh (file_name,Mem_PostHistory);
			file_name = {SIM_PATH, "data", DIR_ID, "/PreSpikeHistory.txt"}; 	$readmemh (file_name,Mem_PreHistory);
			file_name = {SIM_PATH, "data", DIR_ID, "/Weights.txt"};			    $readmemh (file_name,Mem_Weight);
            //file_name = {SIM_PATH, DIR_ID, "/Weights.txt"};			    $readmemh (file_name,Mem_Weight2);

		end
	`endif

    //read address registers
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_bias;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_potential;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_threshold;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_posthistory;
    reg [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]     read_address_register_prehistory;
    reg [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]     read_address_register_weight_E, read_address_register_weight_F;

	wire [DSIZE-1:0] data_StatRd_E, data_StatRd_F;
	reg fifo_write_enable;


	wire [DSIZE-1:0] weight_fifo_out;


    //memory bias
	always @(posedge clk_i)
        begin
	        if (read_enable_bias_i == 1'b1)
				read_address_register_bias <= read_addr_bias_i;
		    if (write_enable_bias_i == 1'b1)
				Mem_Bias[write_addr_bias_i] <= data_wr_bias_i;
        end
    assign data_rd_bias_o = Mem_Bias[read_address_register_bias];

    always @(posedge clk_i)
        begin
	        if (read_enable_potential_i == 1'b1)
				read_address_register_potential <= read_addr_potential_i;
		    if (write_enable_potential_i == 1'b1)
				Mem_Potential[write_addr_potential_i] <= data_wr_potential_i;
        end
    assign data_rd_potential_o = Mem_Potential[read_address_register_potential];

    always @(posedge clk_i)
        begin
	        if (read_enable_threshold_i == 1'b1)
				read_address_register_threshold <= read_addr_threshold_i;
		    if (write_enable_threshold_i == 1'b1)
				Mem_Threshold[write_addr_threshold_i] <= data_wr_threshold_i;
        end
    assign data_rd_threshold_o = Mem_Threshold[read_address_register_threshold];

    always @(posedge clk_i)
        begin
	        if (read_enable_posthistory_i == 1'b1)
				read_address_register_posthistory <= read_addr_posthistory_i;
		    if (write_enable_posthistory_i == 1'b1)
				Mem_PostHistory[write_addr_posthistory_i] <= data_wr_posthistory_i;
        end
    assign data_rd_posthistory_o = Mem_PostHistory[read_address_register_posthistory];


    always @(posedge clk_i)
        begin
	        if (rdEn_StatRd_C_i == 1'b1)
	            read_address_register_prehistory <= Addr_StatRd_C_i;
		    if (wrEn_StatWr_D_i == 1'b1)
			    Mem_PreHistory[Addr_StatWr_D_i] <= data_StatWr_D_i;
        end
    assign data_StatRd_C_o = Mem_PreHistory[read_address_register_prehistory];

    always @(posedge clk_i)
        begin
	        if (rdEn_StatRd_E_i == 1'b1)
	            read_address_register_weight_E <= Addr_StatRd_E_i;
		    if (wrEn_StatWr_G_i == 1'b1)
			    Mem_Weight[Addr_StatWr_G_i] <= data_StatWr_G_i;
        end
    assign data_StatRd_E = Mem_Weight[read_address_register_weight_E];
	assign data_StatRd_E_o = data_StatRd_E;


assign data_StatRd_F_o = weight_fifo_out;

always @(posedge clk_i or negedge rst_n_i)
	begin
		if (rst_n_i == 1'b0)
			fifo_write_enable <= 1'b0;
		else
			fifo_write_enable <= rdEn_StatRd_E_i;
	end

//fifo
generic_fifo_sc_b
#(
	.dw(DSIZE),
	.aw(9)
)
weight_fifo
(
	.clk(clk_i), 
	.rst(rst_n_i), 
	.clr(start_i), 
	.din(data_StatRd_E), 
	.we(fifo_write_enable), 
	.dout(weight_fifo_out), 
	.re(rdEn_StatRd_F_i),
	.full(), 
	.empty(), 
	.full_r(),
	.empty_r(),
	.full_n(), 
	.empty_n(), 
	.full_n_r(), 
	.empty_n_r(),
	.level()
);

//dump memory contents
`ifdef DUMP_MEMORY
	
	reg [100*8:1] logical_axon_connectivity_file_name;
	reg /*sparse*/ logical_axon_connectivity		[0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];
	
	
	//counter
	integer clock_counter = 0;
	integer step_counter = 0;

	always @(posedge clk_i)
		begin
			clock_counter = clock_counter + 1;
			
			if (start_i == 1'b1)
				step_counter = step_counter + 1;
		end

	//file output
	integer f1, f2, f3, f4, f5, f6, i, j, base_address, axon_id, neuron_id;
	reg [100*8:1] dump_file_name;
	initial
		begin
			logical_axon_connectivity_file_name = {SIM_PATH, "data", DIR_ID, "/logical_axon_connectivity.txt"};	
			$readmemh (logical_axon_connectivity_file_name, logical_axon_connectivity);

			dump_file_name = {SIM_PATH, "data", DIR_ID, "/dump_Bias.csv"};
			f1 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, "data", DIR_ID, "/dump_MembPot.csv"};
			f2 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, "data", DIR_ID, "/dump_Threshold.csv"};
			f3 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, "data", DIR_ID, "/dump_PostHist.csv"};
			f4 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, "data", DIR_ID, "/dump_PreHist.csv"};
			f5 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, "data", DIR_ID, "/dump_Weights.csv"};
			f6 = $fopen(dump_file_name,"w");
			//write header
			$fwrite(f1, "address,");
			$fwrite(f2, "address,");
			$fwrite(f3, "address,");
			$fwrite(f4, "address,");
			$fwrite(f5, "address,");
			$fwrite(f6, "address,");
			for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
				begin
					$fwrite(f1, "%h,", i);			//address
					$fwrite(f2, "%h,", i);			//address
					$fwrite(f3, "%h,", i);			//address
					$fwrite(f4, "%h,", i);			//address
				end
			
			$fwrite(f1, "\n");			$fwrite(f2, "\n");
			$fwrite(f3, "\n");			$fwrite(f4, "\n");
			
			$fwrite(f1, "neuron_id,");
			$fwrite(f2, "neuron_id,");
			$fwrite(f3, "neuron_id,");
			$fwrite(f4, "neuron_id,");
			for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
				begin
					$fwrite(f1, "%0d,", i);			//address
					$fwrite(f2, "%0d,", i);			//address
					$fwrite(f3, "%0d,", i);			//address
					$fwrite(f4, "%0d,", i);			//address
				end

			for (i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i+1)
				begin
					if (logical_axon_connectivity[i] == 1'b1)
						begin
							$fwrite(f5, "%h,", i);			//address
							$fwrite(f6, "%h,", i);			//address
						end
				end
			
			//write neuron id and axon id for prehist and weight
			$fwrite(f5, "\n"); $fwrite(f5, "lable,");
			$fwrite(f6, "\n"); $fwrite(f6, "lable,");
			for(i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i+1)
				begin
					if(logical_axon_connectivity[i] == 1'b1)
						begin
							axon_id = i[AXON_CNT_BIT_WIDTH-1:0];
							neuron_id = i[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:AXON_CNT_BIT_WIDTH];
							$fwrite(f5, "%0d_%0d,", neuron_id, axon_id);
							$fwrite(f6, "%0d_%0d,", neuron_id, axon_id);
						end
				end

			$fwrite(f1, "\n");
			$fwrite(f2, "\n");
			$fwrite(f3, "\n");
			$fwrite(f4, "\n");
			$fwrite(f5, "\n");
			$fwrite(f6, "\n");
		end

	always @(posedge clk_i)
		begin
			if (step_counter < STOP_STEP)
				begin
					if (start_i == 1'b1)
						begin
							//dump bias
							`ifdef DUMP_BIAS
								$fwrite(f1, "step-%0d,",step_counter);
								for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
									begin
										//$fwrite(f1, "%h:", i);			//address
										$fwrite(f1, "%h,", Mem_Bias[i]);	//every word
									end
									$fwrite(f1, "\n");
							`endif

							//dump membpot
							`ifdef DUMP_POTENTIAL
								$fwrite(f2, "step-%0d,",step_counter);
								for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i + 1)
									begin
										//$fwrite(f2, "%h:", i);			//address
										$fwrite(f2, "%h,", Mem_Potential[i]);	//word
									end
									$fwrite(f2, "\n");
							`endif

							//Threshold
							`ifdef DUMP_THRESHOLD
								$fwrite(f3, "step-%0d,",step_counter);
								for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
									begin
										//$fwrite(f3, "%h:",i);
										$fwrite(f3, "%h,", Mem_Threshold[i]);
									end
								$fwrite(f3, "\n");
							`endif
							
							//Post synaptic history
							`ifdef DUMP_POSTHISTORY
								$fwrite(f4, "step-%0d,",step_counter);
								for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
									begin
										//$fwrite(f4, "%h:",i);
										$fwrite(f4, "%0d,", Mem_PostHistory[i]);
									end
								$fwrite(f4, "\n");
							`endif

							//Pre synaptic history
							`ifdef DUMP_PREHISTORY
								$fwrite(f5, "step-%0d,",step_counter);
								//dump all memory, output very large file
								// for (i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i+1)
								// 	begin
								// 		//$fwrite(f5, "%h:",i);
								// 		$fwrite(f5, "%h,", Mem_PreHistory[i]);
								// 	end
								// $fwrite(f5, "\n");

								//only dump valid memory, small file, too many loop times
								// for (i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i + 1)
								// 	begin
								// 		if(logical_axon_connectivity[i]==1'b1)
								// 			$fwrite(f5, "%0d,", Mem_PreHistory[i]);
								// 	end
								// $fwrite(f5, "\n");

								// only dump valid memory, small file, less loop times
								for (i = 0; i < NUM_NURNS; i = i + 1)
									begin
										base_address = i << AXON_CNT_BIT_WIDTH;
										for(j = 0; j < NUM_AXONS; j = j + 1)
											if(logical_axon_connectivity[base_address + j] == 1'b1)
												$fwrite(f5, "%0d,", Mem_PreHistory[base_address + j]);
									end
								
								$fwrite(f5, "\n");

							`endif

							//Weights
							`ifdef DUMP_WEIGHT
								$fwrite(f6, "step-%0d,",step_counter);
								//dump all memory, output very large file
								// for (i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i+1)
								// 	begin
								// 		//$fwrite(f6, "%h:",i);
								// 		$fwrite(f6, "%h,", Mem_Weight[i]);
								// 	end
								// $fwrite(f6, "\n");
								
								//only dump valid memory, small file, too many loop times
								// for (i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i + 1)
								// 	begin
								// 		if(logical_axon_connectivity[i] == 1'b1)
								// 			$fwrite(f6, "%h,", Mem_Weight[i]);
								// 	end

								// only dump valid memory, small file, less loop times
								for (i = 0; i < NUM_NURNS; i = i + 1)
									begin
										base_address = i << AXON_CNT_BIT_WIDTH;
										for(j = 0; j < NUM_AXONS; j = j + 1)
											if(logical_axon_connectivity[base_address + j] == 1'b1)
												$fwrite(f6, "%h,", Mem_Weight[base_address + j]);
									end
								
								$fwrite(f6, "\n");
							`endif
						end
				end
			else
				begin
					$fclose(f1);
					$fclose(f2);
					$fclose(f3);
					$fclose(f4);
					$fclose(f5);
					$fclose(f6);
				end
		end	

`endif

endmodule