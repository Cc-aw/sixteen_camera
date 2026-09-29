#include "platform.h"
#include "xparameters.h"
#include "xv_hdmirx.h"
#include "xv_hdmirxss.h"
#include "xv_hdmitx.h"
#include "xv_hdmitxss.h"
#include "xvphy.h"
#include "xvtc.h"

XV_HdmiRx_Config XV_HdmiRx_ConfigTable[XPAR_XV_HDMIRX_NUM_INSTANCES] = {
    { .DeviceId = 0U, .BaseAddress = HDMI_RX_BASE,
      .AxiLiteClkFreq = (u32)SOC_CLOCK_HZ }
};

XV_HdmiRxSs_Config
XV_HdmiRxSs_ConfigTable[XPAR_XV_HDMIRXSS_NUM_INSTANCES] = {
    {
        .DeviceId = 0U,
        .BaseAddress = HDMI_RX_BASE,
        .HighAddress = HDMI_RX_BASE + 0xFFFFU,
        .Ppc = XVIDC_PPC_2,
        .MaxBitsPerPixel = 8U,
        .HdcpTimer = { 0U, 255U, 0U },
        .Hdcp14 = { 0U, 255U, 0U },
        .Hdcp22 = { 0U, 255U, 0U },
        .HdmiRx = { 1U, 0U, HDMI_RX_BASE },
    }
};

XV_HdmiTx_Config XV_HdmiTx_ConfigTable[XPAR_XV_HDMITX_NUM_INSTANCES] = {
    { .DeviceId = 0U, .BaseAddress = HDMI_TX_BASE,
      .AxiLiteClkFreq = (u32)SOC_CLOCK_HZ }
};

XVtc_Config XVtc_ConfigTable[XPAR_XVTC_NUM_INSTANCES] = {
    { .DeviceId = 0U, .BaseAddress = HDMI_TX_VTC_BASE }
};

XV_HdmiTxSs_Config
XV_HdmiTxSs_ConfigTable[XPAR_XV_HDMITXSS_NUM_INSTANCES] = {
    {
        .DeviceId = 0U,
        .BaseAddress = HDMI_TX_BASE,
        .HighAddress = HDMI_TX_BASE + 0x1FFFFU,
        .Ppc = XVIDC_PPC_2,
        .MaxBitsPerPixel = 8U,
        .LowResolutionSupp = 0U,
        .YUV420Supp = 1U,
        .AxiLiteClkFreq = (u32)SOC_CLOCK_HZ,
        .HdcpTimer = { 0U, 255U, 0U },
        .Hdcp14 = { 0U, 255U, 0U },
        .Hdcp22 = { 0U, 255U, 0U },
        .HdmiTx = { 1U, 0U, HDMI_TX_BASE },
        .Vtc = { 1U, 0U, HDMI_TX_VTC_BASE },
    }
};

XVphy_Config XVphy_ConfigTable[XPAR_XVPHY_NUM_INSTANCES] = {
    {
        .DeviceId = 0U,
        .BaseAddr = VPHY_BASE,
        .XcvrType = XVPHY_GT_TYPE_GTYE4,
        .TxChannels = 4U,
        .RxChannels = 3U,
        .TxProtocol = XVPHY_PROTOCOL_HDMI,
        .RxProtocol = XVPHY_PROTOCOL_HDMI,
        .TxRefClkSel = (XVphy_PllRefClkSelType)4U,
        .RxRefClkSel = (XVphy_PllRefClkSelType)0U,
        .TxSysPllClkSel = (XVphy_SysClkDataSelType)6U,
        .RxSysPllClkSel = (XVphy_SysClkDataSelType)0U,
        .DruIsPresent = 0U,
        .DruRefClkSel = (XVphy_PllRefClkSelType)0U,
        .Ppc = XVIDC_PPC_2,
        .TxBufferBypass = 1U,
        .HdmiFastSwitch = 1U,
        .TransceiverWidth = 2U,
        .ErrIrq = 0U,
        .AxiLiteClkFreq = (u32)SOC_CLOCK_HZ,
        .DrpClkFreq = (u32)SOC_CLOCK_HZ,
        .UseGtAsTxTmdsClk = 1U,
        .DpTxProtocol = 0U,
        .DpRxProtocol = 0U,
    }
};
