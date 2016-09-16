function sb_pockels(base,active)

global sb org_pock;

if(base>0 || active>0)
    org_pock = [base active];   % save pockels value for network blanking
end

fwrite(sb,uint8([8 base active]));