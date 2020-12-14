set hwdsgn [open_hw_design design_1_wrapper.hdf]
generate_app -hw $hwdsgn -os standalone -proc psu_pmu_0 -app zynqmp_pmufw -compile -sw pmufw -dir pmu
quit

