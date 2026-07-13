# OSGCs
Code for OSGCs analysis

# patch data processing
abfload.m                  reads .abf files
FindMarker.m               finds light duration markers from data.abf 
Findspike.m                finds spike from data.abf
OS_RFmap.m                 reconstructs the RF center of an OSGC
count_spikes_to_spots.m    counts spikes for stimuli
resOS.m                    read VC/CC traces from data.abf
sVC_bars.m                 analyses the VC responses of stimuli
fBatchFitOrientationTuning_OBI_PP.m            draw polarplot for OSGCs 
fPlotOBI_TwoVonMisesPolarFit_ColorGroups_HWHM  clustering of OBI

# morphological data processing
sMorph_bars.m                    morphological data analysis
fPlotBoundariesFromXlsx_v5       analyses stratification of OSGCs 
