
module Maze_RAM (

input  logic       clk,
input  logic       write_en, map_rst, 
input  logic [9:0] tile_adress_pac, tile_adress_ghost1,tile_adress_VGA,
output logic [1:0] tile_data_central_control, tile_data_ghost, tile_data_VGA,  
output logic       busy

);

// initialize the array with 1007 tiles of 2 bits eaach tile and load values from Maze_ROM

  logic [1:0] original_map [0:1007];
  logic [1:0] tile_map [0:1007];
  
  
  logic [10:0]index_counter
  
 
  


  initial $readmemb("filename", original_map);
  initial $readmemb("filename", tile_map);



// localize tile data in the ram and send it to other modules

assign tile_data_central_control = tile_map[tile_adress_pac];

assign tile_data_ghost = tile_map[tile_adress_ghost1];

assign tile_data_VGA = tile_map[tile_adress_VGA];




always_ff @ (posedge clk) begin

 // the comment below only works if we want to synthesize 2016 flipflops. But I actually want
 // to use ROM MACROS and RAM MACROS

 /* if (map_rst) begin
    
    foreach (original_map[i]) begin
      tile_map[i] <= original_map[i];
    end */ 
  
 
 
  if (map_rst) begin
  
    index_counter <= 1'b0;
  
    busy <=1; 
    
  end else if (busy) begin
  
      //counter
      
    if (index_counter < 10'd1008) begin
  
      index_counter <= index_counter + 1'b1;
      
      tile_map[index_counter] <= original_map[index_counter];
  
    end else begin
      
     indexcounter <= 10'd0; 
      
     busy <= 1'b0;
      
    end
      
    end else if ( (write_en && tile_data_central_control == 2'b01) || (write_en && tile_data_central_control == 2'b10)) begin
  
      tile_map[tile_adress_pac] <= 2'b00;
  
    end



end










