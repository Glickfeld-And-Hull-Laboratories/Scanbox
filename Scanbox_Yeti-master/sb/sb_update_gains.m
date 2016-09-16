global sbconfig;

sb_galvo_dv(sbconfig.dv_galvo);
sb_set_mag_x_0(sbconfig.gain_resonant(1));
sb_set_mag_x_1(sbconfig.gain_resonant(2));
sb_set_mag_x_2(sbconfig.gain_resonant(3));
sb_set_mag_y_0(sbconfig.gain_galvo(1));
sb_set_mag_y_1(sbconfig.gain_galvo(2));
sb_set_mag_y_2(sbconfig.gain_galvo(3));