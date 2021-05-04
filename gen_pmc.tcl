setws .
set hwdsgn [hsi::open_hw_design design_1_wrapper.xsa]
hsi::generate_app -os standalone -hw $hwdsgn -proc psu_pmu_0 -app zynqmp_pmufw -compile -sw pmufw -dir pmu


