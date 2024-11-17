// *============================================================================================== 
// *
// *   AT25SF128A.v - 128M-BIT CMOS Serial Flash Memory
// *
// *----------------------------------------------------------------------------------------------
// * Environment  : Cadence NC-Verilog
// * Description  : There is only one module in this file
// *                module AT25SF128A->behavior model for the 128M-Bit flash
// *----------------------------------------------------------------------------------------------
// * Note 1:model can load initial flash data from file when parameter CELL_DATA = "xxx" was defined; 
// *        xxx: initial flash data file name;default value xxx = "empty", initial flash data is "FF".
// * Note 2:power setup time is tVSL = 300_000 ns, so after power up, chip can be enable.
// * Note 3:because it is not checked during the Board system simulation the tCLQX timing is not
// *        inserted to the read function flow temporarily.
// * Note 4:more than one values (min. typ. max. value) are defined for some AC parameters in the
// *        datasheet, but only one of them is selected in the behavior model, e.g. program and
// *        erase cycle time is typical value. For the detailed information of the parameters,
// *        please refer to datasheet.
// *============================================================================================== 
// * timescale define
// *============================================================================================== 
`timescale 1ns / 100ps

// *============================================================================================== 
// * product parameter define
// *============================================================================================== 
    /*----------------------------------------------------------------------*/
    /* all the parameters users may need to change                          */
    /*----------------------------------------------------------------------*/
        `define CELL_DATA       "empty"      // Flash data file name for normal array
        `define CELL_DATA_SEC   "empty"      // Flash data file name for security region
        `define STATUS_REG1    	8'h00        // status register 1 are non-volatile bits
        `define STATUS_REG2    	8'h00        // status register 2 are non-volatile bits
        `define STATUS_REG3    	8'h00        // status register 3 are non-volatile bits
    /*----------------------------------------------------------------------*/
    /* Define controller STATE						    */
    /*----------------------------------------------------------------------*/
		    `define		IDLE		 0
        `define		CMD		   1
        `define		BACK_CMD 2

module AT25SF128A( SCLK, 
		    					CS_N, 
		    					SI, 
		    					SO,
		    					HOLD_N, 
		    					WP_N
		    					);

		// *============================================================================================== 
		// * Declaration of ports (input, output, inout)
		// *============================================================================================== 
    input  SCLK;      // Signal of Clock Input
    input  CS_N;	    // Chip select (Low active)
    inout  SI;	      // Serial Input/Output 
    inout  SO;	      // Serial Input/Output 
    inout  WP_N;      // Serial Input/Output  
    inout  HOLD_N;    // Serial Input/Output  

		// *============================================================================================== 
		// * Declaration of parameter (parameter)
		// *============================================================================================== 
    /*----------------------------------------------------------------------*/
    /* Density STATE parameter						    */  		
    /*----------------------------------------------------------------------*/
    parameter	 ADDR_MSB				 = 23,		
					      TOP_Add					= 24'hffffff,
					      Secur_TOP_Add   = 15'h7fff,
					      Secur_MSB				= 14,
					      ADDR_MSB_OTP		= 14,		
					      Sector_MSB			= 11,
					      Buffer_Num      = 256,     
					      Block_MSB				= 7,
					      Block_NUM				= 256;
  
    /*----------------------------------------------------------------------*/
    /* Define ID Parameter						    */
    /*----------------------------------------------------------------------*/
    parameter	 ID_Manufacturer	 = 8'h1F,
					      ID_Device					= 8'h17,
					      Memory_Type				= 8'h89,
					      Memory_Capacity		= 8'h01;

    /*----------------------------------------------------------------------*/
    /* Define Initial Memory File Name					    */
    /*----------------------------------------------------------------------*/
    parameter   CELL_DATA			= `CELL_DATA;      // initial flash data
	  parameter   CELL_DATA_SEC	= `CELL_DATA_SEC;  // initial flash data for security
    
    /*----------------------------------------------------------------------*/
    /* AC Characters Parameter						    */
    /*----------------------------------------------------------------------*/
    parameter  tSHQZ	 = 6,	    					 	 // CS_N High to SO Float Time [ns]
								tCLQV		= 7,	    						// Clock Low to Output Valid
                tCLQX   = 0,       						// Output hold time 			[min]
             		tBP  		= 30_000,      				// Byte program time     	[type]
             		tPP  		= 600_000,      			// Page program time     	[type]
             		tSE			= 50_000_000,    			// Sector erase time     	[type]
					      tBE			= 250_000_000,    		// Block erase time      	[type]
                tBE32   = 150_000_000,    		// Block 32KB erase time 	[type]
					      tCE			= 60_000,     				// unit is ms instead of ns [type]
                tW 			= 5_000_000,     		  // Write Status time 				[type]
                tWEL		= 10,									// Write Status Register time	[type]
              	tVSL		= 300_000, 						// Time delay to chip select allowed
              	tSUS		= 20_000;					    // CS_N High From Suspend To Next Instruction 

    parameter	 tPGM_CHK	= 2_000,						 // 2 us
								tERS_CHK = 100_000;					  // 100 us 

    specify
	  specparam  tSCLK   = 9.2,    // Clock Cycle Time [ns]
		 			 		  fSCLK   = 108,    // Clock Frequence except READ instruction[ns] 15pF
		 			 		  tRSCLK  = 18,   	// Clock Cycle Time for READ instruction[ns] 15pF
		 			 		  fRSCLK  = 55,   	// Clock Frequence for READ instruction[ns] 15pF
		 			 		  tCH	    = 4,	    // Clock High Time (min) [ns]
		 			 		  tCL	    = 4,	    // Clock Low  Time (min) [ns]
		 			 		  tSLCH   = 5,    	// CS_N Active Setup Time (relative to SCLK) (min) [ns]
		 			 		  tCHSL   = 5,    	// CS_N Not Active Hold Time (relative to SCLK)(min) [ns]
		 			 		  tSHSL   = 20,    	// CS_N High Time for write instruction (min) [ns]
		 			 		  tDVCH   = 2,    	// SI Setup Time (min) [ns]
		 			 		  tCHDX   = 2,    	// SI Hold	Time (min) [ns]
		 			 		  tCHSH   = 5,    	// CS_N Active Hold Time (relative to SCLK) (min) [ns]
		 			 		  tSHCH   = 5,    	// CS_N Not Active Setup Time (relative to SCLK) (min) [ns]
		 			 		  tWHSL   = 20,    	// Write Protection Setup Time		  
		 			 		  tSHWL   = 100,    // Write Protection Hold  Time   
                tDP     = 20_000, // CS_N High To Deep Power Down Mode
                tRES1   = 20_000,
                tRES2   = 20_000;    
    endspecify

    /*----------------------------------------------------------------------*/
    /* Define Command Parameter						    */
    /*----------------------------------------------------------------------*/
    parameter	 WREN	    	     = 8'h06, 		// WriteEnable   
								WRDI	    	    = 8'h04, 		// WriteDisable 
								VSR_EN	 		    = 8'h50, 	  // Write Enable for Volatile Status Register 
									  
								RDSR	   	      = 8'h05, 		// ReadStatus	  
								RDSR2           = 8'h35, 		// Read configuration register SR2    
								RDSR3						= 8'h15,		// Read configuration register SR3
    	          WRSR	    	    = 8'h01, 		// WriteStatus  
    	          WRSR2           = 8'h31, 		// Write configuration register SR2 
    	          WRSR3						= 8'h11,		// Write configuration register SR3
    	          
    	          NORMAL_READ	    = 8'h03, 		// ReadData	  
    	          FAST_READ  	    = 8'h0b, 		// FastReadData          
    	          DUAL_OUT_READ 	= 8'h3b, 	  // Fast read dual output
    	          QUAD_OUT_READ   = 8'h6b, 	  // Fast read quad output
    	          DUAL_IO_READ 	  = 8'hbb, 	  // 2X Read     
    	          QUAD_IO_READ 	  = 8'heb, 	  // 4XI/O FastRead; 
    	          QUAD_IO_WDRD 	  = 8'he7, 	  // 4XI/O WordRead;
                BURST	 			    = 8'h77, 	  // Set Burst with Wrap 

    	          PP	    		    = 8'h02, 		// PageProgram     
    	          FP	    		    = 8'hf2, 		// FastPageProgram
    	          QPP	    		    = 8'h32, 		// QuadPageProgram   
    	           	          	          
    	          SE	    		    = 8'h20, 		// SectorErase   
                BE2             = 8'h52, 		// 32k block erase
                BE	    		    = 8'hd8, 		// 64k blockErase	
    	          CE1	    		    = 8'h60, 		// ChipErase	  
    	          CE2	    		    = 8'hc7, 		// ChipErase	  
  
    	          DP	    		    = 8'hb9, 		// DeepPowerDown
    	          RDP	    		    = 8'hab, 		// ReleaseFromDeepPowerDwon 
    	          HPF							= 8'ha3,		// HighPerformanceMode
    	          
    	          RES	    		    = 8'hab, 		// ReadElectricID 
    	          REMS	    	    = 8'h90, 		// ReadElectricManufacturerDeviceID
    	          REMS_DUAL	    	= 8'h92, 		// ReadElectricManufacturerDeviceID By Dual
    	          REMS_QUAD	    	= 8'h94, 		// ReadElectricManufacturerDeviceID By Quad
  							RDID	    	    = 8'h9F, 		// Read JEDEC ID
                 
    	       	  RDSCUR	    	  = 8'h48, 	  // Read security  register;
    	          WRSCUR	    	  = 8'h42, 	  // Program security  register;
    	          ERSCUR	    	  = 8'h44, 	  // Erase security  register;
    	          RSFDP						= 8'h5a,		// Read Serial Flash Discoverabld Parameter;
                                
                RSTEN	    		  = 8'h66, 	  // reset enable
                RST	    		    = 8'h99, 	  // reset memory
                                 
                SUS	 			      = 8'h75, 	  // Program/Erase Suspend    
                RESUME	 		    = 8'h7a; 	  // Program/Erase resume          

    /*----------------------------------------------------------------------*/
    /* Declaration of internal-signal                                       */
    /*----------------------------------------------------------------------*/
    reg  [7:0]					  ARRAY[0:TOP_Add];  				// memory array
	  reg  [7:0]		 			  Secur_ARRAY_0[0:255]; 
	  reg  [7:0]		 			  Secur_ARRAY_1[0:255];
	  reg  [7:0]		 			  Secur_ARRAY_2[0:255];
	  reg  [7:0]		 			  Secur_ARRAY_3[0:255];
    reg  [7:0]		 			  Status_Reg;	    					// Status Register
    reg	 [7:0]      		  Status_Reg_2;
	  reg	 [7:0]	    		  Status_Reg_3;
    reg  [7:0]		 		  	Status_Cell;	    			  // Status array
    reg	 [7:0]      	  	Status_Cell_2;
    reg	 [7:0]      	  	Status_Cell_3;
    reg  [7:0]		 			  CMD_BUS;
    reg  [23:0]    			  SI_data_Reg;	    				// temp reg to store serial in
    reg  [7:0]    			  Dummy_A[0:255];    				// page size
    reg  [2:0]		 			  STATE;
    reg  [ADDR_MSB:0]	 	  Address;	    
    reg  [Sector_MSB:0]	 	Sector;	  
    reg  [Block_MSB:0] 		Block;	   
    reg  [Block_MSB+1:0] 	Block2;	
    reg	 [ADDR_MSB:0]		  Address_SUS;
       
    reg     SO_Reg;   
    reg     Chip_EN;
    reg     DP_Mode;	    // deep power down mode
    reg     Read_Mode;
    reg     Noumal_Read_Mode;
    reg     Noumal_Read_Chk;

    reg     tDP_Chk;
    reg     tRES1_Chk;
    reg     tRES2_Chk;

    reg     RDID_Mode;
    reg     RDSR_Mode;
    reg     RDSCUR_Mode;
    reg     Fast_Read_Mode;	
    reg     Page_prog_Mode;
    reg     ERSCUR_Mode;
    reg     SE_4K_Mode;
    reg     BE_Mode;
    reg     BE32K_Mode;
    reg     BE64K_Mode;
    reg     CE_Mode;
    reg     WRSR_Mode;
    reg     WRSR2_Mode;
    reg			WRSR3_Mode;
    reg     RES_Mode;
    reg     REMS_Mode;
    reg			REMS_Mode_Dual;
    reg			REMS_Mode_Quad;

    reg	    SCLK_EN;
    reg	    SO_OUT_EN;   // for SO
    reg	    SI_IN_EN;    // for SI
   
    reg     RST_CMD_EN;
    reg     W4Read_Mode;
    reg     HOLD_OUT_B;
    wire    HOLD_B_INT;

    wire    CS_N_INT;
    wire    WP_B_INT;
    wire    RESETB_INT;
    wire    SCLK; 
    wire    ISCLK;
    wire    WIP;
    wire    QE;
    wire    WEL;
    wire    SEC;
    wire    TB;
    wire    BP0;
    wire    BP1;
    wire    BP2;
    wire    CMP;
    wire    Dis_CE, Dis_WRSR;  

    event   WRSR_Event; 
    event   BE_Event;
    event   SE_4K_Event;
    event   ERSCUR_Event;
    event   CE_Event;
    event   PP_Event;
    event   BE32K_Event;
    event   RST_Event;
    event   RST_EN_Event;
    event		SUS_Event;
    event		RESUME_Event;
    event		BURST_Event;
    event		RES_PP_Event;

    integer i;
    integer j;
    integer Bit; 
    integer Bit_Tmp; 
    integer Start_Add;
    integer End_Add;
    integer tWRSR;
    reg 		EN_Burst;
    integer Burst_Length;
    reg 		Read_SHSL;
    wire 	  Write_SHSL;

    reg     DUAL_IO_READ_Mode;
    reg     DUAL_IO_READ_Chk;

    reg     Byte_PGM_Mode;	    
    reg	    SI_OUT_EN;   // for SI
    reg	    SO_IN_EN;    // for SO
    reg     SI_Reg;
   
    reg     WP_N_Reg;
    reg     HOLD_N_Reg;
    reg     QUAD_IO_Mode;
    reg			QUAD_IO_WDMD;
    reg     QUAD_Mode;
    reg     QUAD_IO_Chk;
    reg			QUAD_IO_WD_Chk;
    reg     DUAL_OUT_Mode;
    reg     QUAD_OUT_Mode;
    reg     DUAL_OUT_Chk;
    reg     QUAD_OUT_Chk;

    reg     QPP_Mode;
    reg     PP_Load;
    reg     PP_Chk; 
    reg	    WP_OUT_EN;   // for WP_N pin
    reg	    HOLD_N_OUT_EN; // for HOLD_N pin
    reg	    WP_IN_EN;    // for WP_N pin
    reg	    HOLD_N_IN_EN;  // for HOLD_N pin
    reg     During_RST_REC;
    wire    HOLD_N;

	  reg 			flag_sr1;
	  reg 			flag_sr2;
	  reg 			flag_sr3;
	  reg 			suspend;
	  reg 			read_scur;
	  reg 			wr_scur;
	  reg				WELVOL;
	  reg				ACOTP;
	  reg				ACSR;
	  reg				SE_4K_Mode_SUS;
	  reg				BE32K_Mode_SUS;
	  reg				BE64K_Mode_SUS;
	  reg				QPP_Mode_SUS;
	  reg				Page_prog_Mode_SUS;
	  reg				Byte_PGM_Mode_SUS; 
    
	  reg[1:0] M54_D;
	  reg[1:0] M54_Q;
	  reg[1:0] M54_W;
	  reg[1:0] M54_D_buff;
	  reg[1:0] M54_Q_buff;
	  reg[1:0] M54_W_buff;
    
	  reg DUAL_M;
	  reg QUAD_M;
    reg [15:0] rst_data_Reg;

    /*----------------------------------------------------------------------*/
    /* initial variable value						    */
    /*----------------------------------------------------------------------*/
    initial begin
        
        Chip_EN         = 1'b0;
		    Status_Reg      = `STATUS_REG1;
        Status_Reg_2    = `STATUS_REG2;
        Status_Reg_3    = `STATUS_REG3;
        Status_Cell     = `STATUS_REG1;
        Status_Cell_2   = `STATUS_REG2;
        Status_Cell_3   = `STATUS_REG3;
        QUAD_Mode     	= 1'b0;
        WELVOL					= 1'b0;
	      reset_sm;
    end   

    task reset_sm; 
		begin
        flag_sr1				= 0;
        flag_sr2				= 0;
        flag_sr3				= 0;
				suspend					= 0;
				read_scur				= 0;
				wr_scur					= 0;
                          
				DUAL_M					= 0;
				QUAD_M					= 0;
				M54_D						= 0;
				M54_Q						= 0;
				M54_W						= 0;
				M54_D_buff			= 0;
				M54_Q_buff			= 0;
				M54_W_buff			= 0;
				
        During_RST_REC  = 1'b0;
        SI_Reg        	= 1'b1;
        SO_Reg        	= 1'b1;
        WP_N_Reg        = 1'b1;
        HOLD_N_Reg      = 1'b1;
        RST_CMD_EN      = 1'b0;
				SO_OUT_EN	    	= 1'b0; // SO output enable
				SI_IN_EN	    	= 1'b0; // SI input enable
				CMD_BUS	    		= 8'b0000_0000;
				Address	    		= 0;
				i		    				= 0;
				j		    				= 0;
				Bit		    			= 0;
				Bit_Tmp	    		= 0;
				Start_Add	    	= 0;
				End_Add	    		= 0;
				DP_Mode	    		= 1'b0;
				SCLK_EN	    		= 1'b1;
				Read_Mode	    	= 1'b0;
				Noumal_Read_Mode  = 1'b0;
				Noumal_Read_Chk   = 1'b0;
        tDP_Chk         = 1'b0;
        tRES1_Chk       = 1'b0;
        tRES2_Chk       = 1'b0;
        HOLD_OUT_B      = 1'b1;

        RDID_Mode       = 1'b0;
        RDSR_Mode       = 1'b0;

				Page_prog_Mode  = 1'b0;
				ERSCUR_Mode	    = 1'b0;
				SE_4K_Mode	    = 1'b0;
				BE_Mode	    		= 1'b0;
        BE32K_Mode      = 1'b0;
        BE64K_Mode      = 1'b0;
				CE_Mode	    		= 1'b0;
				WRSR_Mode	    	= 1'b0;
        WRSR2_Mode      = 1'b0;
        WRSR3_Mode      = 1'b0;
				RES_Mode	    	= 1'b0;
				REMS_Mode	    	= 1'b0;
				REMS_Mode_Dual  = 1'b0;
				REMS_Mode_Quad 	= 1'b0;
        Read_SHSL 	    = 1'b0;
				Fast_Read_Mode  = 1'b0;
				DUAL_OUT_Mode  	= 1'b0;
        QUAD_OUT_Mode  	= 1'b0;
				SI_OUT_EN	    	= 1'b0; // SI output enable
				SO_IN_EN	    	= 1'b0; // SO input enable
				DUAL_IO_READ_Mode  = 1'b0;
				DUAL_IO_READ_Chk   = 1'b0;
				Byte_PGM_Mode   = 1'b0;
				WP_OUT_EN	    	= 1'b0; // for WP_N pin output enable
				HOLD_N_OUT_EN	  = 1'b0; // for HOLD_N pin output enable
				WP_IN_EN	    	= 1'b0; // for WP_N pin input enable
				HOLD_N_IN_EN	  = 1'b0; // for HOLD_N pin input enable
				QUAD_IO_Mode  	= 1'b0;
				QUAD_IO_WDMD		= 1'b0;
				W4Read_Mode     = 1'b0;
				QUAD_IO_Chk   	= 1'b0;
				QUAD_IO_Chk			= 1'b0;
				QPP_Mode    		= 1'b0;
        PP_Load    			= 1'b0;
        PP_Chk     			= 1'b0;
        DUAL_OUT_Chk 		= 1'b0;
        QUAD_OUT_Chk 		= 1'b0;
				ACOTP						= 1'b0;
				ACSR						= 1'b0;
				SE_4K_Mode_SUS         = 1'b0;
				BE32K_Mode_SUS         = 1'b0;
				BE64K_Mode_SUS         = 1'b0;
				QPP_Mode_SUS           = 1'b0;
				Page_prog_Mode_SUS     = 1'b0;
				Byte_PGM_Mode_SUS      = 1'b0;
				Address_SUS            = 0;
        EN_Burst          		 = 1'b0;
        Burst_Length      		 = 8;
				rst_data_Reg					 = 0;    
		end
    endtask // reset_sm
    
    /*----------------------------------------------------------------------*/
    /* initial flash data    						    */
    /*----------------------------------------------------------------------*/
    initial 
    begin : memory_initialize
	      for ( i = 0; i <=  TOP_Add; i = i + 1 )
	          ARRAY[i] = 8'hff; 
	          
	      if ( CELL_DATA != "empty" )
	          $readmemh("CELL_DATA",ARRAY) ;
          
	      for( i = 0; i <=  255; i = i + 1 ) begin	      		
	          Secur_ARRAY_0[i] = 8'hff;
	          Secur_ARRAY_1[i] = 8'hff;
	          Secur_ARRAY_2[i] = 8'hff;
	          Secur_ARRAY_3[i] = 8'hff;
	      end 
	      
        if ( CELL_DATA_SEC != "empty" )begin
            $readmemh("Secur_ARRAY",Secur_ARRAY_0);   
            $readmemh("Secur_ARRAY",Secur_ARRAY_1);
            $readmemh("Secur_ARRAY",Secur_ARRAY_2);
            $readmemh("Secur_ARRAY",Secur_ARRAY_3);
        end
	  end
    // *============================================================================================== 
    // * Input/Output bus opearation 
    // *============================================================================================== 
    assign 	 ISCLK      = ((SCLK_EN == 1'b1)&&(HOLD_B_INT)) ? SCLK:1'b0;
    assign 	 CS_N_INT   = ( During_RST_REC == 1'b0 ) ? CS_N : 1'b1;
    assign 	 WP_B_INT   = ( Status_Reg_2[1] == 1'b0) ? ((WP_N==1'b0)? 1'b0:1'b1): 1'b1;        
    assign 	 HOLD_B_INT = ( Status_Reg_2[1] == 1'b0  && CS_N_INT == 1'b0 ) ? ((HOLD_N==1'b0)?1'b0:1'b1) : 1'b1;
   
    //----output
	  assign   SO       = (SO_OUT_EN && HOLD_OUT_B) ? SO_Reg : 1'bz ;
    assign   SI       = (SI_OUT_EN && HOLD_OUT_B) ? SI_Reg : 1'bz ;
    assign   WP_N     = (WP_OUT_EN && HOLD_OUT_B)  ? WP_N_Reg : 1'bz ;
    assign   HOLD_N   = (HOLD_N_OUT_EN && HOLD_OUT_B) ? HOLD_N_Reg : 1'bz ;

    // *============================================================================================== 
    // * Finite State machine to control Flash operation
    // *============================================================================================== 
    /*----------------------------------------------------------------------*/
    /* power on              						    */
    /*----------------------------------------------------------------------*/
    initial begin 
				Chip_EN   = #tVSL 1'b1;// Time delay to chip select allowed 
    end
    
    /*----------------------------------------------------------------------*/
    /* Command Decode        						    */
    /*----------------------------------------------------------------------*/
	  assign QE       = Status_Reg_2[1];
    assign WIP	    = Status_Reg[0];
    assign WEL	    = Status_Reg[1];
                    
    assign SEC      = Status_Reg[6];
    assign TB       = Status_Reg[5];
    assign CMP      = Status_Reg_2[6];
    assign BP0      = Status_Reg[2];
    assign BP1      = Status_Reg[3];
    assign BP2      = Status_Reg[4];
    assign LB1			= Status_Reg_2[3];         
    assign LB2			= Status_Reg_2[4];
    assign LB3			= Status_Reg_2[5];
    assign SUS1			= Status_Reg_2[7];
    assign SUS2			= Status_Reg_2[2];
    assign DRV1			= Status_Reg_3[6];
    assign DRV0			= Status_Reg_3[5];
    assign HPF_Mode = Status_Reg_3[4];
    
    assign Dis_CE   = CMP ? (BP0 == 1'b0 || BP1 == 1'b0 || BP2 == 1'b0) : (BP0 == 1'b1 || BP1 == 1'b1 || BP2 == 1'b1);
    //assign Dis_CE   = Status_Reg[4] == 1'b1 || Status_Reg[3] == 1'b1 || Status_Reg[2] == 1'b1; 
    assign Dis_WRSR = !(Status_Reg_2[0]==0 && (Status_Reg[7] == 1'b0 || WP_B_INT == 1'b1)); 
    assign BIT_TEMP = Bit;
     
    always @ ( negedge CS_N_INT ) begin
       SI_IN_EN = 1'b1; 
       #1;
       tDP_Chk = 1'b0;
       tRES1_Chk = 1'b0;
       tRES2_Chk = 1'b0;
    end

		always@(negedge CS_N_INT ) begin
				if(M54_Q == 2'b10 || M54_W == 2'b10)begin
					 SO_IN_EN = 1'b1; 
					 WP_IN_EN = 1'b1; 
					 HOLD_N_IN_EN = 1'b1; 
				end		
		end
		always@(negedge CS_N_INT ) begin
				if(M54_D == 2'b10)begin
					 SO_IN_EN = 1'b1; 
				end		
		end

		always@(posedge QPP_Mode) begin
				SI_IN_EN = 1'b1;
				SO_IN_EN = 1'b1; 
				WP_IN_EN = 1'b1; 
				HOLD_N_IN_EN = 1'b1;
		end
		
    //--------------------------ADDR INPUT    but no dual
    always @ ( posedge ISCLK or posedge CS_N_INT ) begin
	       if ( CS_N_INT == 1'b0 ) begin
             Bit_Tmp = Bit_Tmp + 1;
             Bit     = Bit_Tmp - 1;
	           if ( SI_IN_EN == 1'b1 && SO_IN_EN == 1'b1 && WP_IN_EN == 1'b1 && HOLD_N_IN_EN == 1'b1 ) begin
		            SI_data_Reg[23:0] = {SI_data_Reg[19:0], HOLD_N, WP_N, SO, SI};
	           end 
	           else  if ( SI_IN_EN == 1'b1 && SO_IN_EN == 1'b1 ) begin
		            SI_data_Reg[23:0] = {SI_data_Reg[21:0], SO, SI};
	           end
	           else begin 
		            SI_data_Reg[23:0] = {SI_data_Reg[22:0], SI};
	           end
				     rst_data_Reg[15:0] = {rst_data_Reg[14:0], SI};
	       end	

			   if(M54_D==2'b10 && CS_N_INT == 1'b0 )begin
			   	    CMD_BUS=DUAL_IO_READ;
			   	    STATE = `CMD;
			   end
		     else if(M54_Q==2'b10 && CS_N_INT == 1'b0 )begin
			   	    CMD_BUS=QUAD_IO_READ;
			   	    STATE = `CMD;
			   end
			   else if(M54_W==2'b10 && CS_N_INT == 1'b0 )begin
			   	    CMD_BUS=QUAD_IO_WDRD;
			   	    STATE = `CMD;
			   end
		     else if ( Bit == 7 && CS_N_INT == 1'b0) begin
	            STATE = `CMD;
	            CMD_BUS = SI_data_Reg[7:0];
              if ( During_RST_REC )
                   $display ($time," During reset recovery time, there is command. \n");
			   end
	       
	       case ( STATE )
	    	  	`IDLE: 
	          begin
	          end
          
	    	  	`CMD: 
	          begin
	              case ( CMD_BUS ) 
	              WREN: 
				  		  begin
				  		  		if ( !DP_Mode && !WIP && Chip_EN && !WELVOL) begin
				  		  				if ( CS_N_INT == 1'b1 && Bit == 7 ) begin										
				  		  						write_enable;
				  		  				end
				  		  				else if ( Bit > 7 )
				  		  						STATE <= `BACK_CMD; 
				  		  		end 
				  		  	  else if ( Bit == 7 )
				  		  				STATE <= `BACK_CMD; 
				  		  end
				  		  
				  		  VSR_EN: 
				  		  begin
				  		  		if ( !DP_Mode && !WIP && Chip_EN && !WEL) begin
				  		  				if ( CS_N_INT == 1'b1 && Bit == 7 ) begin										
				  		  						welvol_enable;
				  		  				end
				  		  				else if ( Bit > 7 )
				  		  						STATE <= `BACK_CMD; 
				  		  		end 
				  		  	  else if ( Bit == 7 )
				  		  				STATE <= `BACK_CMD; 
				  		  end
				  		  
				  			WRDI:   
				  			begin
				  					if ( !DP_Mode && !WIP && Chip_EN ) begin
	            	  			if ( CS_N_INT == 1'b1 && Bit == 7 ) begin											
				  									write_disable;
	            	  			end
	            	  			else if ( Bit > 7 )
				  								STATE <= `BACK_CMD; 
				  					end 
				  					else if ( Bit == 7 )
				  							STATE <= `BACK_CMD; 
				  			end 
         
                RDID:
                begin
				  					if ( !DP_Mode && !WIP && Chip_EN ) begin
                				Read_SHSL = 1'b1;
                		    RDID_Mode = 1'b1;
                		end
                		else if ( Bit == 7 )
                		   STATE <= `BACK_CMD;
                end
                        
	              RDSR:
				  			begin  
				  					if ( !DP_Mode && Chip_EN ) begin 
				  							Read_SHSL = 1'b1;
				  							RDSR_Mode = 1'b1 ;
				  							flag_sr1  = 1'b1;
              	  	end
				  					else if ( Bit == 7 )
				  							STATE <= `BACK_CMD; 	
				  			end
				  			
				  	  	RDSR2:                                                              
				  			begin 
				  					if ( !DP_Mode && Chip_EN ) begin 
				  							Read_SHSL = 1'b1;
				  							RDSR_Mode = 1'b1 ;
				  							flag_sr2  = 1'b1;
              	  	end
				  					else if ( Bit == 7 )
				  							STATE <= `BACK_CMD; 	
				  			end
				  			
				  			RDSR3:                                                              
				  			begin 
				  					if ( !DP_Mode && Chip_EN ) begin 
				  							Read_SHSL = 1'b1;
				  							RDSR_Mode = 1'b1 ;
				  							flag_sr3  = 1'b1;
              	  	end
				  					else if ( Bit == 7 )
				  							STATE <= `BACK_CMD; 	
				  			end
         
				  		  WRSR:
				  			begin
				  					if ( !DP_Mode && !WIP && (WEL || WELVOL) && Chip_EN && !suspend) begin
				  							if ( CS_N_INT == 1'b1 && Bit == 15 ) begin
				  									if ( Dis_WRSR ) begin 
				  											Status_Reg[1] = 1'b0; 
				  									end
				  									else if (CS_N_INT == 1'b1 && Bit == 15) begin 
				  											->WRSR_Event;
				  											WRSR_Mode = 1'b1;
				  											ACSR			= 1'b1;
				  									end
				  							end 
				  							else if ( CS_N_INT == 1'b1 && (Bit < 15 || Bit > 15 ) )
				  									STATE <= `BACK_CMD;
				  					end
				  					else if ( Bit == 7 )
				  						STATE <= `BACK_CMD;
				  			end 
				  			
				  			WRSR2:
				  			begin
				  					if ( !DP_Mode && !WIP && (WEL || WELVOL) && Chip_EN && !suspend) begin
				  							if ( CS_N_INT == 1'b1 && Bit == 15 ) begin
				  									if ( Dis_WRSR ) begin 
				  											Status_Reg[1] = 1'b0; 
				  									end
				  									else if (CS_N_INT == 1'b1 && Bit == 15) begin 
				  											->WRSR_Event;
				  											WRSR2_Mode = 1'b1;
				  											ACSR			 = 1'b1;
				  									end	
				  							end 
				  							else if ( CS_N_INT == 1'b1 && (Bit < 15 || Bit > 15 ) )
				  									STATE <= `BACK_CMD;
				  					end
				  					else if ( Bit == 7 )
				  						STATE <= `BACK_CMD;
				  			end
				  			
				  			WRSR3:
				  			begin
				  					if ( !DP_Mode && !WIP && (WEL || WELVOL) && Chip_EN && !suspend) begin
				  							if ( CS_N_INT == 1'b1 && Bit == 15 ) begin
				  									if ( Dis_WRSR ) begin 
				  											Status_Reg[1] = 1'b0; 
				  									end
				  									else if (CS_N_INT == 1'b1 && Bit == 15) begin 
				  											->WRSR_Event;
				  											WRSR3_Mode = 1'b1;
				  											ACSR			 = 1'b1;
				  									end	
				  							end 
				  							else if ( CS_N_INT == 1'b1 && (Bit < 15 || Bit > 15 ) )
				  									STATE <= `BACK_CMD;
				  					end
				  					else if ( Bit == 7 )
				  						STATE <= `BACK_CMD;
				  			end
                        
	              NORMAL_READ: 
				  			begin
				  					if ( !DP_Mode && !WIP && Chip_EN ) begin
				  							Read_SHSL = 1'b1;
				  							if ( Bit == 31 ) begin
				  									Address = SI_data_Reg [ADDR_MSB:0];
              	  	  	    load_address(Address);
				  							end
				  							Noumal_Read_Mode = 1'b1;
				  					end	
				  					else if ( Bit == 7 )
	            	  	    STATE <= `BACK_CMD;				
				  			end
         
	              FAST_READ:
	    	  			begin
	    	  	    		if ( !DP_Mode && !WIP && Chip_EN ) begin
                		    Read_SHSL = 1'b1;
	    	  							if ( Bit == 31 ) begin
              			    		Address = SI_data_Reg [ADDR_MSB:0];
              			    		load_address(Address);
	    	  							end
				  							Fast_Read_Mode = 1'b1;
	    	  	    		end	
	    	  	    		else if ( Bit == 7 )
	              		    STATE <= `BACK_CMD;				
	    	  			end
				  
	              SE: 
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && WEL && Chip_EN && !SUS1 ) begin
	    	  							if ( Bit == 31 ) begin
            		  					Address = SI_data_Reg [ADDR_MSB:0];
	    	  							end 
	    	  							
	    	  							if ( CS_N_INT == 1'b1 && Bit == 31 ) begin
	    	  							    ->SE_4K_Event;
	    	  							    SE_4K_Mode = 1'b1;
	    	  							end
	    	  							else if ( CS_N_INT == 1'b1 && Bit < 31 || Bit > 31 )
	          		  	    		STATE <= `BACK_CMD;
	    	  			  	end
	    	  			  	else if ( Bit == 7 )
	    	  							STATE <= `BACK_CMD;
	    	  			end
         
	              BE: 
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && WEL && Chip_EN && !SUS1 ) begin
	    	  							if ( Bit == 31 ) begin
            		  			    Address = SI_data_Reg [ADDR_MSB:0];
	    	  							end
	    	  							
	    	  							if ( CS_N_INT == 1'b1 && Bit == 31 ) begin
	    	  							    ->BE_Event;
	    	  							    BE_Mode = 1'b1;
            		  			    BE64K_Mode = 1'b1;
	    	  							end 
	    	  							else if ( CS_N_INT == 1'b1 && Bit < 31 || Bit > 31 )
	    	  							    STATE <= `BACK_CMD;
	    	  			    end 
	    	  			    else if ( Bit == 7 )
	    	  							STATE <= `BACK_CMD;
	    	  			end
         
                BE2:
                begin
                    if ( !DP_Mode && !WIP && WEL && Chip_EN && !SUS1 ) begin
                        if ( Bit == 31 ) begin
                            Address = SI_data_Reg [ADDR_MSB:0];
                        end
                        
                        if ( CS_N_INT == 1'b1 && Bit == 31  ) begin
                            ->BE32K_Event;
    		                    BE_Mode = 1'b1;
                            BE32K_Mode = 1'b1;
                        end
                        else if ( CS_N_INT == 1'b1 && Bit < 31 || Bit > 31 )
                            STATE <= `BACK_CMD;
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
                end
         
                        
	              CE1, CE2:
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && WEL && Chip_EN && !suspend) begin
	    	  							if ( CS_N_INT == 1'b1 && Bit == 7 ) begin
	    	  							    ->CE_Event;
	    	  							    CE_Mode = 1'b1 ;
	    	  							end 
	    	  							else if ( Bit > 7 )
	    	  							    STATE <= `BACK_CMD;
	    	  			    end
	    	  			    else if ( Bit == 7 ) 
	    	  							STATE <= `BACK_CMD;
	    	  			end
                        
	              PP, FP: 
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && WEL && Chip_EN && !SUS2 ) begin
	    	  							if ( Bit == 31 ) begin
            		  					Address = SI_data_Reg [ADDR_MSB:0];
            		  					load_address(Address);
	    	  							end
            		
	    	  							if ( Bit == 31 ) begin
            		  				  if ( CS_N_INT == 1'b0 ) begin
				  											->PP_Event;
				  											Page_prog_Mode = 1'b1;
				  											QPP_Mode = 1'b0;
            		  				  end  
	    	  							end
	    	  							else if ( CS_N_INT == 1 && (Bit < 31 || ((Bit + 1) % 8 !== 0)))
	    	  							    STATE <= `BACK_CMD;
	    	  					end
	    	  			  	else if ( Bit == 7 )
	          		  	    STATE <= `BACK_CMD;
	    	  			end
	    	  			
	    	  			QPP: 
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && WEL && Chip_EN && QE && !SUS2 ) begin
	    	  							if ( Bit == 31 ) begin
            		  					Address = SI_data_Reg [ADDR_MSB:0];
            		  					load_address(Address);
	    	  							end
            		
	    	  							if ( Bit == 31 ) begin
            		  				  if ( CS_N_INT == 1'b0 ) begin
				  											->PP_Event;
				  											Page_prog_Mode = 1'b1;
				  											QPP_Mode = 1'b1;
            		  				  end  
	    	  							end
	    	  							else if ( CS_N_INT == 1 && (Bit < 31 || ((Bit - 31) % 2 != 0)))begin
	    	  							    STATE <= `BACK_CMD;
	    	  							end
	    	  					end
	    	  			  	else if ( Bit == 7 )
	          		  	    STATE <= `BACK_CMD;
	    	  			end
         
                DP:
                begin
                    if ( !WIP && Chip_EN && !suspend) begin
                        if ( CS_N_INT == 1'b1 && Bit == 7 && DP_Mode == 1'b0 ) begin
                            tDP_Chk = 1'b1;
                            if(HPF_Mode == 1'b1)
                            		Status_Reg_3[4] = 1'b0;
                            else
                            		DP_Mode = 1'b1;
                        end
                        else if ( Bit > 7 )
                            STATE <= `BACK_CMD;
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
                end
                
                HPF:
                begin
                    if ( !WIP && Chip_EN && !DP_Mode ) begin
                        if ( CS_N_INT == 1'b1 && Bit == 7) begin
                            Status_Reg_3[4] = 1'b1;
                        end
                        else if ( Bit > 7 )
                            STATE <= `BACK_CMD;
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
                end
         
                RDP, RES:
                begin
                    if ( !WIP && Chip_EN ) begin
                        RES_Mode = 1'b1;
                        Read_SHSL = 1'b1;
                        if ( CS_N_INT == 1'b1 && ISCLK == 1'b0 && tRES1_Chk &&(Bit >= 38) ) begin
                            tRES1_Chk = 1'b0;
                            tRES2_Chk = 1'b1;
                            DP_Mode = 1'b0;
                        end
                        else if ( CS_N_INT == 1'b1 && ISCLK == 1'b1 && tRES1_Chk && (Bit >= 39 )) begin
                            tRES1_Chk = 1'b0;
                            tRES2_Chk = 1'b1;
                            DP_Mode = 1'b0;
                        end
                        else if ( CS_N_INT == 1'b1 && Bit > 0 && DP_Mode ) begin
                            tRES1_Chk = 1'b1;
                            DP_Mode = 1'b0;
                        end
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
                end
         
	              REMS:
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && Chip_EN ) begin
	    	  							if ( Bit == 31 ) begin
	    	  							    Address = SI_data_Reg[ADDR_MSB:0] ;
	    	  							end
            		  			Read_SHSL = 1'b1;
	    	  							REMS_Mode = 1'b1;
	    	  			  	end
	    	  			  	else if ( Bit == 7 )
	          		  	    STATE <= `BACK_CMD;			    
	    	  			end

	              REMS_DUAL:
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && Chip_EN ) begin
	    	  							if ( Bit == 19 ) begin
	    	  							    Address = SI_data_Reg[ADDR_MSB:0] ;
	    	  							end
            		  			Read_SHSL = 1'b1;
	    	  							REMS_Mode = 1'b1;
	    	  							REMS_Mode_Dual = 1'b1;
	    	  			  	end
	    	  			  	else if ( Bit == 7 )
	          		  	    STATE <= `BACK_CMD;			    
	    	  			end
	    	  			
	    	  			REMS_QUAD:
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && Chip_EN && QE) begin
	    	  							if ( Bit == 13 ) begin
	    	  							    Address = SI_data_Reg[ADDR_MSB:0] ;
	    	  							end
            		  			Read_SHSL = 1'b1;
	    	  							REMS_Mode = 1'b1;
	    	  							REMS_Mode_Quad = 1'b1;
	    	  			  	end
	    	  			  	else if ( Bit == 7 )
	          		  	    STATE <= `BACK_CMD;			    
	    	  			end
	    	  			         
	              DUAL_IO_READ: 
	    	  			begin 
	    	  			    if ( !DP_Mode && !WIP && Chip_EN ) begin
            		    		Read_SHSL = 1'b1;
	    	  							if ( Bit == 19 && (M54_D!=2'b10)) begin
				  									Address = SI_data_Reg [ADDR_MSB:0];
				  									load_address(Address);
				  							end
				  							else if( Bit == 11 && (M54_D==2'b10))begin
				  									Address = SI_data_Reg [ADDR_MSB:0];
				  									load_address(Address);
				  							end 
	    	  							DUAL_IO_READ_Mode = 1'b1;
	    	  					end	
	    	  					else if ( Bit == 7 )
	          				    STATE <= `BACK_CMD;				
	    	  			end 	
         
              	RDSCUR, RSFDP: 
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && Chip_EN ) begin
            		    		Read_SHSL = 1'b1;
	    	  							if ( Bit == 31 ) begin
            		  					Address = SI_data_Reg [ADDR_MSB:0];
            		  					load_address(Address);
	    	  							end
            		
				  							Fast_Read_Mode = 1'b1;
				  				 			read_scur=1;
				  				 			ACOTP = 1'b1;          		
	    	  			    end	
	    	  			    else if ( Bit == 7 )
	          		        STATE <= `BACK_CMD;							
	    	  			end                        
                        
	              WRSCUR: 
	    	  			begin
				  					if ( !DP_Mode && !WIP && WEL && Chip_EN && !suspend) begin
	    	  							if ( Bit == 31 ) begin
            				  			Address = SI_data_Reg [ADDR_MSB:0];
            				  			load_address(Address);
	    	  							end
            				  	
	    	  							if ( Bit == 31 ) begin
            				  	    if ( CS_N_INT == 1'b0 ) begin
				  											->PP_Event;
				  											Page_prog_Mode = 1'b1;
				  											wr_scur		= 1;
				  											ACOTP 		= 1'b1;
				  											QPP_Mode  = 1'b0;
            				         end  
	    	  							end
	    	  							else if ( CS_N_INT == 1 && (Bit < 31 || ((Bit + 1) % 8 !== 0)))
	    	  							    STATE <= `BACK_CMD;
	    	  					end
	    	  					else if ( Bit == 7 )
	          				  	STATE <= `BACK_CMD;
	    	  			end				  
				  
				  			ERSCUR:
				  			begin
	    	  				  if ( !DP_Mode && !WIP && WEL && Chip_EN && !suspend) begin
	    	  							if ( Bit == 31 ) begin
          			    				Address = SI_data_Reg [ADDR_MSB:0];
	    	  							end
	    	  							if ( CS_N_INT == 1'b1 && Bit == 31 ) begin
	    	  							    ->ERSCUR_Event;
	    	  							    ERSCUR_Mode = 1'b1;
	    	  							    ACOTP = 1'b1;
	    	  							end
	    	  							else if ( CS_N_INT == 1'b1 && Bit < 31 || Bit > 31 )
	        			            STATE <= `BACK_CMD;
	    	  				  end
	    	  				  else if ( Bit == 7 )
	    	  							STATE <= `BACK_CMD;
	    	  			end
                        
	              QUAD_IO_READ:
				  			begin
	    	  	    		if ( !DP_Mode && !WIP && QE && Chip_EN ) begin
                    		Read_SHSL = 1'b1;
                    		if ( Bit == 13 && (M54_Q != 2'b10) ) begin
				  									Address = SI_data_Reg [ADDR_MSB:0];
				  									load_address(Address);
				  							end
				  							else if(Bit == 5 && (M54_Q == 2'b10) ) begin
				  									Address = SI_data_Reg [ADDR_MSB:0];
				  									load_address(Address);
				  							end
				  							QUAD_IO_Mode = 1'b1;
				  							QUAD_Mode    = 1'b1;
				  					end
				  					else if ( Bit == 7 )
				  							STATE <= `BACK_CMD;			    
				  			end
				  			
				  		  QUAD_IO_WDRD:
				  			begin
	    	  	    		if ( !DP_Mode && !WIP && QE && Chip_EN ) begin
                    		Read_SHSL = 1'b1;
                    		if ( Bit == 13 && (M54_W != 2'b10) ) begin
				  									Address[ADDR_MSB:1] = SI_data_Reg [ADDR_MSB:1];
				  									Address[0] = 1'b0;
				  									load_address(Address);
				  							end
				  							else if(Bit == 5 && (M54_W == 2'b10) ) begin
				  									Address[ADDR_MSB:1] = SI_data_Reg [ADDR_MSB:1];
				  									Address[0] = 1'b0;
				  									load_address(Address);
				  							end
				  							QUAD_IO_WDMD = 1'b1;
				  							QUAD_Mode    = 1'b1;
				  					end
				  					else if ( Bit == 7 )
				  							STATE <= `BACK_CMD;			    
				  			end
         
	              DUAL_OUT_READ:
	    	  			begin
	    	  			    if ( !DP_Mode && !WIP && Chip_EN ) begin
            		    		Read_SHSL = 1'b1;
	    	  							if ( Bit == 31 ) begin
            		  					Address = SI_data_Reg [ADDR_MSB:0];
            		  					load_address(Address);
	    	  							end
	    	  							DUAL_OUT_Mode =1'b1;
	    	  			    end
	    	  			    else if ( Bit == 7 )
	          		        STATE <= `BACK_CMD;			    
	    	  			end
                        
                QUAD_OUT_READ:
                begin
                    if ( !DP_Mode && !WIP && QE && Chip_EN ) begin
                        Read_SHSL = 1'b1;
                        if ( Bit == 31 ) begin
                            Address = SI_data_Reg[ADDR_MSB:0] ;
                            load_address(Address);
                        end
                        QUAD_OUT_Mode =1'b1;
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
                end
                  
                RSTEN:
                begin
                    if ( Chip_EN && !suspend && !DP_Mode) begin
                        if ( CS_N_INT == 1'b1 && Bit == 7 ) begin
				      							->RST_EN_Event;
                        end
                        else if ( Bit > 7 )
                            STATE <= `BACK_CMD;
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
                end
         
                RST:
                begin
                    if ( Chip_EN && RST_CMD_EN && !suspend && !DP_Mode) begin
                        if ( CS_N_INT == 1'b1 && Bit == 7 ) begin
                            ->RST_Event;
                        end
                        else if ( Bit > 7 )
                            STATE <= `BACK_CMD;
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
                end   
                	
				  			SUS:
				  			begin
				  					if( Chip_EN && !suspend && WIP && !DP_Mode && !ACOTP && !ACSR && !CE_Mode)begin
				  							if( CS_N_INT == 1'b1 && Bit == 7 ) begin
				  								-> SUS_Event;
				  							end
				  							else if ( Bit > 7 )
                            STATE <= `BACK_CMD;
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
				  			end
				  			
				  			RESUME:
				  			begin
				  					if( Chip_EN && suspend && !WIP && !DP_Mode) begin
				  							if( CS_N_INT == 1'b1 && Bit == 7 ) begin
				  									-> RESUME_Event;
				  							end
				  							else if ( Bit > 7 )
                            STATE <= `BACK_CMD;
                    end
                    else if ( Bit == 7 )
                        STATE <= `BACK_CMD;
				  			end
				  			
				  		  BURST:
				  			begin
				  					if ( !DP_Mode  && QE && Chip_EN ) begin
                  			if ((Bit == 15 && QE) ) begin
                  					-> BURST_Event;
				  							end
				  						  SI_IN_EN	= 1'b1;
				  							SO_IN_EN	= 1'b1;
				  							WP_IN_EN	= 1'b1;
				  							HOLD_N_IN_EN   = 1'b1;
				  					end
				  					else if ( Bit == 7 )
	              		    STATE <= `BACK_CMD;			    
				  			end

	              default: 
	    	  			begin
	    	  			    STATE <= `BACK_CMD;
	    	  			end
		      			endcase
	       		end
                   
	    	  	`BACK_CMD: 
	    	  	begin
	    	  	end
      	  	     
	    	  	default: 
	    	  	begin
	    	  			STATE =  `IDLE;
	    	  	end
			   endcase
    end

    //------------------------------

		always@(posedge ISCLK)begin
				if(DUAL_M)begin
						M54_D_buff<={SO, SI};
				end
		end
		
		always@(posedge CS_N_INT)begin
				M54_D <= M54_D_buff;
				M54_Q <= M54_Q_buff;
				M54_W <= M54_W_buff;
		end
		
		always@(posedge ISCLK)begin
				if(QUAD_M)begin
						if(QUAD_IO_Mode)
								M54_Q_buff<={SO, SI};
						else if(QUAD_IO_WDRD)
								M54_W_buff<={SO, SI};
				end
		end
		
    //------------------------------
    always @ (posedge CS_N_INT) begin
    		SI_Reg 						<= #tSHQZ 1'bx;
    		SO_Reg 						<= #tSHQZ 1'bx;
    		WP_N_Reg 					<= #tSHQZ 1'bx;
    		HOLD_N_Reg 				<= #tSHQZ 1'bx;
    		              		
	  		SO_OUT_EN    			<= #tSHQZ 1'b0;
	  		SI_OUT_EN   			<= #tSHQZ 1'b0;
	  		WP_OUT_EN    			<= #tSHQZ 1'b0;
	  		HOLD_N_OUT_EN 		<= #tSHQZ 1'b0;
    		
    		#1;
    		Bit         			= 1'b0;
    		Bit_Tmp     			= 1'b0;
    		            			
    		SO_IN_EN    			= 1'b0;
    		SI_IN_EN    			= 1'b0;
    		WP_IN_EN    			= 1'b0;
    		HOLD_N_IN_EN  		= 1'b0;
    		
    		RDID_Mode   			= 1'b0;
    		RDSR_Mode   			= 1'b0;
    		RDSCUR_Mode 			= 1'b0;
	  		Read_Mode					= 1'b0;
	  		RES_Mode					= 1'b0;
	  		REMS_Mode					= 1'b0;
	  		REMS_Mode_Dual  	= 1'b0;
				REMS_Mode_Quad 		= 1'b0;
    		
	  		Noumal_Read_Mode  = 1'b0;
	  		DUAL_IO_READ_Mode = 1'b0;
	  		QUAD_IO_Mode  		= 1'b0;
	  		QUAD_IO_WDMD  		= 1'b0;
	  		Noumal_Read_Chk   = 1'b0;
	  		DUAL_IO_READ_Chk  = 1'b0;
	  		QUAD_IO_Chk   		= 1'b0;
	  		QUAD_IO_Chk				= 1'b0;
	  		Fast_Read_Mode		= 1'b0;
    		DUAL_OUT_Mode			= 1'b0;
    		QUAD_OUT_Mode			= 1'b0;
    		DUAL_OUT_Chk			= 1'b0;
    		QUAD_OUT_Chk			= 1'b0;
	  		PP_Load    				= 1'b0;
    		PP_Chk     				= 1'b0;
	  		STATE 						<=  `IDLE;
    		
    		disable read_id;
    		disable read_status;
    		disable read_1xio;
    		disable read_2xio;
    		disable read_4xio;
    		disable fastread_1xio;
    		disable fastread_2xio;
    		disable fastread_4xio;
    		disable read_electronic_id;
    		disable read_electronic_manufacturer_device_id;
	  		disable read_function;
	  		disable dummy_cycle;
				flag_sr1					=0;
				flag_sr2					=0;
				flag_sr3					=0;
				read_scur					=0;
	  end
		
    /*----------------------------------------------------------------------*/
    /*	ALL function trig action            				    */
    /*----------------------------------------------------------------------*/
    always @ ( posedge Noumal_Read_Mode
	    				 or posedge Fast_Read_Mode
	    				 or posedge REMS_Mode
	    				 or posedge RES_Mode
	    				 or posedge DUAL_IO_READ_Mode
	    				 or posedge QUAD_IO_Mode 
	    				 or posedge QUAD_IO_WDMD
	    				 or posedge PP_Load 
	    				 or posedge DUAL_OUT_Mode
      				 or posedge QUAD_OUT_Mode
	   ) begin:read_function 
     		wait ( SCLK == 1'b0 );
		 		if ( Noumal_Read_Mode == 1'b1 ) begin
		 		    Noumal_Read_Chk = 1'b1;
		 		    read_1xio;
		 		end
		 		else if ( Fast_Read_Mode == 1'b1 ) begin
		 		    fastread_1xio;
		 		end
		 		else if ( DUAL_OUT_Mode == 1'b1 ) begin
  	 		    DUAL_OUT_Chk = 1'b1;
		 		    fastread_2xio;
		 		end   
     		else if ( QUAD_OUT_Mode == 1'b1 ) begin
     		    QUAD_OUT_Chk = 1'b1;
     		    fastread_4xio;
     		end
		 		else if ( REMS_Mode == 1'b1 ) begin
		 		    read_electronic_manufacturer_device_id;
		 		end 
		 		else if ( RES_Mode == 1'b1 ) begin
		 		    read_electronic_id;
		 		end
		 		else if ( DUAL_IO_READ_Mode == 1'b1 ) begin
		 		    DUAL_IO_READ_Chk = 1'b1;
		 		    read_2xio;
		 		end
		 		else if ( QUAD_IO_Mode == 1'b1 ) begin
		 		    QUAD_IO_Chk = 1'b1;
		 		    read_4xio;
		 		end  
		 		else if ( QUAD_IO_WDMD == 1'b1 ) begin
		 		    QUAD_IO_WD_Chk = 1'b1;
		 		    read_4xio;
		 		end 
     		else if ( PP_Load == 1'b1 ) begin
     		    PP_Chk = 1'b1;
     		end
    end	
    
		always @ ( SUS_Event ) begin
			  #tSUS;
				SE_4K_Mode_SUS 			= SE_4K_Mode;
				BE32K_Mode_SUS 			= BE32K_Mode;
				BE64K_Mode_SUS 			= BE64K_Mode;
				QPP_Mode_SUS 				= QPP_Mode;
				Page_prog_Mode_SUS 	= Page_prog_Mode;
				Byte_PGM_Mode_SUS		= Byte_PGM_Mode;
				Address_SUS 				= Address;
				suspend							= 1'b1;				
				Status_Reg[0]   		= 1'b0;
		    Status_Reg[1]   		= 1'b0;
				if( Page_prog_Mode )
						Status_Reg_2[2] = 1'b1;
				else
						Status_Reg_2[7] = 1'b1;
		end
		
		always @ ( RESUME_Event ) begin				 
				if(	SE_4K_Mode_SUS )begin  
						SE_4K_Mode        = SE_4K_Mode_SUS;
						->SE_4K_Event;						
				end
																	
				if( BE32K_Mode_SUS )begin
						BE32K_Mode        = BE32K_Mode_SUS;
						->BE32K_Event;
				end
						 						
				if( BE64K_Mode_SUS )begin
						BE64K_Mode        = BE64K_Mode_SUS;
						->BE_Event;
				end
						 		
				if( Page_prog_Mode_SUS )begin
						QPP_Mode          = QPP_Mode_SUS; 			
						Page_prog_Mode    = Page_prog_Mode_SUS;
						Byte_PGM_Mode			= Byte_PGM_Mode_SUS;
						->RES_PP_Event;
				end
						
				Address           = Address_SUS; 				
				Status_Reg[0]   	= 1'b1;			
				Status_Reg[1]   	= 1'b1;
				suspend           = 1'b0;
				Status_Reg_2[2] 	= 1'b0;				          
				Status_Reg_2[7] 	= 1'b0;
		end
		
		always @(RES_PP_Event) begin
			update_array(Address_SUS);
		end
		
    always @ ( RST_EN_Event ) begin
				RST_CMD_EN = #2 1'b1;
    end

    always @ ( RST_Event ) begin
        During_RST_REC = 1;
        #30000;
        disable write_status;
        disable block_erase_32k;
        disable block_erase;
        disable sector_erase_4k;
        disable erase_sec_reg;
        disable chip_erase;
        disable page_program; // can deleted
        disable update_array;
        disable read_id;
        disable read_status;
        disable read_1xio;
        disable read_2xio;
        disable read_4xio;
        disable fastread_1xio;
        disable fastread_2xio;
        disable fastread_4xio;
        disable read_electronic_id;
        disable read_electronic_manufacturer_device_id;
        disable read_function;
        disable dummy_cycle;

        reset_sm;
        QUAD_Mode 			= 1'b0;
        WELVOL 					= 1'b0;
        Status_Reg[1:0] = 2'b00;
        Status_Reg[7:2] = Status_Cell[7:2];
        Status_Reg_2[7] = 1'b0;
        Status_Reg_2[2] = 1'b0;
        Status_Reg_2[6:3] = Status_Cell_2[6:3];
        Status_Reg_2[1:0] = Status_Cell_2[1:0];
        Status_Reg_3[6:5] = Status_Cell_3[6:5];
				flag_sr1				= 0;
				flag_sr2				= 0;
				flag_sr3				= 0;
				suspend					= 0;
				wr_scur					= 0;
				read_scur				= 0;
    end
    
    always @ ( BURST_Event ) begin
    		EN_Burst = !SI_data_Reg[4] ;
				if(!SI_data_Reg[5] && !SI_data_Reg[6])
						Burst_Length = 8;
				else if(SI_data_Reg[5] && !SI_data_Reg[6])
						Burst_Length = 16;
				else if(!SI_data_Reg[5] && SI_data_Reg[6])
						Burst_Length = 32;
				else if(SI_data_Reg[5] && SI_data_Reg[6])
						Burst_Length = 64;
    end
    
    always @ ( posedge W4Read_Mode ) begin
         QUAD_Mode = 1'b0;
    end
 
    always @ ( posedge QUAD_Mode ) begin
         W4Read_Mode = 1'b0;
    end

    always @ ( WRSR_Event ) begin
				write_status;
    end

    always @ ( BE_Event ) begin
				block_erase;
    end

    always @ ( CE_Event ) begin
				chip_erase;
    end
    
    always @ ( PP_Event ) begin:page_program_mode
        page_program( Address );
    end
   
    always @ ( SE_4K_Event ) begin
				sector_erase_4k;
    end  
	 
	 	always @ ( ERSCUR_Event ) begin
				erase_sec_reg;
    end

    always @ ( posedge RDID_Mode ) begin
        read_id;
    end

    always @ ( posedge RDSR_Mode ) begin
        read_status;
    end

    always @ ( BE32K_Event ) begin
        block_erase_32k;
    end

		// *========================================================================================== 
		// * Module Task Declaration
		// *========================================================================================== 
    /*----------------------------------------------------------------------*/
    /*	Description: define a wait dummy cycle task			    */
    /*	INPUT							            */
    /*	    Cnum: cycle number						    */
    /*----------------------------------------------------------------------*/
    task dummy_cycle;
		input [31:0] Cnum;
		begin
		    repeat( Cnum ) begin
						@ ( posedge ISCLK );
		    end
		end
    endtask // dummy_cycle

    /*----------------------------------------------------------------------*/
    /*	Description: define a write enable task				    */
    /*----------------------------------------------------------------------*/
    task write_enable;
		begin
		    Status_Reg[1] = 1'b1; 
		end
    endtask // write_enable
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a write disable task (WRDI)			    */
    /*----------------------------------------------------------------------*/
    task write_disable;
		begin
		    Status_Reg[1]  = 1'b0;             
		end
    endtask // write_disable
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a write SR register enable task				    */
    /*----------------------------------------------------------------------*/
    task welvol_enable;
		begin
		    WELVOL = 1'b1; 
		end
    endtask // welvol_enable
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a read id task (RDID)			    */
    /*----------------------------------------------------------------------*/
    task read_id;
		reg  [23:0] Dummy_ID;
		integer Dummy_Count;
		begin
		    Dummy_ID	= {ID_Manufacturer, Memory_Type, Memory_Capacity};
		    Dummy_Count = 0;
		    forever begin
						@ ( negedge ISCLK or posedge CS_N_INT );
						if ( CS_N_INT == 1'b1 ) begin
						    disable read_id;
						end
						else begin
  	  					SO_OUT_EN = 1'b1;
  	  					SO_IN_EN  = 1'b0;
  	  					SI_IN_EN  = 1'b0;
  	  					WP_IN_EN  = 1'b0;
  	  					HOLD_N_IN_EN = 1'b0;
  	  					{SO_Reg, Dummy_ID} <= #tCLQV {Dummy_ID, Dummy_ID[23]};
						end
		    end  // end forever
		end
    endtask // read_id
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a read status task (RDSR)			    */
    /*----------------------------------------------------------------------*/
    task read_status;
		integer Dummy_Count;
		begin
  	     Dummy_Count = 8;
  	     forever begin
				 		@ ( negedge ISCLK or posedge CS_N_INT );
				 		if ( CS_N_INT == 1'b1 ) begin
				 				disable read_status;
				 		end
				 		else begin
  	  	 				SO_OUT_EN = 1'b1;
  	  	 				SO_IN_EN  = 1'b0;
  	  	 				SI_IN_EN  = 1'b0;
  	  	 				WP_IN_EN  = 1'b0;
  	  	 				HOLD_N_IN_EN = 1'b0;
				 			 	if ( Dummy_Count ) begin
				 						Dummy_Count = Dummy_Count - 1;  	  	 		    		                        
				 						if(flag_sr1)
				 								SO_Reg    <= #tCLQV Status_Reg[Dummy_Count];
				 						else if(flag_sr2)
				 								SO_Reg    <= #tCLQV Status_Reg_2[Dummy_Count]; 
				 						else if(flag_sr3)
				 								SO_Reg    <= #tCLQV Status_Reg_3[Dummy_Count];          
				 				end
				 				else begin
  	  	 		  	    Dummy_Count = 7;
				 						if(flag_sr1)
				 								SO_Reg    <= #tCLQV Status_Reg[Dummy_Count];
				 						else if(flag_sr2)
				 								SO_Reg    <= #tCLQV Status_Reg_2[Dummy_Count];  
				 						else if(flag_sr3) 
				 								SO_Reg    <= #tCLQV Status_Reg_3[Dummy_Count];   
				 				end		 
				 		end
		    end  // end forever
		end
    endtask // read_status

    /*----------------------------------------------------------------------*/
    /*	Description: define a write status task				    */
    /*----------------------------------------------------------------------*/
    task write_status;
    reg [7:0] Status_Reg_Up;
    //reg [7:0] CR_Up;
		begin
				if (WRSR_Mode == 1'b1 || WRSR2_Mode == 1'b1 || WRSR3_Mode == 1'b1) begin
  	      	Status_Reg_Up = SI_data_Reg[7:0] ;
  	    end
  	    
  	    if(WELVOL)
  	        tWRSR = tWEL;
  	    else if(WEL)
  	      	tWRSR = tW;	
  	    
  	    Status_Reg[0]   = 1'b1;
  	    #tWRSR;
  	    if( WRSR_Mode )
  	    begin
  	    		Status_Reg[7]   =  Status_Reg_Up[7];
		    		Status_Reg[6]   =  Status_Reg_Up[6];                                 
		    		Status_Reg[5:2] =  Status_Reg_Up[5:2];
		    		if(WEL)
		    		begin
		    				Status_Cell[7]   =  Status_Reg_Up[7];
		    				Status_Cell[6]   =  Status_Reg_Up[6];                                 
		    				Status_Cell[5:2] =  Status_Reg_Up[5:2];
		    		end
		    end
		    
  	    if( WRSR2_Mode )
  	    begin		    		
  	    		if(WEL)
  	    		begin
  	    				if(!LB1)
  	    				begin
  	    						Status_Reg_2[3] = Status_Reg_Up[3];
  	    						Status_Cell_2[3] = Status_Reg_Up[3];
  	    				end
  	    				
  	    				if(!LB2)
  	    				begin
  	    						Status_Reg_2[4] = Status_Reg_Up[4];
  	    						Status_Cell_2[4] = Status_Reg_Up[4];
  	    				end
  	    				
  	    				if(!LB3)
  	    				begin
  	    						Status_Reg_2[5] = Status_Reg_Up[5];	
  	    						Status_Cell_2[5] = Status_Reg_Up[5];	
  	    				end
  	    				Status_Cell_2[6] = Status_Reg_Up[6];
								Status_Cell_2[1:0] = Status_Reg_Up[1:0];
						end
	   				Status_Reg_2[6] = Status_Reg_Up[6];
						Status_Reg_2[1:0] = Status_Reg_Up[1:0];
				end
				
				if( WRSR3_Mode )
				begin
						if(WEL)
						begin							
								Status_Cell_3[6] = Status_Reg_Up[6];
								Status_Cell_3[5] = Status_Reg_Up[5];
						end
						Status_Reg_3[6] = Status_Reg_Up[6];
						Status_Reg_3[5] = Status_Reg_Up[5];
				end		    		 		
  			
		    Status_Reg[0]   = 1'b0;
		    Status_Reg[1]   = 1'b0;
		    WELVOL 					= 1'b0;
		    WRSR_Mode       = 1'b0;
		    WRSR2_Mode      = 1'b0;	
		    WRSR3_Mode      = 1'b0;		    
		    ACSR						= 1'b0;   	    		
		end
    endtask // write_status
   
    /*----------------------------------------------------------------------*/
    /*	Description: define a read data task				    */
    /*		     03 AD1 AD2 AD3 X					    */
    /*----------------------------------------------------------------------*/
    task read_1xio;
	  integer Dummy_Count, Tmp_Int;
	  reg  [7:0]	 OUT_Buf;
	  begin
	      Dummy_Count = 8;
        dummy_cycle(24);
        #1; 
        read_array(Address, OUT_Buf);
	      forever begin
	  				@ ( negedge ISCLK or posedge CS_N_INT );
	  				if ( CS_N_INT == 1'b1 ) begin
	  				    disable read_1xio;
	  				end 
	  				else begin 
	  				    Read_Mode	= 1'b1;
	  				    SO_OUT_EN	= 1'b1;
      			    SI_IN_EN    = 1'b0;
	  				    if ( Dummy_Count ) begin
	  				    		{SO_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[7]};
	  								Dummy_Count = Dummy_Count - 1;
	  				    end
	  				    else begin
	  								Address = Address + 1;
      			  			load_address(Address);
      			  			read_array(Address, OUT_Buf);
	  								{SO_Reg, OUT_Buf} <= #tCLQV  {OUT_Buf, OUT_Buf[7]};
	  								Dummy_Count = 7;
	  				    end
	  				end 
	      end  // end forever
	  end   
    endtask // read_1xio

    /*----------------------------------------------------------------------*/
    /*	Description: define a fast read data task			    */
    /*		     0B AD1 AD2 AD3 X					    */
    /*----------------------------------------------------------------------*/
    task fastread_1xio;
		integer Dummy_Count, Tmp_Int;
		reg  [7:0]	 OUT_Buf;
		begin
  	    Dummy_Count = 8;
		    dummy_cycle(32);
  	    read_array(Address, OUT_Buf);
		    forever begin
						@ ( negedge ISCLK or posedge CS_N_INT );
						if ( CS_N_INT == 1'b1 ) begin
						    disable fastread_1xio;
							  read_scur=0;
						end 
						else begin 
						    Read_Mode = 1'b1;
  	  			    SO_OUT_EN = 1'b1;
  	  			    SI_IN_EN  = 1'b0;
						    if ( Dummy_Count ) begin
						        {SO_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[7]};
										Dummy_Count = Dummy_Count - 1;
						    end
						    else begin
										Address = Address + 1;
  	  			        load_address(Address);
  	  			        read_array(Address, OUT_Buf);
  	  			        {SO_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[7]};
										Dummy_Count = 7 ;
						    end
						end    
		    end  // end forever
		end   
    endtask // fastread_1xio

    /*----------------------------------------------------------------------*/
    /*  Description: define a block erase task                              */
    /*               52 AD1 AD2 AD3                                         */
    /*----------------------------------------------------------------------*/
    task block_erase_32k;
    integer i;
    integer Start_Add;
    integer End_Add;
    begin
        Block         =  Address[ADDR_MSB:15];
        Block2        =  Address[ADDR_MSB:15];
        Start_Add     =  (Address[ADDR_MSB:15]<<15) + 16'h0;
        End_Add       =  (Address[ADDR_MSB:15]<<15) + 16'h7fff;
        Status_Reg[0] =  1'b1;
        if ( write_protect(Address) == 1'b1  ||  ( SUS2 && Address[ADDR_MSB:15] == Address_SUS[ADDR_MSB:15] )) begin   
						#tERS_CHK;
        end
        else begin
        		for( i = Start_Add; i <= End_Add; i = i + 1 )
            begin
            		if(!SUS1) begin
										#(tBE32/(End_Add-Start_Add)) ;
                		ARRAY[i] = 8'hff;
                end
            end            
        end
        Status_Reg[0] = 1'b0;//WIP
        Status_Reg[1] = 1'b0;//WEL
        BE_Mode 			= 1'b0;
        BE32K_Mode 		= 1'b0;
    end
    endtask // block_erase_32k
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a block erase task				    */
    /*		     D8 AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task block_erase;
		integer i;
    integer Start_Add;
    integer End_Add;
		begin
		    Block	=  Address[ADDR_MSB:16];
		    Block2	=  Address[ADDR_MSB:16];
		    Start_Add	= (Address[ADDR_MSB:16]<<16) + 16'h0;
		    End_Add	= (Address[ADDR_MSB:16]<<16) + 16'hffff;
		    Status_Reg[0] =  1'b1;
  	
		    if ( write_protect(Address) == 1'b1  ||  ( SUS2 && Address[ADDR_MSB:16] == Address_SUS[ADDR_MSB:16] )) begin
						#tERS_CHK;
		    end
		    else begin
		    		for( i = Start_Add; i <= End_Add; i = i + 1 )
  	    		begin
							 if(!SUS1) begin
							 		#(tBE/(End_Add-Start_Add)) ;
							 		ARRAY[i] = 8'hff;
							 end
  	        end
  	    end   
				Status_Reg[0] =  1'b0;//WIP
				Status_Reg[1] =  1'b0;//WEL
				BE_Mode 			= 1'b0;
  	    BE64K_Mode 		= 1'b0;
		end
    endtask // block_erase

    /*----------------------------------------------------------------------*/
    /*	Description: define a sector 4k erase task			    */
    /*		     20 AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task sector_erase_4k;
		integer i;
    integer Start_Add;
    integer End_Add;
	  begin
	      Sector				=  Address[ADDR_MSB:12]; 
	      Start_Add			= (Address[ADDR_MSB:12]<<12) + 12'h000;
	      End_Add				= (Address[ADDR_MSB:12]<<12) + 12'hfff;	      
	      Status_Reg[0] =  1'b1;
	      if ( write_protect(Address) == 1'b1 || ( SUS2 && Address[ADDR_MSB:12] == Address_SUS[ADDR_MSB:12] )) begin  
	          #tERS_CHK;
        end
	      else begin
        		for( i = Start_Add; i <= End_Add; i = i + 1 )
        		begin
	  						if(!SUS1) begin
	  					 			#(tSE/(End_Add-Start_Add));
	  					 			ARRAY[i] = 8'hff;
	  					 	end	  					
            end
	      end
	  	  Status_Reg[0] = 1'b0;//WIP
	  	  Status_Reg[1] = 1'b0;//WEL
	  	  SE_4K_Mode 		= 1'b0;
	  end
    endtask // sector_erase_4k
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a chip erase task				    */
    /*		     60(C7)						    */
    /*----------------------------------------------------------------------*/
    task chip_erase;
	  integer i;
	  integer k;
	  integer j;
    begin
        Status_Reg[0] =  1'b1;
    
        if ( Dis_CE == 1'b1  || (WP_B_INT == 1'b0) ) begin
            #tERS_CHK;
            Status_Reg[0] = 1'b1;
        end
        else begin
        		for( i = 0; i <Block_NUM; i = i+1 ) begin
	        			Address = (i<<16) + 16'h0;
	        			Start_Add = (i<<16) + 16'h0;
	        			End_Add   = (i<<16) + 16'hffff;	
	        			for( j = Start_Add; j <=End_Add; j = j + 1 )begin
	  	 							for ( k = 0;k<tCE/100;k = k + 1) begin
            						#(100_000_000/((End_Add-Start_Add)*(Block_NUM)));
            				end
	  		 						ARRAY[j] =  8'hff;
	        			end
	    			end
	      end
        Status_Reg[0] = 1'b0;//WIP
        Status_Reg[1] = 1'b0;//WEL
	      CE_Mode 			= 1'b0;
    end
    endtask // chip_erase	

    /*----------------------------------------------------------------------*/
    /*	Description: define a erase_sec_reg task			    */
    /*		     20 AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task erase_sec_reg;
		integer i;
		begin 
		    Status_Reg[0] =  1'b1;
		    if ( write_protect(Address) == 1'b0) begin 
  	    		for( i = 0; i <= 255; i = i + 1 )
  	    		begin
								#(tSE/256);
								case(Address[13:12])
        					2'b00:Secur_ARRAY_0[i] = 8'hff;        								
        					2'b01:Secur_ARRAY_1[i] = 8'hff;
        					2'b10:Secur_ARRAY_2[i] = 8'hff;
        					2'b11:Secur_ARRAY_3[i] = 8'hff;
        				endcase
  	    		end  
  	    end
  	    else begin
	          #tERS_CHK;
	      end
				Status_Reg[0] = 1'b0;//WIP
				Status_Reg[1] = 1'b0;//WEL
				ERSCUR_Mode 	= 1'b0;
				ACOTP 				= 1'b0;
		end
    endtask // erase_sec_reg
    /*----------------------------------------------------------------------*/
    /*	Description: define a page program task				    */
    /*		     02 AD1 AD2 AD3					    */
    /*----------------------------------------------------------------------*/
    task page_program;
		input  [ADDR_MSB:0]  Address;
		reg    [7:0]	  Offset;
		integer Dummy_Count, Tmp_Int, i;
		begin
		    Dummy_Count = Buffer_Num;    // page size
		    Tmp_Int 		= 0;
  	    Offset  		= Address[7:0];
  	    
  	    // QPP_Mode: QPP mode
  	    if( QPP_Mode == 1'b1) begin
  	    		SI_IN_EN			= 1'b1;
		    		SO_IN_EN			= 1'b1;
		    		WP_IN_EN			= 1'b1;
		    		HOLD_N_IN_EN  = 1'b1;
  	    end
  	    else begin
  	    		SI_IN_EN			= 1'b1;
		    		SO_IN_EN			= 1'b0;
		    		WP_IN_EN			= 1'b0;
		    		HOLD_N_IN_EN  = 1'b0;
  	    end 	    
  	    
		    /*------------------------------------------------*/
		    /*	Store 256 bytes into a temp buffer - Dummy_A  */
		    /*------------------------------------------------*/
  	    for (i = 0; i < Dummy_Count ; i = i + 1 ) begin
						Dummy_A[i]  = 8'hff;
  	    end
  	    
		    forever begin
						@ ( posedge ISCLK or posedge CS_N_INT );
						if ( CS_N_INT == 1'b1 ) begin
								if ( (Tmp_Int % 8 !== 0) || (Tmp_Int == 1'b0) ) begin
										QPP_Mode 				= 0;
										Page_prog_Mode 	= 0;
										disable page_program;
								end
								else begin
										if ( Tmp_Int > 8 )
												Byte_PGM_Mode = 1'b0;
  	      	  			else 
											Byte_PGM_Mode = 1'b1;
										update_array ( Address );
								end
								disable page_program;
						end
						else begin  // count how many Bits been shifted
								Tmp_Int = ( QPP_Mode ) ? (Tmp_Int) + 4 : (Tmp_Int + 1);
								if ( Tmp_Int % 8 == 0) begin
  	      	  	    #1;
										Dummy_A[Offset] = SI_data_Reg [7:0];
										Offset 					= Offset + 1;   
  	      	  	  	Offset 					= Offset[7:0];   
  	      	  	end  
						end
		    end  // end forever
		end
    endtask // page_program
    
    /*----------------------------------------------------------------------*/
    /*	Description: define a read electronic ID (RES)			    */
    /*		     AB X X X						    */
    /*----------------------------------------------------------------------*/
    task read_electronic_id;
		reg  [7:0] Dummy_ID;
		begin
  	    dummy_cycle(23);
		    Dummy_ID = ID_Device;
		    dummy_cycle(1);
  	
		    forever begin
						@ ( negedge ISCLK or posedge CS_N_INT );
						if ( CS_N_INT == 1'b1 ) begin
						    disable read_electronic_id;
						end 
						else begin  
						    SO_OUT_EN 		= 1'b1;
  	  			    SO_IN_EN  		= 1'b0;
  	  			    SI_IN_EN  		= 1'b0;
  	  			    WP_IN_EN  		= 1'b0;
  	  			    HOLD_N_IN_EN  = 1'b0;
  	  			    {SO_Reg, Dummy_ID} <= #tCLQV  {Dummy_ID, Dummy_ID[7]};
						end
		    end // end forever	 
		end
    endtask // read_electronic_id
	    
    /*----------------------------------------------------------------------*/
    /*	Description: define a read electronic manufacturer & device ID	    */
    /*----------------------------------------------------------------------*/
    task read_electronic_manufacturer_device_id;
		reg  [15:0] Dummy_ID;
		integer Dummy_Count;
		begin
				if(REMS_Mode_Dual)begin
						dummy_cycle(16);
				end
				else if(REMS_Mode_Quad)begin
						dummy_cycle(12);
				end
				else begin
		    		dummy_cycle(24);
		    end
		    		
		    #1;
		    if ( Address[0] == 1'b0 ) begin
						Dummy_ID = {ID_Manufacturer,ID_Device};
		    end
		    else begin
						Dummy_ID = {ID_Device,ID_Manufacturer};
		    end
		    
		    Dummy_Count = 0;
		    forever begin
						@ ( negedge ISCLK or posedge CS_N_INT );
						if ( CS_N_INT == 1'b1 ) begin
						    disable read_electronic_manufacturer_device_id;
						end
						else if(REMS_Mode_Dual)begin
						    SO_OUT_EN 		= 1'b1;
  	  			    SI_OUT_EN 		= 1'b1;
  	  			    SI_IN_EN			= 1'b0;
	  	    			SO_IN_EN			= 1'b0;
	  	    			WP_IN_EN  		= 1'b0;
  	  			    HOLD_N_IN_EN  = 1'b0;
						    {SO_Reg, SI_Reg, Dummy_ID} <= #tCLQV  {Dummy_ID, Dummy_ID[15:14]};
						end
						else if(REMS_Mode_Quad)begin
      	    		SO_OUT_EN   	= 1'b1;
      	    		SI_OUT_EN   	= 1'b1;
      	    		WP_OUT_EN   	= 1'b1;
      	    		HOLD_N_OUT_EN = 1'b1;
      	    		SO_IN_EN    	= 1'b0;
      	    		SI_IN_EN    	= 1'b0;
      	    		WP_IN_EN    	= 1'b0;
      	    		HOLD_N_IN_EN  = 1'b0;
						    {HOLD_N_Reg, WP_N_Reg, SO_Reg, SI_Reg, Dummy_ID} <= #tCLQV  {Dummy_ID, Dummy_ID[15:12]};
						end
						else begin
								SO_OUT_EN 		= 1'b1;
  	  			    SO_IN_EN  		= 1'b0;
  	  			    SI_IN_EN  		= 1'b0;
  	  			    WP_IN_EN  		= 1'b0;
  	  			    HOLD_N_IN_EN  = 1'b0;
  	  			    {SO_Reg, Dummy_ID} <= #tCLQV  {Dummy_ID, Dummy_ID[15]};
						end
		    end	// end forever
		end
    endtask // read_electronic_manufacturer_device_id

    /*----------------------------------------------------------------------*/
    /*	Description: define a program chip task				    */
    /*	INPUT:address                            			    */
    /*----------------------------------------------------------------------*/
    task update_array;
	  input [ADDR_MSB:0] Address;
	  integer Dummy_Count, i;
    integer program_time;
	  begin
	      Dummy_Count 	= Buffer_Num;
        Address 			= { Address[ADDR_MSB:8], 8'h00};
        program_time  = (Byte_PGM_Mode) ? tBP : tPP;
	      Status_Reg[0] = 1'b1;		 						 				
        if ( write_protect(Address) == 1'b0 && same_address(Address) == 1'b0) begin
        		if( Byte_PGM_Mode )begin
        				#program_time;
        		end
        		for ( i = 0; i < Dummy_Count; i = i + 1 ) begin
        				if(!SUS2) begin
        						if( !Byte_PGM_Mode) begin   
        								#(program_time/Dummy_Count);
        						end
        						
        						if(wr_scur)begin
        								case(Address[13:12])
        									2'b00:Secur_ARRAY_0[Address[7:0]+ i] = Secur_ARRAY_0[Address[7:0] + i] & Dummy_A[i];        								
        									2'b01:Secur_ARRAY_1[Address[7:0]+ i] = Secur_ARRAY_1[Address[7:0] + i] & Dummy_A[i];
        									2'b10:Secur_ARRAY_2[Address[7:0]+ i] = Secur_ARRAY_2[Address[7:0] + i] & Dummy_A[i];
        									2'b11:Secur_ARRAY_3[Address[7:0]+ i] = Secur_ARRAY_3[Address[7:0] + i] & Dummy_A[i];
        								endcase
		 								end		
		 								else begin						 												
		 										ARRAY[Address+ i] = ARRAY[Address + i] & Dummy_A[i];
		 								end 
		 						end
        		end
		 			  Status_Reg[0] = 1'b0;
		 		end
		 		else begin
		 				#tPGM_CHK ;
		 				Status_Reg[0] = 1'b0;
		 		end
	     	Status_Reg[1] 		= 1'b0;
	     	QPP_Mode 					= 1'b0;
	     	Page_prog_Mode 		= 1'b0;
        Byte_PGM_Mode 		= 1'b0;
		  	wr_scur						=	1'b0;
		  	ACOTP 						= 1'b0;
	  end
    endtask // update_array
    
    /*----------------------------------------------------------------------*/
    /*	Description: Compare program address and erase address 				      */
    /*----------------------------------------------------------------------*/
    function same_address;
    input [ADDR_MSB:0] Address;
		begin
				if(SUS1) begin
						if(SE_4K_Mode_SUS && (Address_SUS[ADDR_MSB:12] == Address[ADDR_MSB:12]))
								same_address = 1'b1;
						else if(BE32K_Mode_SUS && (Address_SUS[ADDR_MSB:15] == Address[ADDR_MSB:15]))
								same_address = 1'b1;
						else if(BE64K_Mode_SUS && (Address_SUS[ADDR_MSB:16] == Address[ADDR_MSB:16]))
								same_address = 1'b1;
						else
								same_address = 1'b0;
				end
				else
						same_address = 1'b0;
		end
		endfunction
		
    /*----------------------------------------------------------------------*/
    /*	Description: Execute 2X IO Read Mode				    */
    /*----------------------------------------------------------------------*/
    task read_2xio;
	  reg  [7:0]  OUT_Buf;
	  integer     Dummy_Count;
	  begin
	      Dummy_Count = 4;
	      SI_IN_EN 	  = 1'b1;
	      SO_IN_EN 	  = 1'b1;
	      SI_OUT_EN   = 1'b0;
	      SO_OUT_EN   = 1'b0;
	      
	      if(M54_D==2)
	  				dummy_cycle(12);
	  	  else
	  	  		dummy_cycle(13);
	  	  		
	  	  @ ( negedge ISCLK)
	  	  		DUAL_M = 1'b1;       
	  	  		
	  	  dummy_cycle(1);
	  	  @ ( negedge ISCLK)
	  	  		DUAL_M = 1'b0;   
	  	  		
	  	  #1;
	  		dummy_cycle(2);
	  				
        read_array(Address, OUT_Buf);
            
	      forever @ ( negedge ISCLK or  posedge CS_N_INT ) begin
	          if ( CS_N_INT == 1'b1 ) begin
	  	    			disable read_2xio;
	          end
	          else begin
	  	    			Read_Mode	= 1'b1;
	  	    			SO_OUT_EN	= 1'b1;
	  	    			SI_OUT_EN	= 1'b1;
	  	    			SI_IN_EN	= 1'b0;
	  	    			SO_IN_EN	= 1'b0;
	  	    			if ( Dummy_Count ) begin
	  								{SO_Reg, SI_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[1:0]};
	  								Dummy_Count = Dummy_Count - 1;
	  	    			end
	  	    			else begin
                		Address = Address + 1;
                		load_address(Address);
                		read_array(Address, OUT_Buf);
	      						{SO_Reg, SI_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[1:0]};
	      						Dummy_Count = 3 ;
	  	    			end
	          end
	      end//forever  
	  end
    endtask // read_2xio

    /*----------------------------------------------------------------------*/
    /*	Description: Execute 4X IO Read Mode or 4X IO Word Read Mode		    */
    /*----------------------------------------------------------------------*/
    task read_4xio;
		reg [7:0]   OUT_Buf ;
		reg [23:0] burst_addr ;
		reg [5:0] Address_num ;
		integer	    Dummy_Count;
		begin
		    Address_num   = 0;
			  Dummy_Count   = 2;
		    SI_OUT_EN     = 1'b0;
		    SO_OUT_EN     = 1'b0;
		    WP_OUT_EN     = 1'b0;
		    HOLD_N_OUT_EN = 1'b0;
		    SI_IN_EN			= 1'b1;
		    SO_IN_EN			= 1'b1;
		    WP_IN_EN			= 1'b1;
		    HOLD_N_IN_EN  = 1'b1;
		    		    
				dummy_cycle(5);
				if(M54_Q != 2 && M54_W != 2)
						dummy_cycle(1);
						
				@ ( negedge ISCLK)
						QUAD_M= 1'b1;
						
				dummy_cycle(1);
				
				@ ( negedge ISCLK)
						QUAD_M= 1'b0;
						
				#1;
				dummy_cycle(1);
				
				if( QUAD_IO_Mode == 1'b1)
        		dummy_cycle(4);
        else if(QUAD_IO_WDMD == 1'b1)
        		dummy_cycle(2);
        		
				burst_addr = Address;
        read_array(Address, OUT_Buf);

	    	forever @ ( negedge ISCLK or  posedge CS_N_INT ) begin
	    	    if ( CS_N_INT == 1'b1 ) begin
		  	  			disable read_4xio;
	    	    end
	    	      
	    	    else begin
      	    		SO_OUT_EN     = 1'b1;
      	    		SI_OUT_EN     = 1'b1;
      	    		WP_OUT_EN     = 1'b1;
      	    		HOLD_N_OUT_EN = 1'b1;
      	    		SO_IN_EN      = 1'b0;
      	    		SI_IN_EN      = 1'b0;
      	    		WP_IN_EN      = 1'b0;
      	    		HOLD_N_IN_EN  = 1'b0;
      	    		Read_Mode     = 1'b1;
      	    		if ( Dummy_Count ) begin
      	    		    {HOLD_N_Reg, WP_N_Reg, SO_Reg, SI_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[3:0]};
      	    		    Dummy_Count = Dummy_Count - 1;
      	    		end
      	    		else begin
										if ( EN_Burst && Burst_Length==8 && Address[2:0]==3'b111 )begin
      	    				    Address[2:0] = 0;
										end
      	            else if ( EN_Burst && Burst_Length==16 && Address[3:0]==4'b1111 )begin
      	                Address[3:0] = 0;
										end
      	            else if ( EN_Burst && Burst_Length==32 && Address[4:0]==5'b1_1111)begin
      	                Address[4:0] = 0;
										end
      	            else if ( EN_Burst && Burst_Length==64 && Address[5:0]==6'b11_1111)begin
      	                Address[5:0] = 0;
										end
      	            else begin
      	                Address = Address + 1;
										end
      	            load_address(Address);
      	            read_array(Address, OUT_Buf);
      	            {HOLD_N_Reg, WP_N_Reg, SO_Reg, SI_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[3:0]};
      	            Dummy_Count = 1 ;
      	        end
	    	    end
	    	end//forever  
	  end
    endtask // read_4xio

    /*----------------------------------------------------------------------*/
    /*	Description: define a fast read dual output data task		    */
    /*		     3B AD1 AD2 AD3 X					    */
    /*----------------------------------------------------------------------*/
    task fastread_2xio;
				integer Dummy_Count;
				reg  [7:0] OUT_Buf;
				begin
				    Dummy_Count = 4 ;
				    dummy_cycle(32);
  			          read_array(Address, OUT_Buf);
				    forever @ ( negedge ISCLK or  posedge CS_N_INT ) begin
				        if ( CS_N_INT == 1'b1 ) begin
					    			disable fastread_2xio;
				        end
				        else begin
					    			Read_Mode = 1'b1;
					    			SO_OUT_EN = 1'b1;
					    			SI_OUT_EN = 1'b1;
					    			SI_IN_EN  = 1'b0;
					    			SO_IN_EN  = 1'b0;
					    			if ( Dummy_Count ) begin
												{SO_Reg, SI_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[1:0]};
				    						Dummy_Count = Dummy_Count - 1;
					    			end
					    			else begin
												Address = Address + 1;
  			    						load_address(Address);
  			    						read_array(Address, OUT_Buf);
												{SO_Reg, SI_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[1:0]};
												Dummy_Count = 3 ;
					    			end
				        end
				    end//forever  
				end
    endtask // fastread_2xio

    /*----------------------------------------------------------------------*/
    /*  Description: define a fast read quad output data task               */
    /*               6B AD1 AD2 AD3 X                                       */
    /*----------------------------------------------------------------------*/
    task fastread_4xio;
        integer Dummy_Count;
        reg  [7:0]  OUT_Buf;
        begin
            Dummy_Count = 2 ;
            dummy_cycle(32);
            read_array(Address, OUT_Buf);
            forever @ ( negedge ISCLK or  posedge CS_N_INT ) begin
                if ( CS_N_INT ==      1'b1 ) begin
                    disable fastread_4xio;
                end
                else begin
                    SI_IN_EN      = 1'b0;
                    SI_OUT_EN     = 1'b1;
                    SO_OUT_EN     = 1'b1;
                    WP_OUT_EN     = 1'b1;
                    HOLD_N_OUT_EN = 1'b1;
                    if ( Dummy_Count ) begin
                        {HOLD_N_Reg, WP_N_Reg, SO_Reg, SI_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[3:0]};
                        Dummy_Count = Dummy_Count - 1;
                    end
                    else begin
                        Address = Address + 1;
                        load_address(Address);
                        read_array(Address, OUT_Buf);
                        {HOLD_N_Reg, WP_N_Reg, SO_Reg, SI_Reg, OUT_Buf} <= #tCLQV {OUT_Buf, OUT_Buf[3:0]};
                        Dummy_Count = 1 ;
                    end
                end
            end//forever
        end
    endtask // fastread_4xio

    /*----------------------------------------------------------------------*/
    /*  Description: define read array output task                          */
    /*----------------------------------------------------------------------*/
    task read_array;
        input [ADDR_MSB:0] Address;
        output [7:0]    OUT_Buf;
        begin
        		if(read_scur)begin
        				case(Address[13:12])
        					2'b00:OUT_Buf = Secur_ARRAY_0[Address[7:0]];        								
        					2'b01:OUT_Buf = Secur_ARRAY_1[Address[7:0]];
        					2'b10:OUT_Buf = Secur_ARRAY_2[Address[7:0]];
        					2'b11:OUT_Buf = Secur_ARRAY_3[Address[7:0]];
        				endcase
						end
						else
								OUT_Buf = ARRAY[Address] ;
        end
    endtask //  read_array

    /*----------------------------------------------------------------------*/
    /*  Description: define read array output task                          */
    /*----------------------------------------------------------------------*/
    task load_address;
        inout [ADDR_MSB:0] Address;
        begin
						if ( read_scur == 1 ) begin
        				Address = Address[ADDR_MSB_OTP:0] ;
        		end
        end
    endtask //  load_address

    /*----------------------------------------------------------------------*/
    /*	Description: define a write_protect area function		    */
    /*	INPUT: address							    */
    /*----------------------------------------------------------------------*/ 
    function write_protect;
        input [ADDR_MSB:0] Address;
        begin
        		Block = Address [ADDR_MSB:16];
        		if( ACOTP )begin
        				case(Address[13:12])
        						2'b00:write_protect = 1'b1;        								
        						2'b01:
        								if(LB1)
        										write_protect = 1'b1;	
        								else
        										write_protect = 1'b0;
        						2'b10:  
        								if(LB2)
        										write_protect = 1'b1;	
        								else
        										write_protect = 1'b0;
        						2'b11:
        								if(LB3)
        										write_protect = 1'b1;	
        								else
        										write_protect = 1'b0;
        				endcase
        		end
        		else begin 
        				if ( CMP == 1'b0 ) begin
        				  	if ( SEC == 1'b0 ) begin
        				  			if(TB == 1'b0)begin
														case({BP2,BP1,BP0})
																3'b000:write_protect = 1'b0;
																3'b001:
																		if(Block[Block_MSB:0] >= 252 && Block[Block_MSB:0] <= 255) begin
																				write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	   	write_protect = 1'b0;
																		end
																3'b010:
																		if (Block[Block_MSB:0] >= 248 && Block[Block_MSB:0] <= 255) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b011:
																		if (Block[Block_MSB:0] >= 240 && Block[Block_MSB:0] <= 255) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b100:
																		if (Block[Block_MSB:0] >= 224 && Block[Block_MSB:0] <= 255) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b101:
																		if (Block[Block_MSB:0] >= 192 && Block[Block_MSB:0] <= 255) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b110:
																		if (Block[Block_MSB:0] >= 128 && Block[Block_MSB:0] <= 255) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b111:
																		write_protect = 1'b1;
														endcase
								 			  end
								 				else begin
														case({BP2,BP1,BP0})
																3'b000:write_protect = 1'b0;
																3'b001:
																		if(Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 3)begin
																				write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
																		end
																3'b010:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 7) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b011:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 15) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b100:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 31) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b101:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 63) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b110:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 127) begin
        				 								  	    write_protect = 1'b1;
        				 								  	end
        				 								  	else begin
        				 								  	    write_protect = 1'b0;
        				 								  	end
																3'b111: write_protect = 1'b1;
														endcase
												end
										end
        				  	else begin//SEC==1
        				  	    if(TB==1'b0) begin
        				  	    		if(BE64K_Mode == 1)begin        				  	    		
        				  	    				if( Block[Block_MSB:0]== 255)
        				  	    						write_protect = 1'b1;
        				  	    				else
        				  	    						write_protect = 1'b0; 
        				  	    		end      				  	 
        				  	    		else begin       				  	    				
																case({BP2,BP1,BP0})
																		3'b000:write_protect = 1'b0;
																		3'b001:
																				if((Address[15:12] == 4'hf || (Address[15] == 1'b1 && BE32K_Mode == 1)) && Block[Block_MSB:0]== 255)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b010:
																				if((Address[15:12] >= 4'he || (Address[15] == 1'b1 && BE32K_Mode == 1)) && Block[Block_MSB:0]== 255)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b011:
																				if((Address[15:12] >= 4'hc || (Address[15] == 1'b1 && BE32K_Mode == 1)) && Block[Block_MSB:0]== 255)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b100,3'b101,3'b110:
																				if(Address[15:12] >= 4'h8 && Block[Block_MSB:0]== 255)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b111:write_protect = 1'b1;
																endcase
														end
												end
												else begin
														if(BE64K_Mode == 1)begin        				  	    		
        				  	    				if( Block[Block_MSB:0] == 0)
        				  	    						write_protect = 1'b1;
        				  	    				else
        				  	    						write_protect = 1'b0; 
        				  	    		end
														else begin
																case({BP2,BP1,BP0})
																		3'b000:write_protect = 1'b0;
																		3'b001:
																				if((Address[15:12]==4'h0 || (Address[15] == 1'b0 && BE32K_Mode == 1)) && Block[Block_MSB:0]==0)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b010:
																				if((Address[15:12]<=4'h1 || (Address[15] == 1'b0 && BE32K_Mode == 1)) && Block[Block_MSB:0]==0)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b011:
																				if((Address[15:12]<=4'h3 || (Address[15] == 1'b0 && BE32K_Mode == 1)) && Block[Block_MSB:0]==0)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b100,3'b101,3'b110:
																				if(Address[15:12]<=4'h7 && Block[Block_MSB:0]==0)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b111:write_protect = 1'b1;
																endcase
														end
												end
										end
								end
								else begin//CMP==1
										if ( SEC == 1'b0 ) begin
        						    if(TB==1'b0)begin
														case({BP2,BP1,BP0})
																3'b000:write_protect = 1'b1;
																3'b001:
																		if(Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 251)begin
																				write_protect = 1'b1;
        						    				  	end
        						    				  	else begin
        						    				  	   	write_protect = 1'b0;
																		end
																3'b010:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 247) begin
        						    				  	    write_protect = 1'b1;
        						    				  	end
        						    				  	else begin
        						    				  	    write_protect = 1'b0;
        						    				  	end
																3'b011:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 239) begin
        						    				  	    write_protect = 1'b1;
        						    				  	end
        						    				  	else begin
        						    				  	    write_protect = 1'b0;
        						    				  	end
																3'b100:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 223) begin
        						    				  	    write_protect = 1'b1;
        						    				  	end
        						    				  	else begin
        						    				  	    write_protect = 1'b0;
        						    				  	end
																3'b101:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 191) begin
        						    				  	    write_protect = 1'b1;
        						    				  	end
        						    				  	else begin
        						    				  	    write_protect = 1'b0;
        						    				  	end
																3'b110:
																		if (Block[Block_MSB:0] >= 0 && Block[Block_MSB:0] <= 127) begin
        						    				  	    write_protect = 1'b1;
        						    				  	end
        						    				  	else begin
        						    				  	    write_protect = 1'b0;
        						    				  	end
																3'b111: write_protect = 1'b0;
														endcase
								 				end						  		
								 				else begin
														case({BP2,BP1,BP0})
														3'b000:write_protect = 1'b1;
														3'b001:
																if(Block[Block_MSB:0] >= 4 && Block[Block_MSB:0] <= 255)begin
																		write_protect = 1'b1;
        				 						  	end
        				 						  	else begin
        				 						  			write_protect = 1'b0;
																end
														3'b010:
																if (Block[Block_MSB:0] >= 8 && Block[Block_MSB:0] <= 255) begin
        				 						  	    write_protect = 1'b1;
        				 						  	end
        				 						  	else begin
        				 						  	    write_protect = 1'b0;
        				 						  	end
														3'b011:
																if (Block[Block_MSB:0] >= 16 && Block[Block_MSB:0] <= 255) begin
        				 						  	    write_protect = 1'b1;
        				 						  	end
        				 						  	else begin
        				 						  	    write_protect = 1'b0;
        				 						  	end
														3'b100:
																if (Block[Block_MSB:0] >= 32 && Block[Block_MSB:0] <= 255) begin
        				 						  	    write_protect = 1'b1;
        				 						  	end
        				 						  	else begin
        				 						  	    write_protect = 1'b0;
        				 						  	end
														3'b101:
																if (Block[Block_MSB:0] >= 64 && Block[Block_MSB:0] <= 255) begin
        				 						  	    write_protect = 1'b1;
        				 						  	end
        				 						  	else begin
        				 						  	    write_protect = 1'b0;
        				 						  	end
														3'b110:
																if (Block[Block_MSB:0] >= 128 && Block[Block_MSB:0] <= 255) begin
        				 						  	    write_protect = 1'b1;
        				 						  	end
        				 						  	else begin
        				 						  	    write_protect = 1'b0;
        				 						  	end
														3'b111: write_protect = 1'b0;
														endcase
												end		
										end						 
        						else begin//SEC==1
        								if(BE64K_Mode == 1)begin        				  	    		
        				  	    		write_protect = 1'b1;
        				  	   	end	
        				  	   	else begin
        										if(TB==1'b0) begin
																case({BP2,BP1,BP0})
																		3'b000:write_protect = 1'b1;
																		3'b001:
																				if(Address[ADDR_MSB:0]<=24'hffefff || (Address[ADDR_MSB:15] == 9'h1ff && BE32K_Mode == 1))
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b010:
																				if(Address[ADDR_MSB:0]<=24'hffdfff || (Address[ADDR_MSB:15] == 9'h1ff && BE32K_Mode == 1))
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b011:
																				if(Address[ADDR_MSB:0]<=24'hffbfff || (Address[ADDR_MSB:15] == 9'h1ff && BE32K_Mode == 1))
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b100,3'b101,3'b110:
																				if(Address[ADDR_MSB:0]<=24'hff7fff)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b111:write_protect = 1'b0;
																endcase
														end
														else begin
																case({BP2,BP1,BP0})
																		3'b000:write_protect = 1'b1;
																		3'b001:
																				if(Address[ADDR_MSB:0]>=24'h001000 || (Address[ADDR_MSB:15] == 9'h00 && BE32K_Mode == 1))
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b010:
																				if(Address[ADDR_MSB:0]>=24'h002000 || (Address[ADDR_MSB:15] == 9'h00 && BE32K_Mode == 1))
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b011:
																				if(Address[ADDR_MSB:0]>=24'h004000 || (Address[ADDR_MSB:15] == 9'h00 && BE32K_Mode == 1))
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b100,3'b101,3'b110:
																				if(Address[ADDR_MSB:0]>=24'h008000)
																						write_protect = 1'b1;
																				else
																						write_protect = 1'b0;
																		3'b111:write_protect = 1'b0;
																endcase
														end
											  end
										end	
								end
						end				
    		end
    endfunction // write_protect


		// *============================================================================================== 
		// * AC Timing Check Section
		// *==============================================================================================
    wire HOLD_N_EN;
    wire WP_EN;
    assign HOLD_N_EN = !Status_Reg_2[1];
    assign WP_EN = (!Status_Reg_2[1]);

    assign  Write_SHSL = !Read_SHSL;

    wire Noumal_Read_Chk_W;
    assign Noumal_Read_Chk_W = Noumal_Read_Chk;
    wire DUAL_IO_READ_Chk_W;
    assign DUAL_IO_READ_Chk_W = DUAL_IO_READ_Chk;
    wire DUAL_OUT_Chk_W;
    assign DUAL_OUT_Chk_W = DUAL_OUT_Chk;
    wire QUAD_OUT_Chk_W;
    assign QUAD_OUT_Chk_W = QUAD_OUT_Chk;
    wire QUAD_IO_Chk_W;
    assign QUAD_IO_Chk_W = QUAD_IO_Chk ;
    wire QUAD_IO_Chk_W0;
    assign QUAD_IO_Chk_W0 = QUAD_IO_WD_Chk;
    wire tDP_Chk_W;
    assign tDP_Chk_W = tDP_Chk;
    wire tRES1_Chk_W;
    assign tRES1_Chk_W = tRES1_Chk;
    wire tRES2_Chk_W;
    assign tRES2_Chk_W = tRES2_Chk;
    wire PP_Chk_W;
    assign PP_Chk_W = PP_Chk;
    wire Read_SHSL_W;
    assign Read_SHSL_W = Read_SHSL;
    wire SI_IN_EN_W;
    assign SI_IN_EN_W = SI_IN_EN;
    wire SO_IN_EN_W;
    assign SO_IN_EN_W = SO_IN_EN;
    wire WP_IN_EN_W;
    assign WP_IN_EN_W = WP_IN_EN;
    wire HOLD_N_IN_EN_W;
    assign HOLD_N_IN_EN_W = HOLD_N_IN_EN;

    specify
    		/*----------------------------------------------------------------------*/
    		/*  Timing Check                                                        */
    		/*----------------------------------------------------------------------*/
				$period( posedge  ISCLK &&& ~CS_N, tSCLK  );	// SCLK _/~ ->_/~
				$period( negedge  ISCLK &&& ~CS_N, tSCLK  );	// SCLK ~\_ ->~\_
				$period( posedge  ISCLK &&& Noumal_Read_Chk_W , tRSCLK ); // SCLK _/~ ->_/~
				$period( posedge  ISCLK &&& DUAL_IO_READ_Chk_W , tSCLK ); // SCLK _/~ ->_/~
				$period( posedge  ISCLK &&& DUAL_OUT_Chk_W , tSCLK ); // SCLK _/~ ->_/~
				$period( posedge  ISCLK &&& QUAD_IO_Chk_W , tSCLK ); // SCLK _/~ ->_/~ 
				$period( posedge  ISCLK &&& QUAD_OUT_Chk_W , tSCLK ); // SCLK _/~ ->_/~
				$period( posedge  ISCLK &&& QUAD_IO_Chk_W0 , tSCLK ); // SCLK _/~ ->_/~
				$period( posedge  ISCLK &&& PP_Chk_W, tSCLK ); // SCLK _/~ ->_/~
      	
				$width ( posedge  CS_N  &&& tDP_Chk_W, tDP );       // CS_N _/~\_
				$width ( posedge  CS_N  &&& tRES1_Chk_W, tRES1 );   // CS_N _/~\_
				$width ( posedge  CS_N  &&& tRES2_Chk_W, tRES2 );   // CS_N _/~\_
      	
				$width ( posedge  ISCLK &&& ~CS_N, tCH   );       // SCLK _/~~\_
				$width ( negedge  ISCLK &&& ~CS_N, tCL   );       // SCLK ~\__/~
				$width ( posedge  ISCLK &&& Noumal_Read_Chk_W, tCH   );       // SCLK _/~~\_
				$width ( negedge  ISCLK &&& Noumal_Read_Chk_W, tCL   );       // SCLK ~\__/~
      	
				$width ( posedge  CS_N  &&& Read_SHSL_W, tSHSL );	// CS_N _/~\_
				$width ( posedge  CS_N  &&& Write_SHSL, tSHSL );// CS_N _/~\_
				$setup ( SI &&& ~CS_N, posedge ISCLK &&& SI_IN_EN_W,  tDVCH );
				$hold  ( posedge ISCLK &&& SI_IN_EN_W, SI &&& ~CS_N,  tCHDX );
      	
				$setup ( SO &&& ~CS_N, posedge ISCLK &&& SO_IN_EN_W,  tDVCH );
				$hold  ( posedge ISCLK &&& SO_IN_EN_W, SO &&& ~CS_N,  tCHDX );
				$setup ( WP_N &&& ~CS_N, posedge ISCLK &&& WP_IN_EN_W,  tDVCH );
				$hold  ( posedge ISCLK &&& WP_IN_EN_W, WP_N &&& ~CS_N,  tCHDX );
      	
				$setup ( HOLD_N &&& ~CS_N, posedge ISCLK &&& HOLD_N_IN_EN_W,  tDVCH );
				$hold  ( posedge ISCLK &&& HOLD_N_IN_EN_W, HOLD_N &&& ~CS_N,  tCHDX );
      	
				$setup    ( negedge CS_N, posedge ISCLK &&& ~CS_N, tSLCH );
				$hold     ( posedge ISCLK &&& ~CS_N, posedge CS_N, tCHSH );
      	
				$setup    ( posedge CS_N, posedge ISCLK &&& CS_N, tSHCH );
				$hold     ( posedge ISCLK &&& CS_N, negedge CS_N, tCHSL );
      	
				$setup ( posedge WP_N &&& WP_EN, negedge CS_N,  tWHSL );
				$hold  ( posedge CS_N, negedge WP_N &&& WP_EN,  tSHWL );

     endspecify

    integer AC_Check_File;
    // timing check module 
    initial 
    begin 
    		AC_Check_File= $fopen ("ac_check.err" );    
    end

    time  T_CS_P , T_CS_N;
    time  T_WP_P , T_WP_N;
    time  T_SCLK_P , T_SCLK_N;
    time  T_HOLD_N_P , T_HOLD_N_N;
    time  T_SI;
    time  T_SO;
    time  T_WP;
    time  T_HOLD;    
    time  T_HOLD_P , T_HOLD_N;                

    initial 
    begin
				T_CS_P = 0; 
				T_CS_N = 0;
				T_WP_P = 0;  
				T_WP_N = 0;
				T_SCLK_P = 0;  
				T_SCLK_N = 0;
				T_HOLD_N_P = 0;  
				T_HOLD_N_N = 0;
				T_SI = 0;
				T_SO = 0;
				T_WP = 0;
				T_HOLD = 0;           
      	T_HOLD_P = 0;
      	T_HOLD_N = 0;        
    end
 
    always @ ( posedge ISCLK ) begin

				//tSCLK
    		if ( $time - T_SCLK_P < tSCLK && $time > 0 && ~CS_N ) 
	  				$fwrite (AC_Check_File, "Clock Frequence for except READ struction fSCLK =%d Mhz, fSCLK timing violation at %d \n", fSCLK, $time );
				//fRSCLK
    		if ( $time - T_SCLK_P < tRSCLK && Noumal_Read_Chk && $time > 0 && ~CS_N )
	  			$fwrite (AC_Check_File, "Clock Frequence for READ instruction fRSCLK =%d Mhz, fRSCLK timing violation at %d \n", fRSCLK, $time );
				//fSCLK
    		if ( $time - T_SCLK_P < tSCLK && DUAL_IO_READ_Chk && $time > 0 && ~CS_N )
	  			$fwrite (AC_Check_File, "Clock Frequence for 2XI/O instruction fSCLK =%d Mhz, fSCLK timing violation at %d \n", fSCLK, $time );
    		//fSCLK
    		if ( $time - T_SCLK_P < tSCLK &&  DUAL_OUT_Chk && $time > 0 && ~CS_N )
    		    $fwrite (AC_Check_File, "Clock Frequence for DUAL_OUT_READ instruction fSCLK =%d Mhz, fSCLK timing violation at %d \n", fSCLK, $time );
    		
				//fSCLK
    		if ( $time - T_SCLK_P < tSCLK && QUAD_IO_Chk_W && $time > 0 && ~CS_N )
	  		  	$fwrite (AC_Check_File, "Clock Frequence for 4XI/O instruction fSCLK =%d Mhz, fSCLK timing violation at %d \n", fSCLK, $time );
    		//fSCLK
    		if ( $time - T_SCLK_P < tSCLK && QUAD_OUT_Chk && $time > 0 && ~CS_N )
    		    $fwrite (AC_Check_File, "Clock Frequence for QUAD_OUT_READ instruction fSCLK =%d Mhz, fSCLK timing violation at %d \n", fSCLK, $time );
    		//fSCLK
    		if ( $time - T_SCLK_P < tSCLK && QUAD_IO_Chk_W0  && $time > 0 && ~CS_N )
    		    $fwrite (AC_Check_File, "Clock Frequence for 4XI/O instruction fSCLK =%d Mhz, fSCLK timing violation at %d \n", fSCLK, $time );
    		//fSCLK
    		if ( $time - T_SCLK_P < tSCLK && PP_Chk && $time > 0 && ~CS_N )
    		        $fwrite (AC_Check_File, "Clock Frequence for 4PP program instruction fSCLK =%d Mhz, fSCLK timing violation at %d \n", fSCLK, $time );
    		
        T_SCLK_P = $time; 
        #0;  
				//tDVCH
        if ( T_SCLK_P - T_SI < tDVCH && SI_IN_EN && T_SCLK_P > 0 )
	    			$fwrite (AC_Check_File, "minimun Data SI setup time tDVCH=%d ns, tDVCH timing violation at %d \n", tDVCH, $time );
        if ( T_SCLK_P - T_SO < tDVCH && SO_IN_EN && T_SCLK_P > 0 )
	    			$fwrite (AC_Check_File, "minimun Data SO setup time tDVCH=%d ns, tDVCH timing violation at %d \n", tDVCH, $time );
        if ( T_SCLK_P - T_WP < tDVCH && WP_IN_EN && T_SCLK_P > 0 )
	    			$fwrite (AC_Check_File, "minimun Data WP_N setup time tDVCH=%d ns, tDVCH timing violation at %d \n", tDVCH, $time );

        if ( T_SCLK_P - T_HOLD < tDVCH && HOLD_N_IN_EN && T_SCLK_P > 0 )
	    			$fwrite (AC_Check_File, "minimun Data HOLD_N setup time tDVCH=%d ns, tDVCH timing violation at %d \n", tDVCH, $time );
	    			
				//tCL
        if ( T_SCLK_P - T_SCLK_N < tCL && ~CS_N && T_SCLK_P > 0 )
	   	 			$fwrite (AC_Check_File, "minimun SCLK Low time tCL=%f ns, tCL timing violation at %d \n", tCL, $time );
	   	 			
        //tCL
        if ( T_SCLK_P - T_SCLK_N < tCL && Noumal_Read_Chk && T_SCLK_P > 0 )
            $fwrite (AC_Check_File, "minimun SCLK Low time tCL=%f ns, tCL timing violation at %d \n", tCL, $time );
        #0;
        
        // tSLCH
        if ( T_SCLK_P - T_CS_N < tSLCH  && T_SCLK_P > 0 )
            $fwrite (AC_Check_File, "minimun CS_N active setup time tSLCH=%d ns, tSLCH timing violation at %d \n", tSLCH, $time );

        // tSHCH
        if ( T_SCLK_P - T_CS_P < tSHCH  && T_SCLK_P > 0 )
            $fwrite (AC_Check_File, "minimun CS_N not active setup time tSHCH=%d ns, tSHCH timing violation at %d \n", tSHCH, $time );
    end

    always @ ( negedge ISCLK ) begin
        T_SCLK_N = $time;
        #0; 
				//tCH
        if ( T_SCLK_N - T_SCLK_P < tCH && ~CS_N && T_SCLK_N > 0 )
	    			$fwrite (AC_Check_File, "minimun SCLK High time tCH=%f ns, tCH timing violation at %d \n", tCH, $time );
        //tCH
        if ( T_SCLK_N - T_SCLK_P < tCH && Noumal_Read_Chk && T_SCLK_N > 0 )
            $fwrite (AC_Check_File, "minimun SCLK High time tCH=%f ns, tCH timing violation at %d \n", tCH, $time );
    end


    always @ ( SI ) begin
        T_SI = $time; 
        #0;  
				//tCHDX
				if ( T_SI - T_SCLK_P < tCHDX && SI_IN_EN && T_SI > 0 )
				    $fwrite (AC_Check_File, "minimun Data SI hold time tCHDX=%d ns, tCHDX timing violation at %d \n", tCHDX, $time );
    end

    always @ ( SO ) begin
        T_SO = $time; 
        #0;  
				//tCHDX
				if ( T_SO - T_SCLK_P < tCHDX && SO_IN_EN && T_SO > 0 )
	  		 	 $fwrite (AC_Check_File, "minimun Data SO hold time tCHDX=%d ns, tCHDX timing violation at %d \n", tCHDX, $time );
    end

    always @ ( WP_N ) begin
        T_WP = $time; 
        #0;  
				//tCHDX
				if ( T_WP - T_SCLK_P < tCHDX && WP_IN_EN && T_WP > 0 )
				    $fwrite (AC_Check_File, "minimun Data WP_N hold time tCHDX=%d ns, tCHDX timing violation at %d \n", tCHDX, $time );
    end

    always @ ( HOLD_N ) begin
        T_HOLD = $time;   
				//tCHDX
  			if ( T_HOLD - T_SCLK_P < tCHDX && HOLD_N_IN_EN && T_HOLD_N > 0 )
				    $fwrite (AC_Check_File, "minimun Data HOLD_N hold time tCHDX=%d ns, tCHDX timing violation at %d \n", tCHDX, $time );
    end

    always @ ( posedge CS_N ) begin
        T_CS_P = $time;  
				// tCHSH 
  			if ( T_CS_P - T_SCLK_P < tCHSH  && T_CS_P > 0 )
				    $fwrite (AC_Check_File, "minimun CS_N active hold time tCHSH=%d ns, tCHSH timing violation at %d \n", tCHSH, $time );
    end

    always @ ( negedge CS_N ) begin
        T_CS_N = $time;
        #0;
				//tCHSL
  			if ( T_CS_N - T_SCLK_P < tCHSL  && T_CS_N > 0 )
				    $fwrite (AC_Check_File, "minimun CS_N not active hold time tCHSL=%d ns, tCHSL timing violation at %d \n", tCHSL, $time );
				//tSHSL
  			if ( T_CS_N - T_CS_P < tSHSL && T_CS_N > 0 && Read_SHSL)
  			    $fwrite (AC_Check_File, "minimun CS_N deslect  time tSHSL=%d ns, tSHSL timing violation at %d \n", tSHSL, $time );
  			if ( T_CS_N - T_CS_P < tSHSL && T_CS_N > 0 && Write_SHSL)
  			    $fwrite (AC_Check_File, "minimun CS_N deslect  time tSHSL=%d ns, tSHSL timing violation at %d \n", tSHSL, $time );
  			
				//tWHSL
        if ( T_CS_N - T_WP_P < tWHSL && WP_EN  && T_CS_N > 0 )
	    			$fwrite (AC_Check_File, "minimun WP setup  time tWHSL=%d ns, tWHSL timing violation at %d \n", tWHSL, $time );


        //tDP
        if ( T_CS_N - T_CS_P < tDP && T_CS_N > 0 && tDP_Chk)
            $fwrite (AC_Check_File, "when transite from Standby Mode to Deep-Power Mode to Deep-Power Mode, CS_N must remain high for at least tDP =%d ns, tDP timing violation at %d \n", tDP, $time );


        //tRES1/2
        if ( T_CS_N - T_CS_P < tRES1 && T_CS_N > 0 && tRES1_Chk)
            $fwrite (AC_Check_File, "when transite from Deep-Power Mode to Standby Mode, CS_N must remain high for at least tRES1 =%d ns, tRES1 timing violation at %d \n", tRES1, $time );

        if ( T_CS_N - T_CS_P < tRES2 && T_CS_N > 0 && tRES2_Chk)
            $fwrite (AC_Check_File, "when transite from Deep-Power Mode to Standby Mode, CS_N must remain high for at least tRES2 =%d ns, tRES2 timing violation at %d \n", tRES2, $time );
    end

    always @ ( posedge HOLD_B_INT ) begin
        T_HOLD_P = $time;
        #0;
    end

    always @ ( negedge HOLD_B_INT ) begin
        T_HOLD_N = $time;
        #0;
    end

    always @ ( posedge WP_N ) begin
        T_WP_P = $time;
        #0;  
    end

    always @ ( negedge WP_N ) begin
        T_WP_N = $time;
        #0;
				//tSHWL
        if ( ((T_WP_N - T_CS_P < tSHWL) || ~CS_N) && WP_EN && T_WP_N > 0 )
	    			$fwrite (AC_Check_File, "minimun WP hold time tSHWL=%d ns, tSHWL timing violation at %d \n", tSHWL, $time );
    end
endmodule

