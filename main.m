classdef main < handle
%rsync -aP /Volumes/Data/.daveDB/exp/*.mat deb:/MNT/STORAGE/DATA/Data/.daveDB/exp
%rsync -aP /Volumes/Data/.daveDB/raw/*.mat deb:/MNT/STORAGE/DATA/Data/.daveDB/raw
methods(Static)
%% INIT EXP
    function gen_b()
        %ind=ismember(P.idx.B,[1 4 8 13]) & ~P.Flags.other & ~P.Flags.seen;
        %P.Flags.bad(ind)=false;
        %P.Flags.save();
        %Blk.gen();
        Blk.renew();
        %main.flag_not_exist();
    end
    function gen_e()
        ETable.fromBlk([],{'JDB','DNW'},'rand','ordered');
        alias=Env.var('ALIAS');
        STable.changeMode('DNW',alias,2);
    end
    function gen_b_flat()
        B=Blk.get();
        %ind=B.opts.table(ismember(B.opts.key,'flatAnchor'));
        B.opts.table(:,ismember(B.opts.key,'flatAnchor'))=repmat({'L'},size(B.opts.table,1),1);
        B.saveas('DSP2f');

    end
    function E=gen_e_flat()
        alias='DSP2f';
        ETable.fromBlk(alias,{'JDB','DNW'},'rand','ordered');
        STable.changeMode('DNW',alias,2);

        B=Blk.get(alias);
        r=B.lookup.lvl{'disparity',[1 3 5],'bins',[1 4],'stdInd'};

        E=Exp(alias);
        E.ETable.Table('lvlInd','~=',r,'status')=-1;
        E.ETable.save();
    end
    function add_flat_subj(subj)
        alias='DSP2f';
        E=Exp(alias);
        E.addSubj(subj);
        % Exp.addSubj(subj)
    end
    function make_flat_easy_train(subj)
        alias='DSP2f';
        %r=B.lookup.lvl{'disparity',1:2,'bins',[1 4],'stdInd'};
        r=B.lookup.lvl{'disparity',1:2,'stdInd'};

        E=Exp(alias);
        E.ETable.Table('subj',subj,'lvlInd','~=',r,'mode','~=',3,'status')=-1;
        E.changeMode(subj,3);

        E.ETable.save();
        E.STable.save();

    end
    function gen_pre()
        bins=[19 25 30 35 39];
        ImapSmp.create_pre('DSP2',bins);
    end
    function gen_preExtra()
        bins=[19 25 30 35 39];
        ImapSmp.create_pre('DSP2_add',bins);
    end
    function gen_extra()
        Imap.run('DSP2_add','smp');
        Imap.run('DSP2_add','tbl');
        P=ptchs.get();
        P.addExtra('DSP2_add');
        main.gen_b();

    end
    function P=gen_ptchs_new(P)
        if nargin < 1 || isempty(P)
            P=ptchs.getRaw('all');
        end
        [~,inds]=Blk.get();
        %P.gen_ptch_all(inds,'ptchAlias','DSP2');
        P.gen_ptch_all(inds,'ptchAlias','DSP2','bCheckAll',true,'bSkipBadList',true);
    end
    function P=gen_ptchs(inds,P)
        % NOTE: backup and fix flags before running
        if nargin >=1 && ~isempty(inds) && islogical(inds)
            inds=find(inds);
        end
        if nargin < 2 || isempty(P)
            P=ptchs.getRaw('all');
        end
        inds=find(ismember(P.idx.B,[1 4 8 13]));
        %P.gen_ptch_all(inds,'ptchAlias','DSP2','bCheckAll',true);
        P.gen_ptch_all(inds,'ptchAlias','DSP2');
    end
    function gen_ptchs_blk(P)
        if nargin < 1
            P=ptchs.getBlk('all');
        end
        P.gen_ptch_all_blk('ptchAlias','DSP2','bCheckAll',true);
    end
%% GET
    function tblP=get_pre()
        bins=[1,4,8,13,17];
        hash='d7688d789dbae46fccee9888162cb451';

        preFname=['/Volumes/Data/.daveDB/imap/all/' hash '/_smp_pre_.mat'];
        db=dbInfo('LRSI');
        S=load(preFname);
        tblP=ImapSmp.pre_to_table(S.PctrInds,db.IszRC,bins);
    end
    function tbl=get_preExtra();
        bins=[1,4,8,13,17];
        %bins=1:5;
        %bins=[19 25 30 35 39];
        hash='2de113e3708658803cfa62f6c8135e3a';

        preFname=['/Volumes/Data/.daveDB/imap/all/' hash '/_smp_pre_.mat'];
        db=dbInfo('LRSI');
        S=load(preFname);
        tbl=ImapSmp.pre_to_table(S.PctrInds,db.IszRC,bins);
    end
    function tbl=get_src()
        bins=[1,4,8,13,17];
        oHash='44270c0b5ce4439c39788751bfd0403e';
        tbl=main.getIndsSrc(oHash,bins,0);
    end
    function tbl=get_src_extra()
        bins=[1,4,8,13,17];
        eHash='31ac702b1248115f07d27503a372383a';
        tbl=main.getIndsSrc(eHash,bins,1);
    end
    function tbl=getIndsSrc(hash,bins,bChange)
        FLDS={'B','I','K','PctrRC'};
        %FLDS={'B','PctrRC'};
        types={'double','char','double','double','double','double','double','double','double'};

        dire=ptch.get_directory_p('LRSI', hash);
        S=load([dire '_src_']);

        n=size(S.table,1);
        tbl=zeros(n,numel(FLDS)+1);
        for i = 1:length(FLDS)-1
            tbl(:,i)=vertcat(S.table{:,ismember(S.key,FLDS{i})});
        end
        tbl(:,end-1:end)=vertcat(S.table{:,ismember(S.key,'PctrRC')});


        tbl(:,1)=tbl(:,1)*-1;
        B=flipud(unique(tbl(:,1)))';
        if bChange
            for i = 1:length(bins)
                bind=tbl(:,1)==B(i);
                tbl(bind,1)=bins(i);
            end
        end
        tbl(~ismember(tbl(:,1),bins),:)=[];
        %PctrInds=round(PctrInds);
        %PctrInds(:,1)=[];
    end
%% CHECK
    function check_ptch_src(P)
        % DONE
        bins=[1,4,8,13,17];
        tblP=P.to_table(bins);
        tblS=main.get_src();

        out=ismember(tblS,tblP,'rows');
        disp(sum(out)/size(out,1))

        out=ismember(tblP,tblS,'rows');
        disp(sum(out)/size(out,1))
    end
    function check_pre_ptchs(P)
        % DONE
        bins=[1,4,8,13,17];
        db=dbInfo('LRSI');

        tblS=main.get_pre();

        tblP=P.to_table(bins);

        out=ismember(tblS,tblP,'rows');
        disp(sum(out)/size(out,1))

        out=ismember(tblP,tblS,'rows');
        disp(sum(out)/size(out,1))
    end
    function check_preExtra_srcExtra()
        % DONE
        bins=[1,4,8,13,17];

        tblS=main.get_src_extra();

        tblP=main.get_preExtra();

        %out=false(size(tblP,1),1);
        %for i = 1:size(tblP,1)
        %    out(i)=ismembertol([tblP(i,:)],tblS,.1,'ByRows',true,'DataScale',1);
        %end

        out=ismembertol(tblS,tblP,.2,'ByRows',true,'DataScale',1);
        disp(sum(out)/size(out,1))

        out=ismembertol(tblP,tblS,.2,'ByRows',true,'DataScale',1);
        disp(sum(out)/size(out,1))
    end
    function check_pre_preExtra()
        % NOT ALL PRE-SAMPLES END UP IN SAMPLED
        % PROBLEM IN IMAPSMP, EVERYTHING ELSE RULED OUT
        % XXX***
        tblE=main.get_preExtra();
        tblP=main.get_pre();

        %inds=[1,2,3,4,5];
        %tblS=tblS(:,inds);
        %tblP=tblP(:,inds);
        tblP=unique(tblP,'rows');
        tblE=unique(tblE,'rows');

        disp('abs')
        out=ismember(tblE,tblP,'rows');
        disp(sum(out)/size(out,1))


        out=ismember(tblP,tblE,'rows');
        disp(sum(out)/size(out,1))
        % SHOULD BE 1


        return

        disp('tol')
        out=ismembertol(tblS,tblP,.2,'ByRows',true,'DataScale',1);
        disp(sum(out)/size(out,1))


        out=ismembertol(tblP,tblS,.2,'ByRows',true,'DataScale',1);
        disp(sum(out)/size(out,1))

        disp('loop')
        out=false(size(tblP,1),1);
        for i = 1:size(tblP,1)
            out(i)=ismember(tblP(i,:),tblS,'rows');
        end
        disp(sum(out)/size(out,1))

        out=false(size(tblS,1),1);
        for i = 1:size(tblS,1)
            out(i)=ismember(tblS(i,:),tblP,'rows');
        end
        disp(sum(out)/size(out,1))


        % SHOULD BE 1
    end
    function check_pre_srcExtra()
        % XXX
        bins=[1,4,8,13,17];

        tblS=main.get_src_extra();

        tblP=main.get_pre();
        size(tblS)
        size(tblP)

        %out=false(size(tblP,1),1);
        %for i = 1:size(tblP,1)
        %    out(i)=ismembertol([tblP(i,:)],tblS,.1,'ByRows',true,'DataScale',1);
        %end

        out=ismembertol(tblS,tblP,.2,'ByRows',true,'DataScale',1);
        disp(sum(out)/size(out,1))

        out=ismembertol(tblP,tblS,.2,'ByRows',true,'DataScale',1);
        disp(sum(out)/size(out,1))
    end
    function check_preExtra_ptchs(P)
        % XXX
        bins=[1,4,8,13,17];
        db=dbInfo('LRSI');

        tblS=main.get_preExtra();

        tblP=P.to_table(bins);

        out=ismember(tblS,tblP,'rows');
        disp(sum(out)/size(out,1))

        out=ismember(tblP,tblS,'rows');
        disp(sum(out)/size(out,1))
    end
    function check_ptch_srcExtra(P)
        % XXX
        bins=[1,4,8,13,17];
        tblP=P.to_table(bins);
        tblS=main.get_src_extra();

        out=ismembertol(tblS,tblP,.2,'ByRows',true,'DataScale',1);
        disp(sum(out)/size(out,1))

        out=ismembertol(tblP,tblS,.2,'ByRows',true,'DataScale',1);
        disp(sum(out)/size(out,1))
    end
    function check_src_src()
        PctrIdndsO=main.get_src();
        PctrIdndsE=main.get_src_extra();
        %PctrIndsE(:,end-1:end)=fliplr(PctrIndsE(:,end-1:end));


        out1=ismember(PctrIndsE,PctrIndsO,'rows');
        disp(sum(out1)/size(out1,1)) % SHOULD EQUAL 1

        out2=ismember(PctrIndsO,PctrIndsE,'rows');
        disp(sum(out2)/size(out2,1))
        %PctrIndsO(~out1,:)
        %PctrIndsE(~out,:)
    end
    function dots=get_pht_dot_ptchs(P,kernSz)
        if nargin < 1
            P=ptchs.getRaw('all');
        end
        dots=CP_verify.pht_dot_ptchs(P,kernSz,true);
        %dots=CP_verify.pht_dot_ptchs(P,[3,3],true);
    end
    function view_dotPtchs(P,kernSz,bins)
        if nargin < 3
            bins=[];
        end
        CP_verify.view_dot_ptchs(P,kernSz,bins);
    end
    function get_rms_ptchs(P)
        CP_verify.rms_ptchs(P,true);
    end

%% FLAGGING
    function reset_flag()
        P=ptchs.getBlk('all');
        P.Flags.accum_seen_SEEN();
        P.Flags.save();
    end
    function bInd=get_not_gen(bFixFlags)
        if nargin < 1
            bFixFlags=false;
        end
        P=ptchs.getRaw('all');
        bExist=P.exist(false,[1 4 8 13]);

        P.Flags.load();

        bBad=P.load_badGen;
        bInd=bExist==0 & ~bBad;

        if bFixFlags
            P.Flags.bad=P.Flags.bad & bExist~=0 & ~bBad;
            P.Flags.save();
        end
    end

    function bInd=flag_not_exist(bBlk,bins)
        %while true
            if nargin < 1
                bBlk=[];
            end
            bInd=ptchs.exist(bBlk,bins);
            if sum(bInd) == 0
                return
            else
                disp(sum(bInd));
            end
            if nargout < 1
                P.Flags.bad(nums(bInd))=true;
                P.Flags.save();
            end
            %Blk.renew();
        %end
    end
    function flag_pilot()
        P=ptchs.getBlk(2,'all','all','TEST');

        lvls=[];

        lvls=Set.distribute(1:5,1:4);

         lvls=[...
        %       1 1;
        %       2 1;
        %       3 1;
        %       4 1;
               1 1;
         ];

        % lvls=[...
        %       1 2;
        %       2 2;
        %       3 2;
        %       4 2;
        %       5 2;
        % ];

        % lvls=[...
        %       1 3;
        %       2 3;
        %       3 3;
        %       4 3;
        %       5 3;
        % ];

        % lvls=[...
        %       1 4;
        %       2 4;
        %       3 4;
        %       4 4;
        %       5 4;
        % ];

        % lvls=[...
        %       1 5;
        %       2 5;
        %       3 5;
        %       4 5;
        %       5 5;
        % ];


        %P.Blk.blk=P.Blk('lvl',lvls,'mode',2,'blk',1);
        if ~isempty(lvls)
            P.Blk=P.Blk('lvl',lvls);
        end
        P.getStat('rms');
        P.getStat('dot',[3,3]);

        alias=Env.var('ALIAS');
        VF=PtchsViewer(P,'DSP',1,'view');
        assignin('base','VF',VF);
        VF.run();

        %VF.Flags.save()
        %Blk.renew
    end
    function renew()
        % REGEN BLK WITH FLAGS
        Blk.renew();
        % GET THOSE MISSING
        ptchs.gen();
    end

%% PILOT
    function pilot()
        lvls=[...
              5 1;
              %1 1;

              %5 2;
              %1 2;

              %5 1;
              %1 3;

              %5 4;
              %1 4;

              %1 1;
              %2 1;
              %2 1;
              %2 4;

                %3 1;
                %2 2;
                %4 2;
                %5 1;
                %5 2;
                %2 2;
              %4 4;
              %3 4;
              %4 4;

              %3 1;
              %3 1;
              %3 4;
              %3 2;

              %4 1;
              %2 1;
              %2 4;
        ];

        runSubj('DNW','lvl',lvls);
    end
    function pilot_flat()
        lvls=[...
              5 1;
              5 4;

              1 1;
              1 4;

              %3 1;
              %3 5;

        ];

        runSubj('DNW','alias','DSP2f','lvl',lvls);
    end
    function EP=plot_flat(subj,moude,lvlInds,passes)
        alias='DSP2f';
        if nargin < 1 || isempty(subj)
            subj=getenv('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=STable.getMode(subj,alias);
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        if nargin < 4 || isempty(passes)
            passes=1;
        end
        opts=struct('nBoot',1,'bPlotCI',false,'bMFix',false,'nBest',100);
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,1,'');

        EP.plot();
    end
    function EP=plot(subj,moude,lvlInds,passes)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=getenv('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=STable.getMode(subj,alias);
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        if nargin < 4 || isempty(passes)
            passes=1;
        end
        opts=struct('nBoot',1,'bPlotCI',false,'bMFix',false,'nBest',100);
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,1,'');

        EP.plot();
        %EP.plotT();
    end
    function EP=plotBoot1000(subj,moude,lvlInds)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=Env.var('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=1;
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        passes=1;

        opts=struct('nBoot',1000,'bPlotCI',false,'bMFix',false,'nBest',1);
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,2,'boot1000');

        %EP.plot();
        EP.plotT();
    end
    function plot_all_double(subj,moude,lvlInds)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=Env.var('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=1;
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end

        passes=[1 2];
        opts=main.fixOpts;
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,3,'Corr',true);

        passes=[1 2];
        opts=main.nofixOpts;
        EPn=main.EPget(alias,subj,moude,lvlInds,passes,opts,3,'Corr',true);

        EP.plotCorr();
        EPn.plotMagr();
        EPn.scatterRho();
        EPn.scatterRho(true);
        EPn.scatterRho(true,true);
        EPn.histRho();
        EPn.histRho(true);
    end
    function plot_Corr(subj,moude,lvlInds)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=Env.var('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=1;
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        passes=[1 2];
        opts=main.fixOpts;
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,3,'Corr',true);

        EP.plotCorr();
    end
    function plot_Magr(subj,moude,lvlInds)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=Env.var('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=1;
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        passes=[1 2];
        opts=main.nofixOpts;
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,4,'Magr',true);

        EP.plotMagr();
    end
    function scatter(subj,moude,lvlInds)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=Env.var('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=1;
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        passes=[1 2];
        opts=main.nofixOpts;
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,4,'Scatt',true);

        EP.scatterRho();
    end
    function scatterR(subj,moude,lvlInds)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=Env.var('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=1;
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        passes=[1 2];
        opts=main.nofixOpts;
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,4,'ScattR',true);

        EP.scatterRho(true);
    end
    function scatterRM(subj,moude,lvlInds)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=Env.var('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=1;
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        passes=[1 2];
        opts=main.nofixOpts;
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,4,'ScattRM',true);

        EP.scatterRho(true,true);
    end
    function allSubj(subj)
        main.blkDate(subj,1,[],1);
        main.blkDate(subj,1,[],2);

        EP=main.plot(subj,1,[],1);
        EP.plotT;
        EP.plotTT;

        main.plot_all_double('JDB',1,[]);
    end
    function blkDate(subj,moude,lvlInds,passes)
        alias='DSP2';
        if nargin < 1 || isempty(subj)
            subj=getenv('lastSubj');
            if isempty(subj)
                subj='DNW';
            end
        end
        if nargin < 2 || isempty(moude)
            moude=STable.getMode(subj,alias);
        end
        if nargin < 3 || isempty(lvlInds)
            lvlInds=[];
        end
        if nargin < 4 || isempty(passes)
            passes=1;
        end
        opts=struct('nBoot',1,'bPlotCI',false,'bMFix',false,'nBest',100,'bBlk',true);
        EP=main.EPget(alias,subj,moude,lvlInds,passes,opts,1,'');

        EP.plotT();
        %EP.plotT();
    end
%%
    function EP=EPget(alias,subj,moude,lvlInds,passes,opts,num,name,bDV)
        bTest=true;
        if isempty(alias)
            alias='DSP2';
        end
        if nargin < 9 || isempty(bDV)
            bDV=false;
        end
        if numel(passes) > 1
            num=str2double(strrep(num2str([1 2]),' ',''))*10+num;
        else
            num=passes*10+num;
        end
        fname=EPsyCurve.get_fname(alias,subj,moude,passes,name);
        if ~bTest && Fil.exist(fname)
            EP=EPsyCurve.load(alias,subj,moude,passes,name);
        else
            EP=EPsyCurve(alias,subj,moude,passes,{'disparity','bin'},lvlInds,num,name);
            assignin('base',['EP_' alias],EP);
            assignin('base','obj',EP);
            if bDV
                EP.getDVCorr(opts);
            else
                EP.getCurves(opts);
            end
            EP.save;
        end
    end
    function opts=nofixOpts()
        opts=struct('modelType','RMM','nBoot',1,'nParabSim',100,'Magr',2,'bRhoFixCmp',false,'bMu1FixCmp',false,'bMu2FixCmp',false,'bCr1FixCmp',false,'bCr2FixCmp',false);
    end
    function opts=fixOpts()
        opts=struct('modelType','RMM','nBoot',1,'nParabSim',100,'Magr',2,'bRhoFixCmp',true,'bMu1FixCmp',false,'bMu2FixCmp',false,'bCr1FixCmp',false,'bCr2FixCmp',false);
    end

    function lvls=get_lvls(ctr,d)
        s=ctr-d*2;
        e=ctr+d*2;
        lvls=linspace(s,e,5);
    end
    function unflag_new(P)
        bInd=main.newInd;
        P.Flags.bad(bInd)=false;
        P.Flags.save();
    end
    function bInd=newInd(P)
        new=main.new_fnames();
        bInd=ismember(P.fnames,new);
    end
end
end
