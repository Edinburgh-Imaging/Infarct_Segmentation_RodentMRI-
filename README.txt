RodentAnalysisGUI is a tool used for the semi-automated analysis of brain T2-weighted MRI images in 
rodent models of focal cerebral ischaemia for the measurement of infarct volume.

The code requires MATLAB version 2015a or later. Unzip all files in a folder and set the MATLAB current
directory to this folder or add it to MATLAB search path.

Instructions for use
--------------------
1. Type 'RodentAnalysisGUI' in MATLAB's Command Window.
2. Press the 'Load' button in the 'Inputs' panel and select a tif image sequence for analysis. Images 
   must be bias field corrected (e.g. 1_corr.tif in the 'example scan' folder).
3. Examine the brain images in the 'Input Data' figure to determine which slices include the infarct.
   Fill the 'Analyse slices...' boxes in the 'Inputs' panel accordingly and check the rest of the 
   boxes in this panel for correctness; change where necessary (the voxel size in the example scan is 
   0.09765625 x 0.09765625 x 0.75 mm).
4. Load the masks of the ipsilateral brain hemisphere by pressing the corresponding 'Load' button in the
   'Inputs' panel.
5. Load or draw a region of interest in the healthy contralateral hemisphere in the middle slice without 
   including ventricles or any MRI artefacts by pressing the corresponding 'Load' or 'Draw' button. 
   If drawing, the GUI will initiate a polygon tool and the middle slice will be shown automatically
   in the 'Output Data' figure when 'Draw' is pressed. Follow the instructions in the GUI's log window 
   to draw the region.
6. Press the 'Measure volume' button in the 'Analysis' panel to measure the infarct volume.
7. Optionally, if manual refinement of the infarct boundary is required, press the 'Edit' button in the 
   'Analysis' panel and follow the instructions in the GUI's log window.
8. Optionally, if manual refinement of an already saved mask is required, check the box next to the 
   'Load to edit' button in the 'Analysis' panel, press the 'Load to edit' button and follow the 
   instructions in the GUI's log window. For this purpose, the corresponding brain scan and masks of the 
   ipsilateral hemisphere must be loaded in advance.

Notes:
- Instructions are given in the GUI's log window for all drawing steps; follow these to complete analysis.
- The infarct is detected by applying an intensity threshold in the ipsilateral hemipshere that is 
  estimated based on the mean and SD of the intensity in the region of interest selected in the 
  contralateral hemisphere. The default formula for estimating the threshold is mean+2.1xSD; the 
  factors multiplying the mean and SD can be changed in the 'Inputs' panel.
- The GUI's log window also lists all the measurements performed thus far. Volume estimates per slice   
  are shown in MATLAB's Command Window.
- The analysis is visualised in the 'Output Data' figure. Select 'Show: Overlaid' to show the infarct 
  boundary over the corresponding slices, or 'Show: Masks only' to show the infarct masks. 
- Check 'Save images?' and press 'Measure volume' again in the 'Analysis' panel to save the infarct masks 
  in the folder where the input image sequence is.

Example scan
------------
An example brain scan (1.tif), its bias field corrected version (1_corr.tif) and manually drawn masks of 
the ipsilateral brain hemisphere (1_ipsi.tif) are given. The example scan is a T2-weighted MRI scan of a 
Sprague-Dawley rat that was subjected to permanent middle cerebral artery occlusion, as part of a study 
assessing the influence of gender in the progression of ischaemic injury. It was acquired 24 hours 
post-occlusion with a 7 T MRI scanner and a rapid acquisition with relaxation enhancement (RARE) sequence 
with parameters:
  TR = 5086ms
  Effective TE = 72 ms
  RARE factor = 8
  Number of averages = 2
  Matrix size = 256x256 pixels
  Field of view = 25x25 mm
  Slice thickness = 0.75 mm
  16 coronal slices

Please cite the following article if this brain scan is used:
Baskerville, T. A., Macrae, I. M., Holmes, W. M., & McCabe, C. (2016). The influence of gender on 
'tissue at risk' in acute stroke: A diffusion-weighted magnetic resonance imaging study in a rat model 
of focal cerebral ischaemia. Journal of Cerebral Blood Flow and Metabolism, 36(2), 381-386. 
doi:10.1177/0271678x15606137


by Xenios Milidonis, last modified 11 August 2016
email: x.milidonis@sms.ed.ac.uk