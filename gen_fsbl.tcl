set hwdsgn [hsi::open_hw_design design_1_wrapper.xsa]
hsi::generate_app -hw $hwdsgn -os standalone -proc psu_cortexa53_0 -app zynqmp_fsbl -compile -sw fsbl -dir fsbl

