
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name test232 -dir "C:/Users/Yakov/OneDrive/School/University Stuff/ENEL500/test232/planAhead_run_4" -part xc3s250evq100-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/Yakov/OneDrive/School/University Stuff/ENEL500/test232/rs232.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/Yakov/OneDrive/School/University Stuff/ENEL500/test232} }
set_property target_constrs_file "rs232.ucf" [current_fileset -constrset]
add_files [list {rs232.ucf}] -fileset [get_property constrset [current_run]]
link_design
