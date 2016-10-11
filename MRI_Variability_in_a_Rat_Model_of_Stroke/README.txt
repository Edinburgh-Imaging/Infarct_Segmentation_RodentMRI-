Description: MRI Variability in a Rat Model of Stroke

The "sourcedata" folder contains T2-weighted MRI scans of 21 different Sprague-Dawley rats that were subjected 
to permanent middle cerebral artery occlusion, as part of a study assessing the influence of gender in the 
progression of ischaemic injury (Baskerville, et al., 2016). Scans were acquired 24 hours post-occlusion using
a 7 T Bruker BioSpec scanner and a rapid acquisition with relaxation enhancement (RARE) sequence with parameters:
  TR = 5000 ms
  Effective TE = 47 ms
  RARE factor = 8
  Number of averages = 2
  Matrix size = 256 x 256 pixels
  Field of view = 25 x 25 mm
  Slice thickness = 0.75 mm (no gap)
  Voxel size = 0.09765625 x 0.09765625 x 0.75 mm
  16 coronal slices


The "derivatives" folder contains corresponding transformed scans using 3D affine geometric transformations 
to simulate differences in the use of MRI at six different preclinical centres located across Europe. The aim 
of this simulation was to examine the impact of MRI variability in the measurement of infarct size. 
Specifically, three different cases were simulated:

case1: various linear scaling errors due to improper gradient calibration and voxel sizes in the centre-specific
       in vivo sequences
case2: various linear scaling errors due to improper gradient calibration but an identical voxel size
case3: various voxel sizes in the centre-specific in vivo sequences but no linear scaling errors


scaling_errors.tsv lists the linear scaling errors in each scanner for each case.
voxel_size.tsv lists the voxel sizes that can be used to measure infarct volume for each case and scanner. 
scaling_factors.tsv lists the scaling factors used to transform the scans, estimated based on the linear
  scaling errors, the voxel sizes and a correction factor for each direction to account for errors in the 
  scanner used to acquire the "sourcedata": x = -0.703, y = -1.449, z = -0.928


Please cite the following references if you use these data:
-----------------------------------------------------------
Baskerville, T. A., Macrae, I. M., Holmes, W. M., & McCabe, C. (2016). The influence of gender on 
'tissue at risk' in acute stroke: A diffusion-weighted magnetic resonance imaging study in a rat model 
of focal cerebral ischaemia. Journal of Cerebral Blood Flow and Metabolism, 36(2):381-386. 
doi:10.1177/0271678x15606137


This study was funded by an Anthony Watson studentship (Edinburgh Imaging, The University of Edinburgh) 
and partially supported by Multi-PART (Multicentre Preclinical Animal Research Team, http://www.multi-part.org).

Last modified 5 October 2016
Author: Xenios Milidonis
Email: x.milidonis@sms.ed.ac.uk