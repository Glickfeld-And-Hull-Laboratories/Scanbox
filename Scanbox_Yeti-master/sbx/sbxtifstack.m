function sbxtifstack(re)

sbxaligndir([re '*.sbx'])

d = dir([re '*.align']);
fn = [re '_stack.tif'];

for(i=1:length(d))
    load('-mat',d(i).name)
    if(i==1)
        imwrite(m,fn,'tif');
    else
        imwrite(m,fn,'tif','writemode','append');
    end
end
