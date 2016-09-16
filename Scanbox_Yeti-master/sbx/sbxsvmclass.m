function r = sbxsvmclass(img)

global svm;

img = zscore(img(:))';

r = svmclassify(svm,img);

