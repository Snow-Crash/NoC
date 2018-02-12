//memory 1 - 4 read write address are same, separare read signal and write signal
//2017.10.18 change width of Addr_StatWr_B_i. and remove wire addr_B.
//2017.11.7  fix two registers wrong width. Weight's fifo depth should be larger than 256, beacuse when second neuron
//			 starts recall and write to fifo, this time fifo is full, first doesn't start learning, so fifo is not read 
//			 at this time. So double the fifo depth. It't not a good solution.

`include "neuron_define.v"
// `define SIM_MEM_INIT
// `define QUARTUS_SYN_INIT
// `define NULL 0
// `define DUMP_MEMORY


module StatusMem_Asic
#(

	
	parameter STOP_STEP = 5,
	
	parameter NUM_NURNS = 256  ,
	parameter NUM_AXONS = 256  ,

	parameter DSIZE = 16 ,

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
        reg [DSIZE-1:0] 			 Mem_Bias           [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [DSIZE-1:0] 			 Mem_Potential      [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [DSIZE-1:0] 			 Mem_Threshold      [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PostHistory    [0:(1<<NURN_CNT_BIT_WIDTH) -1];
        
		reg /*sparse*/ [STDP_WIN_BIT_WIDTH-1:0] Mem_PreHistory     [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];
        reg /*sparse*/ [DSIZE-1:0] 			 	Mem_Weight         [0:(1<<(NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH))-1];

		// neuron 0 - 31
		reg /*sparse*/ [DSIZE-1:0] 			 	Mem_Weight_1         [8192-1:0];
		// neuron 31 - 63
		reg /*sparse*/ [DSIZE-1:0] 			 	Mem_Weight_2         [8192-1:0];
		// neuron 64 - 95
		reg /*sparse*/ [DSIZE-1:0] 			 	Mem_Weight_3         [8192-1:0];
		// neuron 96-127
		reg /*sparse*/ [DSIZE-1:0] 			 	Mem_Weight_4         [8192-1:0];

		// neuron 0 - 31
		reg /*sparse*/ [DSIZE-1:0] 			 	Mem_PreHistory_1		[8192-1:0];
		// neuron 31 - 63
		reg /*sparse*/ [DSIZE-1:0] 			 	Mem_PreHistory_2		[8192-1:0];
		// neuron 64 - 95
		reg /*sparse*/ [DSIZE-1:0] 			 	Mem_PreHistory_3		[8192-1:0];
		// neuron 96-127
		reg /*sparse*/ [DSIZE-1:0] 			 	Mem_PreHistory_4		[8192-1:0];

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

			//initialize 4 weight memory
			file_name = {SIM_PATH, "data", DIR_ID, "/Weights.txt"};
			file = $fopen(file_name, "r+");
			for(idx = 0 ; idx <=(8192-1) ; idx = idx + 1)
				begin
					$fscanf (file, "%h\n", data); 
					Mem_Weight_1[idx] = data;
				end

			for(idx = 0 ; idx <=(8192-1) ; idx = idx + 1)
				begin
					$fscanf (file, "%h\n", data); 
					Mem_Weight_2[idx] = data;
				end
			
			for(idx = 0 ; idx <=(8192-1) ; idx = idx + 1)
				begin
					$fscanf (file, "%h\n", data); 
					Mem_Weight_3[idx] = data;
				end

			for(idx = 0 ; idx <=(8192-1) ; idx = idx + 1)
				begin
					$fscanf (file, "%h\n", data); 
					Mem_Weight_4[idx] = data;
				end
			$fclose(file);
		end
	`endif

    //read address registers
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_bias;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_potential;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_threshold;
    reg [NURN_CNT_BIT_WIDTH-1:0]                        read_address_register_posthistory;
    reg [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]                        read_address_register_prehistory;
    reg [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:0]                        read_address_register_weight_E, read_address_register_weight_F;

	wire [DSIZE-1:0] data_StatRd_E, data_StatRd_F;
	reg fifo_write_enable;

	reg [STDP_WIN_BIT_WIDTH-1:0] pre_history_rd_mux, pre_history_wr_mux;
	reg weight_1_wr_en, weight_2_wr_en, weight_3_wr_en, weight_4_wr_en;
	reg weight_recall_1_rd_en, weight_recall_2_rd_en, weight_recall_3_rd_en, weight_recall_4_rd_en;
	reg [1:0] weight_recall_rd_sel_reg, weight_learn_rd_sel;
	wire [1:0] weight_recall_rd_sel;
	wire [1:0] weight_mem_wr_sel;
	wire [DSIZE-1:0] weight_mem_1_out, weight_mem_2_out, weight_mem_3_out, weight_mem_4_out;
	reg [AXON_CNT_BIT_WIDTH+NURN_CNT_BIT_WIDTH-3:0] weight_1_rd_addr_reg, weight_2_rd_addr_reg, weight_3_rd_addr_reg, weight_4_rd_addr_reg;
	reg [DSIZE-1:0] data_e;
	wire [DSIZE-1:0] data_f;
	wire [NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-3:0] weight_recall_rd_addr, weight_mem_wr_addr;

	reg pre_history_1_wr_en, pre_history_2_wr_en, pre_history_3_wr_en, pre_history_4_wr_en;
	reg pre_history_1_rd_en, pre_history_2_rd_en, pre_history_3_rd_en, pre_history_4_rd_en;
	reg [1:0] pre_history_wr_sel, pre_history_rd_sel;

`ifdef SINGLE_PORT_STATUS_MEM
	// output reg
	reg [DSIZE-1:0] Mem_Bias_dout, Mem_Potential_dout, Mem_Threshold_dout;
	reg [STDP_WIN_BIT_WIDTH-1:0] Mem_PostHistory_dout;
	// address mux
	wire [NURN_CNT_BIT_WIDTH-1:0] Mem_Bias_addr, Mem_Potential_addr, Mem_PostHistory_addr, Mem_Threshold_addr;
`endif

`ifdef SINGLE_PORT_STATUS_MEM
	`ifdef SEPARATE_ADDRESS
		assign Mem_Bias_addr = (write_enable_bias_i == 1'b1) ? write_addr_bias_i : read_addr_bias_i;
		assign Mem_Potential_addr = (write_enable_potential_i == 1'b1) ? write_addr_potential_i : read_addr_potential_i;
		assign Mem_Threshold_addr = (write_enable_threshold_i == 1'b1) ? write_addr_threshold_i : read_addr_threshold_i;
		assign Mem_PostHistory_addr = (write_enable_posthistory_i == 1'b1) ? write_addr_posthistory_i : read_addr_posthistory_i;
	`else
		assign Mem_Bias_addr = (write_enable_bias_i == 1'b1) ? Addr_StatWr_B_i : Addr_StatRd_A_i;
		assign Mem_Potential_addr = (write_enable_potential_i == 1'b1) ? Addr_StatWr_B_i : Addr_StatRd_A_i;
		assign Mem_Threshold_addr = (write_enable_threshold_i == 1'b1) ? Addr_StatWr_B_i : Addr_StatRd_A_i;
		assign Mem_PostHistory_addr = (write_enable_posthistory_i == 1'b1) ? Addr_StatWr_B_i : Addr_StatRd_A_i;
	`endif

	always  @(posedge clk_i)
		begin
			if(ce)  
				begin
					if(write_enable_bias_i)  
						begin
							//Mem_Bias[Addr_StatWr_B_i] <= data_wr_bias_i;
							Mem_Bias[Mem_Bias_addr] <= data_wr_bias_i;
							Mem_Bias_dout <= data_wr_bias_i;
						end
					else
						// Mem_Bias_dout <= Mem_Bias[Addr_StatRd_A_i];
						Mem_Bias_dout <= Mem_Bias[Mem_Bias_addr];
				end
		end
	assign data_rd_bias_o = Mem_Bias_dout;

	always  @(posedge clk_i)
		begin
			if(ce)  
				begin
					if(write_enable_potential_i)  
						begin
							//Mem_Potential[Addr_StatWr_B_i] <= data_wr_potential_i;
							Mem_Potential[Mem_Potential_addr] <= data_wr_potential_i;
							Mem_Potential_dout <= data_wr_potential_i;
						end
					else
						// Mem_Potential_dout <= Mem_Potential[Addr_StatRd_A_i];
						Mem_Potential_dout <= Mem_Potential[Mem_Potential_addr];
				end
		end
	assign data_rd_potential_o = Mem_Potential_dout;

	always  @(posedge clk_i)
		begin
			if(ce)  
				begin
					if(write_enable_posthistory_i)  
						begin
							//Mem_PostHistory[Addr_StatWr_B_i] <= data_wr_posthistory_i;
							Mem_PostHistory[Mem_PostHistory_addr] <= data_wr_posthistory_i;
							Mem_PostHistory_dout <= data_wr_posthistory_i;
						end
					else
						// Mem_PostHistory_dout <= Mem_PostHistory[Addr_StatRd_A_i];
						Mem_PostHistory_dout <= Mem_PostHistory[Mem_PostHistory_addr];
				end
		end
	assign data_rd_posthistory_o = Mem_PostHistory_dout;

	always  @(posedge clk_i)
		begin
			if(ce)  
				begin
					if(write_enable_threshold_i)  
						begin
							//Mem_Threshold[Addr_StatWr_B_i] <= data_wr_threshold_i;
							Mem_Threshold[Mem_Threshold_addr] <= data_wr_threshold_i;
							Mem_Threshold_dout <= data_wr_threshold_i;
						end
					else
						// Mem_Threshold_dout <= Mem_Threshold[Addr_StatRd_A_i];
						Mem_Threshold_dout <= Mem_Threshold[Mem_Threshold_addr];
				end
		end
	assign data_rd_threshold_o = Mem_Threshold_dout;
`else    
    memory bias
	always @(posedge clk_i)
        begin
	        if (read_enable_bias_i == 1'b1)
	            read_address_register_bias <= Addr_StatRd_A_i;
		    if (write_enable_bias_i == 1'b1)
			    Mem_Bias[Addr_StatWr_B_i] <= data_wr_bias_i;
        end
    assign data_rd_bias_o = Mem_Bias[read_address_register_bias];

    always @(posedge clk_i)
        begin
	        if (read_enable_potential_i == 1'b1)
	            read_address_register_potential <= Addr_StatRd_A_i;
		    if (write_enable_potential_i == 1'b1)
			    Mem_Potential[Addr_StatWr_B_i] <= data_wr_potential_i;
        end
    assign data_rd_potential_o = Mem_Potential[read_address_register_potential];

    always @(posedge clk_i)
        begin
	        if (read_enable_threshold_i == 1'b1)
	            read_address_register_threshold <= Addr_StatRd_A_i;
		    if (write_enable_threshold_i == 1'b1)
			    Mem_Threshold[Addr_StatWr_B_i] <= data_wr_threshold_i;
        end
    assign data_rd_threshold_o = Mem_Threshold[read_address_register_threshold];

    always @(posedge clk_i)
        begin
	        if (read_enable_posthistory_i == 1'b1)
	            read_address_register_posthistory <= Addr_StatRd_A_i;
		    if (write_enable_posthistory_i == 1'b1)
			    Mem_PostHistory[Addr_StatWr_B_i] <= data_wr_posthistory_i;
        end
    assign data_rd_posthistory_o = Mem_PostHistory[read_address_register_posthistory];
`endif

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
	//assign data_StatRd_E_o = data_StatRd_E;
	assign data_StatRd_E_o = data_e;

always @(posedge clk_i or negedge rst_n_i)
	begin
		if (rst_n_i == 1'b0)
			begin
				weight_recall_rd_sel_reg <= 0;
				weight_learn_rd_sel <= 0;
			end
		else
			begin
				weight_recall_rd_sel_reg <= Addr_StatRd_E_i[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-2];
				weight_learn_rd_sel <= Addr_StatRd_F_i[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-2];
			end
	end
assign weight_mem_wr_sel = Addr_StatWr_G_i[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-2];

assign weight_mem_wr_addr = Addr_StatWr_G_i[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-3:0];
assign weight_recall_rd_addr = Addr_StatRd_E_i[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-3:0];
assign weight_recall_rd_sel = Addr_StatRd_E_i[NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-1:NURN_CNT_BIT_WIDTH+AXON_CNT_BIT_WIDTH-2];

// weight memory recall read en generate and output select
always @(*)
	begin
		weight_recall_1_rd_en = 1'b0;
		weight_recall_2_rd_en = 1'b0;
		weight_recall_3_rd_en = 1'b0;
		weight_recall_4_rd_en = 1'b0;
		data_e = 0;
		case (weight_recall_rd_sel_reg)
			2'b00:
				data_e = weight_mem_1_out;
			2'b01:
				data_e = weight_mem_2_out;
			2'b10:
				data_e = weight_mem_3_out;
			2'b11:
				data_e = weight_mem_4_out;
			default:
			data_e = weight_mem_1_out;
		endcase


		case (weight_recall_rd_sel)
			2'b00:
				begin
					weight_recall_1_rd_en = rdEn_StatRd_E_i;
				end
			2'b01:
				begin
					weight_recall_2_rd_en = rdEn_StatRd_E_i;
				end
			2'b10:
				begin
					weight_recall_3_rd_en = rdEn_StatRd_E_i;
				end
			2'b11:
				begin
					weight_recall_4_rd_en = rdEn_StatRd_E_i;
				end
			default:
				begin
					weight_recall_1_rd_en = 1'b0;
					weight_recall_2_rd_en = 1'b0;
					weight_recall_3_rd_en = 1'b0;
					weight_recall_4_rd_en = 1'b0;
				end
		endcase
	end

//weight memory write en generate
always @(*)
	begin
		weight_1_wr_en = 1'b0;
		weight_2_wr_en = 1'b0;
		weight_3_wr_en = 1'b0;
		weight_4_wr_en = 1'b0;

		case (weight_mem_wr_sel)
			2'b00:
				begin
					weight_1_wr_en = wrEn_StatWr_G_i;
				end
			2'b01:
				begin
					weight_2_wr_en = wrEn_StatWr_G_i;
				end
			2'b10:
				begin
					weight_3_wr_en = wrEn_StatWr_G_i;
				end
			2'b11:
				begin
					weight_4_wr_en = wrEn_StatWr_G_i;
				end
			default:
				begin
				  	weight_1_wr_en = 1'b0;
					weight_2_wr_en = 1'b0;
					weight_3_wr_en = 1'b0;
					weight_4_wr_en = 1'b0;
				end
		endcase

	end

	always @(posedge clk_i)
        begin
	        if (weight_recall_1_rd_en == 1'b1)
	            weight_1_rd_addr_reg <= weight_recall_rd_addr;
		    if (weight_1_wr_en == 1'b1)
			    Mem_Weight_1[weight_mem_wr_addr] <= data_StatWr_G_i;
        end
    assign weight_mem_1_out = Mem_Weight_1[weight_1_rd_addr_reg];

	always @(posedge clk_i)
        begin
	        if (weight_recall_2_rd_en == 1'b1)
	            weight_2_rd_addr_reg <= weight_recall_rd_addr;
		    if (weight_2_wr_en == 1'b1)
			    Mem_Weight_2[weight_mem_wr_addr] <= data_StatWr_G_i;
        end
    assign weight_mem_2_out = Mem_Weight_2[weight_2_rd_addr_reg];

		always @(posedge clk_i)
        begin
	        if (weight_recall_3_rd_en == 1'b1)
	            weight_3_rd_addr_reg <= weight_recall_rd_addr;
		    if (weight_3_wr_en == 1'b1)
			    Mem_Weight_3[weight_mem_wr_addr] <= data_StatWr_G_i;
        end
    assign weight_mem_3_out = Mem_Weight_3[weight_3_rd_addr_reg];

	always @(posedge clk_i)
        begin
	        if (weight_recall_4_rd_en == 1'b1)
	            weight_4_rd_addr_reg <= weight_recall_rd_addr;
		    if (weight_4_wr_en == 1'b1)
			    Mem_Weight_4[weight_mem_wr_addr] <= data_StatWr_G_i;
        end
    assign weight_mem_4_out = Mem_Weight_4[weight_4_rd_addr_reg];

//fifo
generic_fifo_sc_b
#(
	.dw(DSIZE),
	.aw(9)
)
weight_fifo_2
(
	.clk(clk_i), 
	.rst(rst_n_i), 
	.clr(start_i), 
	.din(data_e), 
	.we(fifo_write_enable), 
	//.dout(data_f), 
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
	//.dout(data_StatRd_F_o), 
	.dout(), 
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