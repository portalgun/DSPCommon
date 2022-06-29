%V=PtchsViewer(P,'DSP',1,'view');

lvlInd=1;
blocks=1;
if ~exist('PE','var')
end

PE=ptchs.getBlk(1,lvlInd,blocks,'TEST');

V=PtchsViewer(PE,'DSP',1,'exp'); V.run();

Blk.renew('P','P');



