
//not complete
`define SIM_MEM_INIT
//`define QUARTUS_SYN_INIT
`define NULL 0
`define DUMP_MEMORY



module StatusMem_Asic_Onchip
#(

	`ifdef DUMP_MEMORY
		parameter STOP_STEP = 5,
	`endif
	parameter NUM_NURNS    = 256  ,
	parameter NUM_AXONS    = 256  ,

	parameter DSIZE    = 16 ,

	parameter NURN_CNT_BIT_WIDTH   = 8 ,
	parameter AXON_CNT_BIT_WIDTH   = 8 ,

	parameter STDP_WIN_BIT_WIDTH = 8,

	
	parameter X_ID = "1",
	parameter Y_ID = "1",
	parameter DIR_ID = {X_ID, "_", Y_ID},
	parameter SIM_PATH = "D:/code/data",
	parameter SYNTH_PATH = "D:/code/synth/data"

)
(
	`ifdef DUMP_MEMORY
		input 											start_i,
	`endif
	input 												clk_i,
	input 												rst_n_i,


    //Mem Bias
    input [NURN_CNT_BIT_WIDTH-1:0]                      read_address_bias_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                      write_address_bias_i,
    input                                               read_enable_bias_i,
    input                                               write_enable_bias_i,

    //Mem Potential
    input [NURN_CNT_BIT_WIDTH-1:0]                      read_address_potential_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                      write_address_potential_i,
    input                                               read_enable_potential_i,
    input                                               write_enable_potential_i,

    input [NURN_CNT_BIT_WIDTH-1:0]                      read_address_threshold_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                      write_address_threshold_i,
    input                                               read_enable_threshold_i,
    input                                               write_enable_threshold_i,

    input [NURN_CNT_BIT_WIDTH-1:0]                      read_address_posthistory_i,
    input [NURN_CNT_BIT_WIDTH-1:0]                      write_address_posthistory_i,
    input                                               read_enable_posthistory_i,
    input                                               write_enable_posthistory_i,

    input [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]                      read_address_prehistory_i,
    input [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]                      write_address_prehistory_i,
    input                                               read_enable_prehistory_i,
    input                                               write_enable_prehistory_i,

    input [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]                      read_address_weight_i,
    input [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]                      write_address_weight_i,
    input                                               read_enable_weight_recall_i,
    input                                               write_enable_weight_i,
	input												read_enable_weight_learn_i,

	input [DSIZE-1:0]									data_in_bias_i,
	input [DSIZE-1:0]									data_in_potential_i,
	input [DSIZE-1:0]									data_in_threshold_i,
	input [DSIZE-1:0]									data_in_posthistory_i,
	input [STDP_WIN_BIT_WIDTH-1:0]						data_in_prehistory_i,
	input [DSIZE-1:0]									data_in_weight_i,

	output [DSIZE-1:0]									data_out_bias_o,
	output [DSIZE-1:0]									data_out_potential_o,
	output [DSIZE-1:0]									data_out_threshold_o,
	output [STDP_WIN_BIT_WIDTH-1:0]						data_out_posthistory_o,
	output [STDP_WIN_BIT_WIDTH-1:0]						data_out_prehistory_o,
	output [DSIZE-1:0]									data_out_weight_o,

	output reg [DSIZE-1:0]								data_StatRd_A_o,
	input [1:0]											sel_A,
	input [NURN_CNT_BIT_WIDTH+2-1:0] 					Addr_StatRd_A_i,

	input [DSIZE-1:0]									data_StatWr_B_i,
	input [1:0]											sel_B

);


	//MEMORY DECLARATION
	//--------------------------------------------------//
	
    `ifdef QUARTUS_SYN_INIT
		(* ram_init_file = BIAS_MIF_PATH *)             reg [DSIZE-1:0] 			 Mem_Bias           [0:NUM_NURNS-1];
		(* ram_init_file = MEMBPOT_MIF_PATH *)          reg [DSIZE-1:0] 			 Mem_Potential      [0:NUM_NURNS-1];
		(* ram_init_file = TH_MIF_PATH *)               reg [DSIZE-1:0] 			 Mem_Threshold      [0:NUM_NURNS-1];
		(* ram_init_file = POSTSPIKEHISTORY_MIF_PATH *) reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PostHistory    [0:NUM_NURNS-1];
		(* ram_init_file = PRESPIKEHISTORY_MIF_PATH *)  reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PreHistory     [0:NUM_NURNS*NUM_AXONS-1];
		(* ram_init_file = WEIGHTS_MIF_PATH *)          reg [DSIZE-1:0] 			 Mem_Weight         [0:NUM_NURNS*NUM_AXONS-1];
    `else
        reg [DSIZE-1:0] 			 Mem_Bias           [0:NUM_NURNS-1];
        reg [DSIZE-1:0] 			 Mem_Potential      [0:NUM_NURNS-1];
        reg [DSIZE-1:0] 			 Mem_Threshold      [0:NUM_NURNS-1];
        reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PostHistory    [0:NUM_NURNS-1];
        reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PreHistory     [0:NUM_NURNS*NUM_AXONS-1];
        reg [DSIZE-1:0] 			 Mem_Weight         [0:NUM_NURNS*NUM_AXONS-1];
	`endif

    //initial memory
	`ifdef SIM_MEM_INIT
		reg [100*8:1] file_name;
		initial begin
			file_name = {SIM_PATH, DIR_ID, "/Bias.txt"};				$readmemh (file_name,Mem_Bias);
			file_name = {SIM_PATH, DIR_ID, "/MembPot.txt"};			    $readmemh (file_name,Mem_Potential);
			file_name = {SIM_PATH, DIR_ID, "/Th.txt"};				    $readmemh (file_name,Mem_Threshold);
			file_name = {SIM_PATH, DIR_ID, "/PostSpikeHistory.txt"};	$readmemh (file_name,Mem_PostHistory);
			file_name = {SIM_PATH, DIR_ID, "/PreSpikeHistory.txt"}; 	$readmemh (file_name,Mem_PreHistory);
			file_name = {SIM_PATH, DIR_ID, "/Weights.txt"};			    $readmemh (file_name,Mem_Weight);
		end
	`endif

    //read address registers
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_bias;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_potential;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_threshold;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_posthistory;
    reg [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]                        read_address_register_prehistory;
    reg [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]                        read_address_register_weight;

	reg [1:0] sel_A_reg;


	`ifdef SEPARATE_ADDRESS







	`else



	`endif

    //memory bias
	always @(posedge clk_i)
        begin
	        if (read_enable_bias_i == 1'b1)
	            read_address_register_bias <= read_address_bias_i;
		    if (write_enable_bias_i == 1'b1)
			    Mem_Bias[write_address_bias_i] <= data_in_bias_i;
        end
    assign data_out_bias_o = Mem_Bias[read_address_register_bias];

    always @(posedge clk_i)
        begin
	        if (read_enable_potential_i == 1'b1)
	            read_address_register_potential <= read_address_potential_i;
		    if (write_enable_potential_i == 1'b1)
			    Mem_Potential[write_address_potential_i] <= data_in_potential_i;
        end
    assign data_out_potential_o = Mem_Potential[read_address_register_potential];

    always @(posedge clk_i)
        begin
	        if (read_enable_threshold_i == 1'b1)
	            read_address_register_threshold <= read_address_threshold_i;
		    if (write_enable_threshold_i == 1'b1)
			    Mem_Threshold[write_address_threshold_i] <= data_in_threshold_i;
        end
    assign data_out_threshold_o = Mem_Threshold[read_address_register_threshold];

    always @(posedge clk_i)
        begin
	        if (read_enable_posthistory_i == 1'b1)
	            read_address_register_posthistory <= read_address_posthistory_i;
		    if (write_enable_posthistory_i == 1'b1)
			    Mem_PostHistory[write_address_posthistory_i] <= data_in_posthistory_i;
        end
    assign data_out_posthistory_o = Mem_PostHistory[read_address_register_posthistory];

    always @(posedge clk_i)
        begin
	        if (read_enable_prehistory_i == 1'b1)
	            read_address_register_prehistory <= read_address_prehistory_i;
		    if (write_enable_prehistory_i == 1'b1)
			    Mem_PreHistory[write_address_prehistory_i] <= data_in_prehistory_i;
        end
    assign data_out_prehistory_o = Mem_PreHistory[read_address_register_prehistory];

    always @(posedge clk_i)
        begin
	        if (read_enable_weight_recall_i == 1'b1)
	            read_address_register_weight <= read_address_weight_i;
		    if (write_enable_weight_i == 1'b1)
			    Mem_Weight[write_address_weight_i] <= data_in_weight_i;
        end
    assign data_out_weight_o = Mem_Weight[read_address_register_weight];


		//test
always @(posedge clk_i)
	sel_A_reg <= sel_A;

always @(*)
	begin
		data_StatRd_A_o = 0;
		case (sel_A_reg)
	        2'b00: begin
	        	data_StatRd_A_o = Mem_Bias[read_address_register_bias];//Bias
	        end
	        2'b01: begin
	        	data_StatRd_A_o = Mem_Potential[read_address_register_potential];//MembPot
	        end
	        2'b10: begin
	        	data_StatRd_A_o = Mem_Threshold[read_address_register_threshold] ;//Th
	        end
	        default: begin//2'b11
	        	data_StatRd_A_o = Mem_PostHistory[read_address_register_posthistory] ;//PostSpikeHist
	        end
		endcase
	end

//dump memory contents
`ifdef DUMP_MEMORY

	//counter
	integer clock_counter;
	integer step_counter;

	initial
		begin
			clock_counter = 0;
			step_counter = 0;
		end

	always @(posedge clk_i)
		clock_counter = clock_counter + 1;
	
	always @(posedge clk_i)
		if (start_i == 1'b1)
			step_counter = step_counter + 1;

	//file output
	integer f1, f2, f3, f4, f5, f6, i;
	initial
		begin
			f1 = $fopen("Bias.txt","w");
			f2 = $fopen("MembPot.txt","w");
			f3 = $fopen("Threshold.txt","w");
			f4 = $fopen("PostHist.txt","w");
			f5 = $fopen("PreHist.txt","w");
			f6 = $fopen("Weights.txt","w");
			//write header
			$fwrite(f1, "step,");
			$fwrite(f2, "step,");
			$fwrite(f3, "step,");
			$fwrite(f4, "step,");
			$fwrite(f5, "step,");
			$fwrite(f6, "step,");
			for (i = 0; i < NUM_NURNS; i = i+1)
				begin
					$fwrite(f1, "%h,", i);			//address
					$fwrite(f2, "%h,", i);			//address
					$fwrite(f3, "%h,", i);			//address
					$fwrite(f4, "%h,", i);			//address
				end

			for (i = 0; i < NUM_NURNS * NUM_AXONS; i = i+1)
				begin
					$fwrite(f5, "%h,", i);			//address
					$fwrite(f6, "%h,", i);			//address
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
							$fwrite(f1, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS; i = i+1)
								begin
									//$fwrite(f1, "%h:", i);			//address
									$fwrite(f1, "%h,", Mem_Bias[i]);	//every word
								end
								$fwrite(f1, "\n");
							//dump membpot
							$fwrite(f2, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS; i = i + 1)
								begin
									//$fwrite(f2, "%h:", i);			//address
									$fwrite(f2, "%h,", Mem_Potential[i]);	//word
								end
							$fwrite(f2, "\n");
							//Threshold
							$fwrite(f3, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS; i = i+1)
								begin
									//$fwrite(f3, "%h:",i);
									$fwrite(f3, "%h,", Mem_Threshold[i]);
								end
							$fwrite(f3, "\n");
							//Post synaptic history
							$fwrite(f4, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS; i = i+1)
								begin
									//$fwrite(f4, "%h:",i);
									$fwrite(f4, "%h,", Mem_PostHistory[i]);
								end
							$fwrite(f4, "\n");
							//Pre synaptic history
							$fwrite(f5, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS * NUM_AXONS; i = i+1)
								begin
									//$fwrite(f5, "%h:",i);
									$fwrite(f5, "%h,", Mem_PreHistory[i]);
								end
							$fwrite(f5, "\n");
							//Weights
							$fwrite(f6, "%0d,",step_counter);
							for (i = 0; i < NUM_NURNS * NUM_AXONS; i = i+1)
								begin
									//$fwrite(f6, "%h:",i);
									$fwrite(f6, "%h,", Mem_Weight[i]);
								end
							$fwrite(f6, "\n");
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