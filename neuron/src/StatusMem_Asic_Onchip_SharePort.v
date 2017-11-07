//memory 1 - 4 read write address are same, separare read signal and write signal

//2017.10.18 change width of Addr_StatWr_B_i. and remove wire addr_B.

`include "neuron_define.v"
// `define SIM_MEM_INIT
// //`define QUARTUS_SYN_INIT
// `define NULL 0
// `define DUMP_MEMORY


module StatusMem_Asic_Onchip_SharePort
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
	input												start_i,
	input 												clk_i,
	input 												rst_n_i,

	//read port A
	input [NURN_CNT_BIT_WIDTH+2-1:0] 					Addr_StatRd_A_i,
	input 												read_enable_bias_i,
    input                                               read_enable_potential_i,
    input                                               read_enable_threshold_i,
    input                                               read_enable_posthistory_i,

    input write_enable_bias_i,
    input write_enable_potential_i,
    input write_enable_threshold_i,
    input write_enable_posthistory_i,

	output reg [DSIZE-1:0]								data_StatRd_A_o,

	//write port B
	input [NURN_CNT_BIT_WIDTH-1:0] 						Addr_StatWr_B_i,
	input [DSIZE-1:0]									data_StatWr_B_i,
	
	//read port C
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatRd_C_i,
	input 												rdEn_StatRd_C_i,

	output [STDP_WIN_BIT_WIDTH-1:0]						data_StatRd_C_o,

	//write port D
	input [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0] 	Addr_StatWr_D_i,
	input 												wrEn_StatWr_D_i,
	input [STDP_WIN_BIT_WIDTH-1:0]						data_StatWr_D_i,
	
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
	input [DSIZE-1:0]									data_StatWr_G_i

);


	//MEMORY DECLARATION
	//--------------------------------------------------//
	
    `ifdef QUARTUS_SYN_INIT
		(* ram_init_file = BIAS_MIF_PATH *)             reg [DSIZE-1:0] 			 Mem_Bias           [0:(1<<NURN_CNT_BIT_WIDTH) -1];
		(* ram_init_file = MEMBPOT_MIF_PATH *)          reg [DSIZE-1:0] 			 Mem_Potential      [0:(1<<NURN_CNT_BIT_WIDTH) -1];
		(* ram_init_file = TH_MIF_PATH *)               reg [DSIZE-1:0] 			 Mem_Threshold      [0:(1<<NURN_CNT_BIT_WIDTH) -1];
		(* ram_init_file = POSTSPIKEHISTORY_MIF_PATH *) reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PostHistory    [0:(1<<NURN_CNT_BIT_WIDTH) -1];
		(* ram_init_file = PRESPIKEHISTORY_MIF_PATH *)  reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PreHistory     [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];
		(* ram_init_file = WEIGHTS_MIF_PATH *)          reg [DSIZE-1:0] 			 Mem_Weight         [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];
    `else
        reg [DSIZE-1:0] 			 Mem_Bias           [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [DSIZE-1:0] 			 Mem_Potential      [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [DSIZE-1:0] 			 Mem_Threshold      [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PostHistory    [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PreHistory     [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];
        reg [DSIZE-1:0] 			 Mem_Weight         [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];
        reg [DSIZE-1:0] 			 Mem_Weight2        [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];
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
            file_name = {SIM_PATH, DIR_ID, "/Weights.txt"};			    $readmemh (file_name,Mem_Weight2);
		end
	`endif

    //read address registers
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_bias;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_potential;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_threshold;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_posthistory;
    reg [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]                        read_address_register_prehistory;
    reg [NURN_CNT_BIT_WIDTH*AXON_CNT_BIT_WIDTH-1:0]                        read_address_register_weight_E, read_address_register_weight_F;

    wire [DSIZE-1:0] data_out_bias_o, data_out_potential_o, data_out_threshold_o, data_out_weight_o;
    wire [STDP_WIN_BIT_WIDTH-1:0] data_out_posthistory_o;
    wire [NURN_CNT_BIT_WIDTH-1:0] addr_b;
    reg [1:0] sel_A_reg;
	wire [DSIZE-1:0] data_StatRd_E, data_StatRd_F;
	reg fifo_write_enable;

    assign addr_b = Addr_StatWr_B_i;
    //memory bias
	always @(posedge clk_i)
        begin
	        if (read_enable_bias_i == 1'b1)
	            read_address_register_bias <= Addr_StatRd_A_i[NURN_CNT_BIT_WIDTH+2-1:2];
		    if (write_enable_bias_i == 1'b1)
			    Mem_Bias[Addr_StatWr_B_i] <= data_StatWr_B_i;
        end
    assign data_out_bias_o = Mem_Bias[read_address_register_bias];

    always @(posedge clk_i)
        begin
	        if (read_enable_potential_i == 1'b1)
	            read_address_register_potential <= Addr_StatRd_A_i[NURN_CNT_BIT_WIDTH+2-1:2];
		    if (write_enable_potential_i == 1'b1)
			    Mem_Potential[Addr_StatWr_B_i] <= data_StatWr_B_i;
        end
    assign data_out_potential_o = Mem_Potential[read_address_register_potential];

    always @(posedge clk_i)
        begin
	        if (read_enable_threshold_i == 1'b1)
	            read_address_register_threshold <= Addr_StatRd_A_i[NURN_CNT_BIT_WIDTH+2-1:2];
		    if (write_enable_threshold_i == 1'b1)
			    Mem_Threshold[Addr_StatWr_B_i] <= data_StatWr_B_i;
        end
    assign data_out_threshold_o = Mem_Threshold[read_address_register_threshold];

    always @(posedge clk_i)
        begin
	        if (read_enable_posthistory_i == 1'b1)
	            read_address_register_posthistory <= Addr_StatRd_A_i[NURN_CNT_BIT_WIDTH+2-1:2];
		    if (write_enable_posthistory_i == 1'b1)
			    Mem_PostHistory[Addr_StatWr_B_i] <= data_StatWr_B_i;
        end
    assign data_out_posthistory_o = Mem_PostHistory[read_address_register_posthistory];

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

    // always @(posedge clk_i)
    //     begin
	//         if (rdEn_StatRd_F_i == 1'b1)
	//             read_address_register_weight_F <= Addr_StatRd_F_i;
	// 	    if (wrEn_StatWr_G_i == 1'b1)
	// 		    Mem_Weight2[wrEn_StatWr_G_i] <= data_StatWr_G_i;
    //     end
    // assign data_StatRd_F_o = Mem_Weight2[read_address_register_weight_F];


//test
always @(posedge clk_i or negedge rst_n_i)
	begin
		if (rst_n_i == 1'b0)
			sel_A_reg <= 1'b0;
		else
			sel_A_reg <= Addr_StatRd_A_i[1:0];
	end

always @(*)
	begin
		data_StatRd_A_o = 0;
		case (sel_A_reg)
	        2'b00: begin
	        	data_StatRd_A_o = data_out_bias_o;//Bias
	        end
	        2'b01: begin
	        	data_StatRd_A_o = data_out_potential_o;//MembPot
	        end
	        2'b10: begin
	        	data_StatRd_A_o = data_out_threshold_o;//Th
	        end
	        default: begin//2'b11
	        	data_StatRd_A_o = data_out_posthistory_o;//PostSpikeHist
	        end
		endcase
	end

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
	.aw(8)
)
weight_fifo
(
	.clk(clk_i), 
	.rst(rst_n_i), 
	.clr(start_i), 
	.din(data_StatRd_E), 
	.we(fifo_write_enable), 
	.dout(data_StatRd_F_o), 
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
	reg [100*8:1] dump_file_name;
	initial
		begin
			dump_file_name = {SIM_PATH, DIR_ID, "/dump_Bias.txt"};
			f1 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, DIR_ID, "/dump_MembPot.txt"};
			f2 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, DIR_ID, "/dump_Threshold.txt"};
			f3 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, DIR_ID, "/dump_PostHist.txt"};
			f4 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, DIR_ID, "/dump_PreHist.txt"};
			f5 = $fopen(dump_file_name,"w");
			dump_file_name = {SIM_PATH, DIR_ID, "/dump_Weights.txt"};
			f6 = $fopen(dump_file_name,"w");
			//write header
			$fwrite(f1, "step,");
			$fwrite(f2, "step,");
			$fwrite(f3, "step,");
			$fwrite(f4, "step,");
			$fwrite(f5, "step,");
			$fwrite(f6, "step,");
			for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
				begin
					$fwrite(f1, "%h,", i);			//address
					$fwrite(f2, "%h,", i);			//address
					$fwrite(f3, "%h,", i);			//address
					$fwrite(f4, "%h,", i);			//address
				end

			for (i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i+1)
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
							for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
								begin
									//$fwrite(f1, "%h:", i);			//address
									$fwrite(f1, "%h,", Mem_Bias[i]);	//every word
								end
								$fwrite(f1, "\n");
							//dump membpot
							$fwrite(f2, "%0d,",step_counter);
							for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i + 1)
								begin
									//$fwrite(f2, "%h:", i);			//address
									$fwrite(f2, "%h,", Mem_Potential[i]);	//word
								end
							$fwrite(f2, "\n");
							//Threshold
							$fwrite(f3, "%0d,",step_counter);
							for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
								begin
									//$fwrite(f3, "%h:",i);
									$fwrite(f3, "%h,", Mem_Threshold[i]);
								end
							$fwrite(f3, "\n");
							//Post synaptic history
							$fwrite(f4, "%0d,",step_counter);
							for (i = 0; i < (1<<NURN_CNT_BIT_WIDTH); i = i+1)
								begin
									//$fwrite(f4, "%h:",i);
									$fwrite(f4, "%h,", Mem_PostHistory[i]);
								end
							$fwrite(f4, "\n");
							//Pre synaptic history
							$fwrite(f5, "%0d,",step_counter);
							for (i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i+1)
								begin
									//$fwrite(f5, "%h:",i);
									$fwrite(f5, "%h,", Mem_PreHistory[i]);
								end
							$fwrite(f5, "\n");
							//Weights
							$fwrite(f6, "%0d,",step_counter);
							for (i = 0; i < (1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH)); i = i+1)
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