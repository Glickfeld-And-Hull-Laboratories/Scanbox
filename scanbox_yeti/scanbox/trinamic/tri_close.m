function tri_close()

global tri;

if ~isempty(tri)
    fclose(tri);
end
