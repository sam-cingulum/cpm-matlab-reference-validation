function run_script
assert(contains(version,'(R2026b) Update 1'));maxNumCompThreads(1);
folder=pwd;source=fullfile(folder,'upstream','codeshare_behavioralprediction.m');
files=dir('codeshare_*.mat');set(groot,'DefaultFigureVisible','off');
for rep=1:2
    rows=cell(1,numel(files));
    for j=1:numel(files)
        stage=tempname;mkdir(stage);
        copyfile(source,fullfile(stage,'codeshare_behavioralprediction.m'));
        copyfile(fullfile(folder,files(j).name),fullfile(stage,'OHBM_CPM_test_data.mat'));
        cd(stage);close all force;lastwarn('','');
        [workspace,transcript]=invoke;
        [msg,id]=lastwarn;
        figures=cell(1,3);
        for k=1:3
            f=figure(k);ax=findobj(f,'Type','axes');
            lines=findobj(ax,'Type','line');dot=lines(strcmp(get(lines,'Marker'),'.'));
            fit=lines(~strcmp(get(lines,'Marker'),'.'));assert(isscalar(dot) && isscalar(fit));
            figures{k}=struct('number',k,'title',ax.Title.String,'color',dot.Color, ...
                'x',{bits(dot.XData)},'y',{bits(dot.YData)},'fit_x',{bits(fit.XData)},'fit_y',{bits(fit.YData)});
        end
        % Independent public controls on the same scatter data and default axes.
        controls=cell(1,3);
        for k=1:3
            v=figures{k}; x=hex2num(char(v.x)); y=hex2num(char(v.y));
            f=figure('Visible','off'); plot(x,y,'.'); ax=gca;
            xlim0=ax.XLim; ylim0=ax.YLim; xticks0=ax.XTick; yticks0=ax.YTick;
            h=lsline; drawnow;
            slope=polyfit(x,y,1); model=[x,ones(size(y))]\y;
            controls{k}=struct('before_x',{bits(xlim0)},'before_y',{bits(ylim0)}, ...
                'xticks',{bits(xticks0)},'yticks',{bits(yticks0)},'after_x',{bits(ax.XLim)},'after_y',{bits(ax.YLim)},...
                'fit_x',{bits(h.XData)},'fit_y',{bits(h.YData)},'polyfit',{bits(slope)},'solve',{bits(model)}, ...
                'poly_y',{bits(polyval(slope,h.XData))},'solve_y',{bits(model(1)*h.XData+model(2))});
            close(f);
        end
        rows{j}=struct('id',files(j).name,'workspace',workspace,'figures',{figures}, ...
            'controls',{controls},'transcript',transcript,'warning_id',id,'warning_message',msg);
        close all force;cd(folder);
    end
    out.repetitions(rep).rows=rows;
end
out.commit=getenv('GITHUB_SHA');out.release=version;out.run=getenv('GITHUB_RUN_ID');
fid=fopen('original.json','w');assert(fid>=0);fprintf(fid,'%s\n',jsonencode(out));assert(fclose(fid)==0);
end
function [workspace,transcript]=invoke
transcript=evalc('codeshare_behavioralprediction');
vars=whos;
for i=1:numel(vars)
    if ~strcmp(vars(i).class,'double'),continue,end
    name=vars(i).name;x=eval(name);
    workspace.(name)=struct('shape',size(x),'hex',{bits(x)});
end
end
function b=bits(x)
b=cellstr(num2hex(x(:)));
end
