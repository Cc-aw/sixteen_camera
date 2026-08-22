#ifndef HDMI_TX_TEST_H
#define HDMI_TX_TEST_H

int hdmi_tx_init(void);
void hdmi_tx_poll(void);
void hdmi_tx_restart(void);
int hdmi_tx_select_camera(unsigned camera_channel);
void hdmi_tx_print_status(void);

#endif
