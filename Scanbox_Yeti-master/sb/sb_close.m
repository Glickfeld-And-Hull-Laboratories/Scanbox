function sb_close()

global sb;

if ~isempty(sb)
    fclose(sb);
end