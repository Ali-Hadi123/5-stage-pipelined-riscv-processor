## synth_fanout.xdc
##
## Fanout-control constraints for synthesis.
##
## Capping MAX_FANOUT tells synthesis to build a local buffer 
## tree instead of relying on one net to reach everything.
##
## IMPORTANT (Vivado): this file must be added as a SEPARATE constraint set
## (or a separate .xdc within your existing set) and marked "used in:
## Synthesis" only, with "used in: Implementation" UNCHECKED.
##
## GUI: Sources panel -> right-click this file -> Properties -> uncheck
##      "Used in Implementation", leave "Used in Synthesis" checked.
## TCL: set_property used_in_implementation false [get_files synth_fanout.xdc]
##      set_property used_in_synthesis      true  [get_files synth_fanout.xdc]

## ---------------------------------------------------------------------
## 1) Global design-wide cap.
##    Start conservative (16). Too aggressive a value (e.g. <8) can
##    increase logic levels/area from excessive replication, so if timing
##    doesn't improve or area/util blows up, relax this back up.
## ---------------------------------------------------------------------
set_property MAX_FANOUT 16 [current_design]

## ---------------------------------------------------------------------
## 2) Targeted, tighter caps on the specific nets called out in the report.
##    Adjust the hierarchical paths below to match your actual instance
##    names if your top-level module/instance names differ.
## ---------------------------------------------------------------------

# The rs2_addr[2] register driving the fwd/branch-resolution cone.
set_property MAX_FANOUT 8 \
    [get_cells -hierarchical -filter {NAME =~ "*u_de_reg/d_out_reg[rs2_addr][2]*"}]

# pc_srcE: drives both the 32-bit PC mux select AND the hazard unit's
# flush generation -- this is the actual high-fanout culprit downstream
# of rs2_addr. Splitting its fanout is the highest-value fix.
set_property MAX_FANOUT 8 \
    [get_nets -hierarchical -filter {NAME =~ "*pc_srcE*"}]

# The PC register itself (fanout-58 endpoint on Paths 1,2,5,6,8,10).
set_property MAX_FANOUT 8 \
    [get_cells -hierarchical -filter {NAME =~ "*u_pc/pc_out_reg*"}]

# flushD/flushE (fanout-44 endpoint on Paths 3,4,7,9).
set_property MAX_FANOUT 8 \
    [get_nets -hierarchical -filter {NAME =~ "*u_hzrd_unit/flushD*" || NAME =~ "*u_hzrd_unit/flushE*"}]
