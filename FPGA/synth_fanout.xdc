set_property MAX_FANOUT 16 [current_design]

set_property MAX_FANOUT 8 \
    [get_nets -hierarchical -filter {NAME =~ "*u_fwd_unit/fwdA*" || NAME =~ "*u_fwd_unit/fwdB*"}]

set_property MAX_FANOUT 8 \
    [get_nets -hierarchical -filter {NAME =~ "*fwd_rdata1E*" || NAME =~ "*fwd_rdata2E*"}]

set_property MAX_FANOUT 8 \
    [get_cells -hierarchical -filter {NAME =~ "*u_de_reg/d_out_reg[rs1_addr]*" || NAME =~ "*u_de_reg/d_out_reg[rs2_addr]*"}]

set_property MAX_FANOUT 16 \
    [get_nets -hierarchical -filter {NAME =~ "*pc_srcE*" || NAME =~ "*halt_pc*"}]