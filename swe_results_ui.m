function varargout = swe_results_ui(varargin)
% User interface for SwE results: Display and analysis of regional effects
% =========================================================================
% FORMAT: [hReg,xSwE,SwE] = spm_spm_results_uicB('Setup',[xSwE])
% -------------------------------------------------------------------------
% Inputs/Outputs:
%  - hReg: handle of MIP XYZ registry object
%          (see spm_XYZreg.m for details)
%  - xSwE: structure containing specific SwE data, distribution & filtering 
%          details (see spm_getSPM.m for contents)
%  - SwE: SwE structure containing generic parameters
%         (see spm_spm.m for contents)
% =========================================================================
%
% NB: Results section GUI CallBacks use these data structures by name,
%     which therefore *must* be assigned to the correctly named variables.
%__________________________________________________________________________
%
% The SwE results section is for the interactive exploration and
% characterisation of the results of a statistical analysis.
%
% The user is prompted to select a SwE{T} or SwE{F} image, that is
% thresholded at user specified levels. For a parametric analysis, the 
% specification of the contrasts to use and the height and size thresholds 
% are described in spm_getSPM.m. For a non-parametric analysis the height 
% threshold may have been set earlier in the matlab batch specification.
% The resulting SwE data is then displayed in the graphics window as a 
% maximum intensity projection, alongside the design matrix and contrasts
% employed.
%
% The cursors in the MIP can be moved (dragged) to select a particular
% voxel. The three mouse buttons give different drag and drop behaviour:
% Button 1 - point & drop; Button 2 - "dynamic" drag & drop with
% co-ordinate & SwE value updating; Button 3 - "magnetic" drag & drop,
% where the cursor jumps to the nearest suprathreshold voxel in the
% MIP, and shows the value there. (See spm_mip_ui.m, the MIP GUI handling
% function for further details.)
%
% The design matrix and contrast pictures are "surfable": Click and
% drag over the images to report associated data. Clicking with
% different buttons produces different results. Double-clicking
% extracts the underlying data into the base workspace.
% See spm_DesRep.m for further details.
%
% The current voxel specifies the voxel, suprathreshold cluster, or
% orthogonal planes (planes passing through that voxel) for subsequent
% localised utilities.
%
% A control panel in the Interactive window enables interactive
% exploration of the results.
%
% p-values buttons:
%   (i) volume   - Tabulates p-values and statistics for entire volume.
%                                            - see swe_list.m
%  (ii) cluster  - Tabulates p-values and statistics for nearest cluster
%                - Note that the cursor will jump to the nearest
%                  suprathreshold voxel, if it is not already at a
%                  location with suprathreshold statistic.
%                                            - see swe_list.m
%
% Visualisation buttons:
%   (i) plot     - Graphs of adjusted and fitted activity against
%                  various ordinates.
%                - Note that the cursor will jump to the nearest
%                  suprathreshold voxel, if it is not already at a
%                  location with suprathreshold statistic.
%                - Additionally, returns fitted and adjusted data to the
%                  MATLAB base workspace.
%                                               - see swe_graph.m
%                  (Currently only works for T contrasts)
%  (ii) overlays - Popup menu: Overlays of filtered SPM on a structural image
%     -   slices - Slices of the thresholded statistic image overlaid
%                  on a secondary image chosen by the user. Three
%                  transverse slices are shown, being those at the
%                  level of the cursor in the z-axis and the two
%                  adjacent to it.           - see spm_transverse.m
%     - sections - Orthogonal sections of the thresholded statistic
%                  image overlaid on a secondary image chosen by the user.
%                  The sections are through the cursor position.
%                                            - see spm_sections.m
%     -   render - Render blobs on previously extracted cortical surface
%                                            - see spm_render.m
% (iii) save     - Write out thresholded SwE data as image
%                                            - see spm_write_filtered.m
%
% The current cursor location can be set by editing the co-ordinate
% widgets at the bottom of the interactive window. (Note that many of the
% results section facilities are "linked" and can update co-ordinates. E.g.
% clicking on the co-ordinates in a p-value listing jumps to that location.)
%
% Graphics appear in the bottom half of the graphics window, additional
% controls and questions appearing in the interactive window.
%
%                           ----------------
%
% The MIP uses a template outline in MNI space. Consequently for
% the results section to display properly the input images to the
% statistics section should be in MNI space.
%
% Similarly, secondary images should be aligned with the input images
% used for the statistical analysis.
%
%                           ----------------
%
% In addition to setting up the results section, swe_results_ui.m sets
% up the results section GUI and services the CallBacks. FORMAT
% specifications for embedded CallBack functions are given in the main
% body of the code.
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging
 
% Original SPM code by Karl Friston & Andrew Holmes
% Adapted by Bryan Guillaume
% $Id: swe_results_ui.m 3928 2010-06-16 12:09:22Z guillaume $
 
 
%==========================================================================
% - FORMAT specifications for embedded CallBack functions
%==========================================================================
%( This is a multi function function, the first argument is an action  )
%( string, specifying the particular action function to take.          )
%
% swe_results_ui sets up and handles the SwE results graphical user
% interface, initialising an XYZ registry (see spm_XYZreg.m) to co-ordinate
% locations between various location controls.
%
%__________________________________________________________________________
%
% FORMAT [hreg,xSwE,SwE] = swe_results_ui('Setup')
% Query SwE and setup GUI. 
%
% FORMAT [hreg,xSwE,SwE] = swe_results_ui('Setup',xSwE)
% Query SwE and setup GUI using a xSwE input structure. This allows to run
% results setup without user interaction. See spm_getSPM for details of
% allowed fields.
%
% FORMAT hReg = swe_results_ui('SetupGUI',M,DIM,xSwE,Finter)
% Setup results GUI in Interactive window
% M       - 4x4 transformation matrix relating voxel to "real" co-ordinates
% DIM     - 3 vector of image X, Y & Z dimensions
% xSwE    - structure containing xSwE. Required fields are:
% .Z      - minimum of n Statistics {filtered on u and k}
% .XYZmm  - location of voxels {mm}
% Finter  - handle (or 'Tag') of Interactive window (default 'Interactive')
% hReg    - handle of XYZ registry object
%
% FORMAT swe_results_ui('DrawButts',hReg,DIM,Finter,WS,FS)
% Draw GUI buttons
% hReg    - handle of XYZ registry object
% DIM     - 3 vector of image X, Y & Z dimensions
% Finter  - handle of Interactive window
% WS      - WinScale  [Default spm('WinScale') ]
% FS      - FontSizes [Default spm('FontSizes')]
%
% FORMAT hFxyz = swe_results_ui('DrawXYZgui',M,DIM,xSwE,xyz,Finter)
% Setup editable XYZ control widgets at foot of Interactive window
% M      - 4x4 transformation matrix relating voxel to "real" co-ordinates
% DIM    - 3 vector of image X, Y & Z dimensions
% xSwE   - structure containing SwE; Required fields are:
% .Z     - minimum of n Statistics {filtered on u and k}
% .XYZmm - location of voxels {mm}
% xyz    - Initial xyz location {mm}
% Finter - handle of Interactive window
% hFxyz  - handle of XYZ control - the frame containing the edit widgets
%
% FORMAT swe_results_ui('EdWidCB')
% Callback for editable XYZ control widgets
%
% FORMAT swe_results_ui('UpdateSPMval',hFxyz)
% FORMAT swe_results_ui('UpdateSPMval',UD)
% Updates SwE value string in Results GUI (using data from UserData of hFxyz)
% hFxyz - handle of frame enclosing widgets - the Tag object for this control
% UD    - XYZ data structure (UserData of hFxyz).
%
% FORMAT xyz = swe_results_ui('GetCoords',hFxyz)
% Get current co-ordinates from editable XYZ control
% hFxyz - handle of frame enclosing widgets - the Tag object for this control
% xyz   - current co-ordinates {mm}
% NB: When using the results section, should use XYZregistry to get/set location
%
% FORMAT [xyz,d] = swe_results_ui('SetCoords',xyz,hFxyz,hC)
% Set co-ordinates to XYZ widget
% xyz   - (Input) desired co-ordinates {mm}
% hFxyz - handle of XYZ control - the frame containing the edit widgets
% hC    - handle of calling object, if used as a callback. [Default 0]
% xyz   - (Output) Desired co-ordinates are rounded to nearest voxel if hC
%         is not specified, or is zero. Otherwise, caller is assumed to
%         have checked verity of desired xyz co-ordinates. Output xyz returns
%         co-ordinates actually set {mm}.
% d     - Euclidean distance between desired and set co-ordinates.
% NB: When using the results section, should use XYZregistry to get/set location
%
% FORMAT hFxyz = swe_results_ui('FindXYZframe',h)
% Find/check XYZ edit widgets frame handle, 'Tag'ged 'hFxyz'
% h     - handle of frame enclosing widgets, or containing figure [default gcf]
%         If ischar(h), then uses spm_figure('FindWin',h) to locate named figures
% hFxyz - handle of confirmed XYZ editable widgets control
%         Errors if hFxyz is not an XYZ widget control, or a figure containing
%         a unique such control
%
% FORMAT swe_results_ui('PlotUi',hAx)
% GUI for adjusting plot attributes - Sets up controls just above results GUI
% hAx - handle of axes to work with
%
% FORMAT swe_results_ui('PlotUiCB')
% CallBack handler for Plot attribute GUI
%
% FORMAT Fgraph = swe_results_ui('Clear',F,mode)
% Clears results subpane of Graphics window, deleting all but semi-permanent
% results section stuff
% F      - handle of Graphics window [Default spm_figure('FindWin','Graphics')]
% mode   - 1 [default] - clear results subpane
%        - 0           - clear results subpane and hide results stuff
%        - 2           - clear, but respect 'NextPlot' 'add' axes
%                        (which is set by `hold on`)
% Fgraph - handle of Graphics window
%
% FORMAT hMP = swe_results_ui('LaunchMP',M,DIM,hReg,hBmp)
% Prototype callback handler for integrating MultiPlanar toolbox
%
% FORMAT swe_results_ui('Delete',h)
% deletes HandleGraphics objects, but only if they're valid, thus avoiding
% warning statements from MATLAB.
%__________________________________________________________________________
% Modified version of spm_results_ui by Bryan Guillaume 

spm('defaults','FMRI')% to avoid trouble with testing
%-Condition arguments
%--------------------------------------------------------------------------
if nargin == 0, Action='setup'; else Action=varargin{1}; end


%==========================================================================
switch lower(Action), case 'setup'                         %-Set up results
%==========================================================================
 
    %-Initialise
    %----------------------------------------------------------------------
    [Finter,Fgraph,CmdLine] = spm('FnUIsetup','Stats: Results');
    spm_clf('Satellite')
    FS    = spm('FontSizes');

    %-Get thresholded xSwE data and parameters of design
    %======================================================================
    if nargin > 1
        [SwE,xSwE] = swe_getSPM(varargin{2});
    else
        [SwE,xSwE] = swe_getSPM;
    end
    
    % check format of data
    [~,~,file_ext] = fileparts(SwE.xY.P{1});
    isMat          = strcmpi(file_ext,'.mat');
    while(isMat)
      [SwE,xSwE] = swe_getSPM(xSwE);
    end
    
    if isempty(xSwE) 
        varargout = {[],[],[]};
        return;
    end
    
    switch xSwE.STAT
        case 'T'
            eSTAT = 'Z';
        case 'F'
            eSTAT = 'X';
    end
    %-Ensure pwd = swd so that relative filenames are valid
    %----------------------------------------------------------------------
    cd(SwE.swd)
    
    %-Get space information
    %======================================================================
    M         = SwE.xVol.M;
    DIM       = SwE.xVol.DIM;

    %-Space units
    %----------------------------------------------------------------------
    try
        try
            units = SwE.xVol.units;
        catch
            units = xSwE.units;
        end
    catch
        try
            if strcmp(spm('CheckModality'),'EEG')
                datatype = {...
                    'Volumetric (2D/3D)',...
                    'Scalp-Time',...
                    'Scalp-Frequency',...
                    'Time-Frequency',...
                    'Frequency-Frequency'};
                selected = spm_input('Data Type: ','+1','m',datatype);
                datatype = datatype{selected};
            else
                datatype = 'Volumetric (2D/3D)';
            end
        catch
            datatype     = 'Volumetric (2D/3D)';
        end
        
        switch datatype
            case 'Volumetric (2D/3D)'
                units    = {'mm' 'mm' 'mm'};
            case 'Scalp-Time'
                units    = {'mm' 'mm' 'ms'};
            case 'Scalp-Frequency'
                units    = {'mm' 'mm' 'Hz'};
            case 'Time-Frequency'
                units    = {'Hz' 'ms' ''};
            case 'Frequency-Frequency'
                units    = {'Hz' 'Hz' ''};
            otherwise
                error('Unknown data type.');
        end
    end
    if ~isMat && DIM(3) == 1, units{3} = ''; end
    xSwE.units      = units;
    SwE.xVol.units  = units;
    
     
    %-Setup Results User Interface; Display MIP, design matrix & parameters
    %======================================================================
 
    %-Setup results GUI
    %----------------------------------------------------------------------
    spm_clf(Finter);
    spm('FigName',['SwE{',xSwE.STAT,'}: Results'],Finter,CmdLine);
    hReg      = swe_results_ui('SetupGUI',M,DIM,xSwE,Finter);
 
    %-Setup design interrogation menu
    %----------------------------------------------------------------------
    hDesRepUI = spm_DesRep('DesRepUI',SwE);
    figure(Finter)
 
    %-Setup contrast menu
    %----------------------------------------------------------------------
    hC = uimenu(Finter,'Label','Contrasts', 'Tag','ContrastsUI');
    hC1 = uimenu(hC,'Label','New Contrast...',...
        'UserData',struct('Ic',0),...
        'Callback',{@mychgcon,xSwE});
    hC1 = uimenu(hC,'Label','Change Contrast');
    for i=1:numel(SwE.xCon)
        hC2 = uimenu(hC1,'Label',[SwE.xCon(i).STAT, ': ', SwE.xCon(i).name], ...
            'UserData',struct('Ic',i),...
            'Callback',{@mychgcon,xSwE});
        if any(xSwE.Ic == i)
            set(hC2,'ForegroundColor',[0 0 1],'Checked','on');
        end
    end
    hC1 = uimenu(hC,'Label','Previous Contrast',...
        'Accelerator','P',...
        'UserData',struct('Ic',xSwE.Ic-1),...
        'Callback',{@mychgcon,xSwE});
    if xSwE.Ic-1<1, set(hC1,'Enable','off'); end
    hC1 = uimenu(hC,'Label','Next Contrast',...
        'Accelerator','N',...
        'UserData',struct('Ic',xSwE.Ic+1),...
        'Callback',{@mychgcon,xSwE});
    if xSwE.Ic+1>numel(SwE.xCon), set(hC1,'Enable','off'); end
    hC1 = uimenu(hC,'Label','Significance level','Separator','on');
    xSwEtmp = xSwE; xSwEtmp.thresDesc = '';
    uimenu(hC1,'Label','Change...','UserData',struct('Ic',xSwE.Ic),...
        'Callback',{@mychgcon,xSwEtmp});
%     xSPMtmp = xSwE; xSPMtmp.thresDesc = 'p<0.05 (FWE)';
%     uimenu(hC1,'Label','Set to 0.05 (FWE)','UserData',struct('Ic',xSwE.Ic),...
%         'Callback',{@mychgcon,xSPMtmp});
    xSwEtmp = xSwE; xSwEtmp.thresDesc = 'p<0.001 (unc.)';
    uimenu(hC1,'Label','Set to 0.001 (unc.)','UserData',struct('Ic',xSwE.Ic),...
        'Callback',{@mychgcon,xSwEtmp});
    
    uimenu(hC1,'Label',[xSwE.thresDesc ', k=' num2str(xSwE.k)],...
        'Enable','off','Separator','on');
    
    %-Setup Maximum intensity projection (MIP) & register
    %----------------------------------------------------------------------
    hMIPax = axes('Parent',Fgraph,'Position',[0.05 0.60 0.55 0.36],'Visible','off');
    hMIPax = spm_mip_ui(xSwE.Z,xSwE.XYZmm,M,DIM,hMIPax,units);
 
    spm_XYZreg('XReg',hReg,hMIPax,'spm_mip_ui');
    if xSwE.STAT == 'P'
        str = xSwE.STATstr;
    else
        str = ['SwE\{',xSwE.STATstr,'\}'];
    end
    text(240,260,str,...
        'Interpreter','TeX',...
        'FontSize',FS(14),'Fontweight','Bold',...
        'Parent',hMIPax)
 
 
    %-Print comparison title
    %----------------------------------------------------------------------
    hTitAx = axes('Parent',Fgraph,...
        'Position',[0.02 0.95 0.96 0.02],...
        'Visible','off');
 
    text(0.5,0,xSwE.title,'Parent',hTitAx,...
        'HorizontalAlignment','center',...
        'VerticalAlignment','baseline',...
        'FontWeight','Bold','FontSize',FS(14))
 
 
    %-Print SwEresults: Results directory & thresholding info
    %----------------------------------------------------------------------
    hResAx = axes('Parent',Fgraph,...
        'Position',[0.05 0.55 0.45 0.05],...
        'DefaultTextVerticalAlignment','baseline',...
        'DefaultTextFontSize',FS(9),...
        'DefaultTextColor',[1,1,1]*.7,...
        'Units','points',...
        'Visible','off');
    AxPos = get(hResAx,'Position'); set(hResAx,'YLim',[0,AxPos(4)])
    h     = text(0,24,'SPMresults:','Parent',hResAx,...
        'FontWeight','Bold','FontSize',FS(14));
    text(get(h,'Extent')*[0;0;1;0],24,spm_str_manip(SwE.swd,'a30'),'Parent',hResAx)
    try
        thresDesc = xSwE.thresDesc;
        if ~strcmp(xSwE.thresDesc, 'none') && ~isempty(xSwE.thresDesc)
            text(0,12,sprintf('Height threshold %c = %0.6f  {%s}',eSTAT,xSwE.u,thresDesc),'Parent',hResAx)
        else
            text(0,12,sprintf('Height threshold %c = %0.6f',eSTAT,xSwE.u),'Parent',hResAx)
        end
    catch
        text(0,12,sprintf('Height threshold %c = %0.6f',eSTAT,xSwE.u),'Parent',hResAx)
    end
    if strcmp(xSwE.clustWise, 'FWE') 
        text(0,00,sprintf('Extent threshold k = %0.0f voxels {p<%0.3f (FWE)}',xSwE.k, xSwE.fwep_c), 'Parent',hResAx)
    else
        text(0,00,sprintf('Extent threshold k = %0.0f voxels',xSwE.k), 'Parent',hResAx)
    end
    try
        WB = xSwE.WB;
        if WB
            text(0,-12,sprintf('Wild Bootstrap'), 'Parent',hResAx)
        end
    catch
        error('Missing details about whether this is a wild boostrap or not.')
    end
 
    %-Plot design matrix
    %----------------------------------------------------------------------
    hDesMtx   = axes('Parent',Fgraph,'Position',[0.65 0.55 0.25 0.25]);
    hDesMtxIm = image((SwE.xX.X + 1)*32);
    xlabel('Design matrix')
    set(hDesMtxIm,'ButtonDownFcn','spm_DesRep(''SurfDesMtx_CB'')',...
        'UserData',struct(...
        'X',        SwE.xX.X,...
        'fnames',   {reshape({SwE.xY.VY.fname},size(SwE.xY.VY))},...
        'Xnames',   {SwE.xX.name}))
 
    %-Plot contrasts
    %----------------------------------------------------------------------
    nPar   = size(SwE.xX.X,2);
    xx     = [repmat([0:nPar-1],2,1);repmat([1:nPar],2,1)];
    nCon   = length(xSwE.Ic);
    xCon   = SwE.xCon;
    if nCon
        dy     = 0.15/max(nCon,2);
        hConAx = axes('Position',[0.65 (0.80 + dy*.1) 0.25 dy*(nCon-.1)],...
            'Tag','ConGrphAx','Visible','off');
        title('contrast(s)')
        htxt   = get(hConAx,'title');
        set(htxt,'Visible','on','HandleVisibility','on')
    end
 
    for ii = nCon:-1:1
        axes('Position',[0.65 (0.80 + dy*(nCon - ii +.1)) 0.25 dy*.9])
        if xCon(xSwE.Ic(ii)).STAT == 'T' && size(xCon(xSwE.Ic(ii)).c,2) == 1
 
            %-Single vector contrast for SwE{t} - bar
            %--------------------------------------------------------------
            yy = [zeros(1,nPar);repmat(xCon(xSwE.Ic(ii)).c',2,1);zeros(1,nPar)];
            h  = patch(xx,yy,[1,1,1]*.5);
            set(gca,'Tag','ConGrphAx',...
                'Box','off','TickDir','out',...
                'XTick',spm_DesRep('ScanTick',nPar,10) - 0.5,'XTickLabel','',...
                'XLim', [0,nPar],...
                'YTick',[-1,0,+1],'YTickLabel','',...
                'YLim',[min(xCon(xSwE.Ic(ii)).c),max(xCon(xSwE.Ic(ii)).c)] +...
                [-1 +1] * max(abs(xCon(xSwE.Ic(ii)).c))/10  )
 
        else
 
            %-F-contrast - image
            %--------------------------------------------------------------
            h = image((xCon(xSwE.Ic(ii)).c'/max(abs(xCon(xSwE.Ic(ii)).c(:)))+1)*32);
            set(gca,'Tag','ConGrphAx',...
                'Box','on','TickDir','out',...
                'XTick',spm_DesRep('ScanTick',nPar,10),'XTickLabel','',...
                'XLim', [0,nPar]+0.5,...
                'YTick',[0:size(SwE.xCon(xSwE.Ic(ii)).c,2)]+0.5,....
                'YTickLabel','',...
                'YLim', [0,size(xCon(xSwE.Ic(ii)).c,2)]+0.5 )
 
        end
        ylabel(num2str(xSwE.Ic(ii)))
        set(h,'ButtonDownFcn','spm_DesRep(''SurfCon_CB'')',...
            'UserData', struct( 'i',        xSwE.Ic(ii),...
            'h',        htxt,...
            'xCon',     xCon(xSwE.Ic(ii))))
    end
 
 
    %-Store handles of results section Graphics window objects
    %----------------------------------------------------------------------
    H  = get(Fgraph,'Children');
    H  = findobj(H,'flat','HandleVisibility','on');
    H  = findobj(H);
    Hv = get(H,'Visible');
    set(hResAx,'Tag','PermRes','UserData',struct('H',H,'Hv',{Hv}))
    
    %-Load whole brain table.
    %------------------------------------------------------------------
    swe_list('List',xSwE,hReg);
    
    %-Finished results setup
    %----------------------------------------------------------------------
    varargout = {hReg,xSwE,SwE};
    assignin ('base','hReg',hReg)
    assignin ('base','xSwE',xSwE)
    assignin ('base','SwE',SwE)
    spm('Pointer','Arrow')
 
 
    %======================================================================
    case 'setupgui'                            %-Set up results section GUI
    %======================================================================
        % hReg = swe_results_ui('SetupGUI',M,DIM,xSwE,Finter)
        if nargin < 5, Finter='Interactive'; else Finter = varargin{5}; end
        if nargin < 4, error('Insufficient arguments'), end
        M      = varargin{2};
        DIM    = varargin{3};
        xSwE   = varargin{4};
        Finter = spm_figure('GetWin',Finter);
        WS     = spm('WinScale');
        FS     = spm('FontSizes');
 
        %-Create frame for Results GUI objects
        %------------------------------------------------------------------
        hReg    = uicontrol(Finter,'Style','Frame','Position',[001 001 400 190].*WS,...
                           'BackgroundColor',spm('Colour'));
        hFResUi = uicontrol(Finter,...
                     'Style','Pushbutton',...
                     'enable','off',...
                     'Position',[008 007 387 178].*WS);
 
        %-Initialise registry in hReg frame object
        %------------------------------------------------------------------
        [hReg,xyz] = spm_XYZreg('InitReg',hReg,M,DIM,[0;0;0]);
 
        %-Setup editable XYZ widgets & cross register with registry
        %------------------------------------------------------------------
        hFxyz      = swe_results_ui('DrawXYZgui',M,DIM,varargin{4},xyz,Finter);
        spm_XYZreg('XReg',hReg,hFxyz,'swe_results_ui');
 
        %-Set up buttons for results functions
        %------------------------------------------------------------------
        swe_results_ui('DrawButts',hReg,DIM,Finter,WS,FS);
 
        varargout  = {hReg};
 
 
 
    %======================================================================
    case 'drawbutts'   %-Draw results section buttons in Interactive window
    %======================================================================
        % swe_results_ui('DrawButts',hReg,DIM,Finter,WS,FS)
        %
        if nargin<3, error('Insufficient arguments'), end
        hReg = varargin{2};
        DIM  = varargin{3};
        if nargin<4,  Finter = spm_figure('FindWin','Interactive');
        else Finter = varargin{4}; end
        if nargin < 5, WS = spm('WinScale');  else  WS = varargin{5}; end
        if nargin < 6, FS = spm('FontSizes'); else  FS = varargin{6}; end
 
        %-p-values
        %------------------------------------------------------------------
        uicontrol(Finter,'Style','Text','String','p-values',...
            'Position',[020 168 080 015].*WS,...
            'FontAngle','Italic',...
            'FontSize',FS(10),...
            'HorizontalAlignment','Left',...
            'ForegroundColor','w')
        uicontrol(Finter,'Style','PushButton','String','whole brain','FontSize',FS(10),...
            'ToolTipString',...
            'tabulate summary of local maxima, p-values & statistics',...
            'Callback','swe_list(''List'',xSwE,hReg);',...
            'Interruptible','on','Enable','on',...
            'Position',[015 145 100 020].*WS)
        uicontrol(Finter,'Style','PushButton','String','current cluster','FontSize',FS(10),...
            'ToolTipString',...
            'tabulate p-values & statistics for local maxima of nearest cluster',...
            'Callback','swe_list(''ListCluster'',xSwE,hReg);',...
            'Interruptible','on','Enable','on',...
            'Position',[015 120 100 020].*WS)
        uicontrol(Finter,'Style','PushButton','String','small volume','FontSize',FS(10),...
            'ToolTipString',['Small Volume Correction - corrected p-values ',...
            'for a small search region'],...
            'Callback','swe_VOI(SwE,xSwE,hReg);',...
            'Interruptible','on','Enable','on',...
            'Position',[015 095 100 020].*WS)
 
 
        %-SwE area - used for Volume of Interest analyses
        %------------------------------------------------------------------
        uicontrol(Finter,'Style','Text','String','Multivariate',...
            'Position',[135 168 80 015].*WS,...
            'FontAngle','Italic',...
            'FontSize',FS(10),...
            'HorizontalAlignment','Left',...
            'ForegroundColor','w')
        uicontrol(Finter,'Style','PushButton','String','eigenvariate',...
            'Position',[130 145 70 020].*WS,...
            'ToolTipString',...
            'Responses (principal eigenvariate) in volume of interest',...
            'Callback','[Y,xY] = spm_regions(xSwE,SwE,hReg)',...
            'Interruptible','on','Enable','on',...
            'FontSize',FS(10),'ForegroundColor',[1 1 1]/3)
        uicontrol(Finter,'Style','PushButton','String','CVA',...
            'Position',[205 145 65 020].*WS,...
            'ToolTipString',...
            'Canonical variates analysis for the current contrast and VOI',...
            'Callback','CVA = spm_cva(xSwE,SwE,hReg)',...
            'Interruptible','on','Enable','on',...
            'FontSize',FS(10),'ForegroundColor',[1 1 1]/3)
        uicontrol(Finter,'Style','PushButton','String','multivariate Bayes',...
            'Position',[130 120 140 020].*WS,...
            'ToolTipString',...
            'Multivariate Bayes',...
            'Callback','[MVB] = spm_mvb_ui(xSwE,SwE,hReg)',...
            'Interruptible','on','Enable','on',...
            'FontSize',FS(10),'ForegroundColor',[1 1 1]/3)
        uicontrol(Finter,'Style','PushButton','String','BMS',...
            'Position',[130 95 68 020].*WS,...
            'ToolTipString',...
            'Compare or review a multivariate Bayesian model',...
            'Callback','[F,P]  = spm_mvb_bmc',...
            'Interruptible','on','Enable','on',...
            'FontSize',FS(8),'ForegroundColor',[1 1 1]/3)
        uicontrol(Finter,'Style','PushButton','String','p-value',...
            'Position',[202 95 68 020].*WS,...
            'ToolTipString',...
            'Randomisation testing of a multivariate Bayesian model',...
            'Callback','spm_mvb_p',...
            'Interruptible','on','Enable','on',...
            'FontSize',FS(8),'ForegroundColor',[1 1 1]/3)
 
        %-Hemodynamic modelling
        %------------------------------------------------------------------
        if strcmp(spm('CheckModality'),'FMRI')
            uicontrol(Finter,'Style','PushButton','String','Hemodynamics',...
                'FontSize',FS(10),...
                'ToolTipString','Hemodynamic modelling of regional response',...
                'Callback','[Ep,Cp,K1,K2] = spm_hdm_ui(xSwE,SwE,hReg);',...
                'Interruptible','on','Enable','on',...
                'Position',[130 055 140 020].*WS,...
                'ForegroundColor',[1 1 1]/3);
        end
 
        %-Not currently used
        %------------------------------------------------------------------
        %uicontrol(Finter,'Style','PushButton','String','','FontSize',FS(10),...
        %     'ToolTipString','',...
        %     'Callback','',...
        %     'Interruptible','on','Enable','on',...
        %     'Position',[015 055 100 020].*WS)

        %-Visualisation
        %------------------------------------------------------------------
        uicontrol(Finter,'Style','Text','String','Display',...
            'Position',[290 168 065 015].*WS,...
            'FontAngle','Italic',...
            'FontSize',FS(10),...
            'HorizontalAlignment','Left',...
            'ForegroundColor','w')
        uicontrol(Finter,'Style','PushButton','String','plot','FontSize',FS(10),...
            'ToolTipString','plot data & contrasts at current voxel',...
            'Callback','[Y,y,beta,Bcov] = swe_graph(xSwE,SwE,hReg);',...
            'Interruptible','on','Enable','on',...
            'Position',[285 145 100 020].*WS,...
            'Tag','plotButton')
 
        str  = { 'overlays...','slices','sections','render','previous sections','previous render'};
        tstr = { 'overlay filtered SwE on another image: ',...
            '3 slices / ','ortho sections / ','render /','previous ortho sections /','previous surface rendering'};
 
        tmp  = { 'spm_transverse(''set'',xSwE,hReg)',...
            'spm_sections(xSwE,hReg)',...
            ['spm_render(   struct( ''XYZ'',    xSwE.XYZ,',...
            '''t'',     xSwE.Z'',',...
            '''mat'',   xSwE.M,',...
            '''dim'',   xSwE.DIM))'],...
            ['global prevsect;','spm_sections(xSwE,hReg,prevsect)'],...
            ['global prevrend;','if ~isstruct(prevrend)',...
            'prevrend = struct(''rendfile'','''',''brt'',[],''col'',[]); end;',...            
            'spm_render(    struct( ''XYZ'',    xSwE.XYZ,',...
            '''t'',     xSwE.Z'',',...
            '''mat'',   xSwE.M,',...
            '''dim'',   xSwE.DIM),prevrend.brt,prevrend.rendfile)']};
 
        uicontrol(Finter,'Style','PopUp','String',str,'FontSize',FS(10),...
            'ToolTipString',cat(2,tstr{:}),...
            'Callback','spm(''PopUpCB'',gcbo)',...
            'UserData',tmp,...
            'Interruptible','on','Enable','on',...
            'Position',[285 120 100 020].*WS)
 
        uicontrol(Finter,'Style','PushButton','String','save','FontSize',FS(10),...
            'ToolTipString','save thresholded SwE as image',...
            'Callback',['spm_write_filtered(xSwE.Z,xSwE.XYZ,xSwE.DIM,xSwE.M,',...
              'sprintf(''SwE{%c}-filtered: u = %5.3f, k = %d'',',...
              'xSwE.STAT,xSwE.u,xSwE.k));'],...
            'Interruptible','on','Enable','on',...
            'Position',[285 095 100 020].*WS)
 
        %-ResultsUI controls
        %------------------------------------------------------------------
        hClear = uicontrol(Finter,'Style','PushButton','String','clear',...
            'ToolTipString','clears results subpane',...
            'FontSize',FS(9),'ForegroundColor','b',...
            'Callback',['swe_results_ui(''Clear''); ',...
              'spm_input(''!DeleteInputObj''),',...
              'spm_clf(''Satellite'')'],...
            'Interruptible','on','Enable','on',...
            'DeleteFcn','spm_clf(''Graphics'')',...
            'Position',[285 055 035 018].*WS);
 
        hExit  = uicontrol(Finter,'Style','PushButton','String','exit',...
            'ToolTipString','exit the results section',...
            'FontSize',FS(9),'ForegroundColor','r',...
            'Callback',['spm_clf(''Interactive''), spm_clf(''Graphics''),'...
              'close(spm_figure(''FindWin'',''Satellite'')),'...
              'clear'],...
            'Interruptible','on','Enable','on',...
            'Position',[325 055 035 018].*WS);
 
        hHelp  = uicontrol(Finter,'Style','PushButton','String','?',...
            'ToolTipString','results section help',...
            'FontSize',FS(9),'ForegroundColor','g',...
            'Callback','spm_help(''swe_results_ui'')',...
            'Interruptible','on','Enable','on',...
            'Position',[365 055 020 018].*WS);
 
 
    %======================================================================
    case 'drawxyzgui'                                   %-Draw XYZ GUI area
    %======================================================================
        % hFxyz = swe_results_ui('DrawXYZgui',M,DIM,xSwE,xyz,Finter)
        if nargin<6,  Finter=spm_figure('FindWin','Interactive');
        else Finter=varargin{6}; end
        if nargin < 5, xyz=[0;0;0]; else xyz=varargin{5}; end
        if nargin < 4, error('Insufficient arguments'), end
        DIM     = varargin{3};
        M       = varargin{2};
        xyz     = spm_XYZreg('RoundCoords',xyz,M,DIM);
 
        %-Font details
        %------------------------------------------------------------------
        WS      = spm('WinScale');
        FS      = spm('FontSizes');
        PF      = spm_platform('fonts');
 
        %-Create XYZ control objects
        %------------------------------------------------------------------
        hFxyz = uicontrol(Finter,'Style','Pushbutton',...
            'visible','off','enable','off','Position',[010 010 265 030].*WS);
        uicontrol(Finter,'Style','Text','String','co-ordinates',...
            'Position',[020 035 090 016].*WS,...
            'FontAngle','Italic',...
            'FontSize',FS(10),...
            'HorizontalAlignment','Left',...
            'ForegroundColor','w')
 
        uicontrol(Finter,'Style','Text','String','x =',...
            'Position',[020 015 024 018].*WS,...
            'FontName',PF.times,'FontSize',FS(10),'FontAngle','Italic',...
            'HorizontalAlignment','Center');
        hX   = uicontrol(Finter,'Style','Edit','String',sprintf('%.2f',xyz(1)),...
            'ToolTipString','enter x-coordinate',...
            'Position',[044 015 056 020].*WS,...
            'FontSize',FS(10),'BackGroundColor',[.8,.8,1],...
            'HorizontalAlignment','Right',...
            'Tag','hX',...
            'Callback','swe_results_ui(''EdWidCB'')');
 
        uicontrol(Finter,'Style','Text','String','y =',...
            'Position',[105 015 024 018].*WS,...
            'FontName',PF.times,'FontSize',FS(10),'FontAngle','Italic',...
            'HorizontalAlignment','Center')
        hY   = uicontrol(Finter,'Style','Edit','String',sprintf('%.2f',xyz(2)),...
            'ToolTipString','enter y-coordinate',...
            'Position',[129 015 056 020].*WS,...
            'FontSize',FS(10),'BackGroundColor',[.8,.8,1],...
            'HorizontalAlignment','Right',...
            'Tag','hY',...
            'Callback','swe_results_ui(''EdWidCB'')');
 
        if DIM(3) ~= 1
        uicontrol(Finter,'Style','Text','String','z =',...
            'Position',[190 015 024 018].*WS,...
            'FontName',PF.times,'FontSize',FS(10),'FontAngle','Italic',...
            'HorizontalAlignment','Center')
        hZ   = uicontrol(Finter,'Style','Edit','String',sprintf('%.2f',xyz(3)),...
            'ToolTipString','enter z-coordinate',...
            'Position',[214 015 056 020].*WS,...
            'FontSize',FS(10),'BackGroundColor',[.8,.8,1],...
            'HorizontalAlignment','Right',...
            'Tag','hZ',...
            'Callback','swe_results_ui(''EdWidCB'')');
        else
        hZ = [];
        end
        
        %-Statistic value reporting pane
        %------------------------------------------------------------------
        uicontrol(Finter,'Style','Text','String','statistic',...
            'Position',[285 035 090 016].*WS,...
            'FontAngle','Italic',...
            'FontSize',FS(10),...
            'HorizontalAlignment','Left',...
            'ForegroundColor','w')
        hSPM = uicontrol(Finter,'Style','Text','String','',...
            'Position',[285 012 100 020].*WS,...
            'FontSize',FS(10),...
            'HorizontalAlignment','Center');
 
 
        %-Store data
        %------------------------------------------------------------------
        set(hFxyz,'Tag','hFxyz','UserData',struct(...
            'hReg', [],...
            'M',    M,...
            'DIM',  DIM,...
            'XYZ',  varargin{4}.XYZmm,...
            'Z',    varargin{4}.Z,...
            'hX',   hX,...
            'hY',   hY,...
            'hZ',   hZ,...
            'hSPM', hSPM,...
            'xyz',  xyz ));
 
        set([hX,hY,hZ],'UserData',hFxyz)
        varargout = {hFxyz};
 
 
    %======================================================================
    case 'edwidcb'                          %-Callback for editable widgets
    %======================================================================
        % swe_results_ui('EdWidCB')
 
        hC    = gcbo;
        d     = find(strcmp(get(hC,'Tag'),{'hX','hY','hZ'}));
        hFxyz = get(hC,'UserData');
        UD    = get(hFxyz,'UserData');
        xyz   = UD.xyz;
        nxyz  = xyz;
 
        o = evalin('base',['[',get(hC,'String'),']'],'sprintf(''error'')');
        if ischar(o) || length(o)>1
            warning(sprintf('%s: Error evaluating ordinate:\n\t%s',...
                mfilename,lasterr))
        else
            nxyz(d) = o;
            nxyz = spm_XYZreg('RoundCoords',nxyz,UD.M,UD.DIM);
        end
 
        if abs(xyz(d)-nxyz(d))>0
            UD.xyz = nxyz; set(hFxyz,'UserData',UD)
            if ~isempty(UD.hReg), spm_XYZreg('SetCoords',nxyz,UD.hReg,hFxyz); end
            set(hC,'String',sprintf('%.3f',nxyz(d)))
            swe_results_ui('UpdateSPMval',UD)
        end
 
        
    %======================================================================
    case 'updatespmval'                           %-Update SwE value in GUI
    %======================================================================
        % swe_results_ui('UpdateSPMval',hFxyz)
        % swe_results_ui('UpdateSPMval',UD)
        if nargin<2, error('insufficient arguments'), end
        if isstruct(varargin{2}), UD=varargin{2}; else UD = get(varargin{2},'UserData'); end
        i  = spm_XYZreg('FindXYZ',UD.xyz,UD.XYZ);
        if isempty(i), str = ''; else str = sprintf('%6.2f',UD.Z(i)); end
        set(UD.hSPM,'String',str);
 
 
    %======================================================================
    case 'getcoords'             % Get current co-ordinates from XYZ widget
    %======================================================================
        % xyz = swe_results_ui('GetCoords',hFxyz)
        if nargin<2, hFxyz='Interactive'; else hFxyz=varargin{2}; end
        hFxyz     = swe_results_ui('FindXYZframe',hFxyz);
        varargout = {getfield(get(hFxyz,'UserData'),'xyz')};
 
 
    %======================================================================
    case 'setcoords'                       % Set co-ordinates to XYZ widget
    %======================================================================
        % [xyz,d] = swe_results_ui('SetCoords',xyz,hFxyz,hC)
        if nargin<4, hC=0; else hC=varargin{4}; end
        if nargin<3, hFxyz=swe_results_ui('FindXYZframe'); else hFxyz=varargin{3}; end
        if nargin<2, error('Set co-ords to what!'); else xyz=varargin{2}; end
 
        %-If this is an internal call, then don't do anything
        if hFxyz==hC, return, end
 
        UD = get(hFxyz,'UserData');
 
        %-Check validity of coords only when called without a caller handle
        %------------------------------------------------------------------
        if hC <= 0
            [xyz,d] = spm_XYZreg('RoundCoords',xyz,UD.M,UD.DIM);
            if d>0 && nargout<2, warning(sprintf(...
                '%s: Co-ords rounded to nearest voxel centre: Discrepancy %.2f',...
                mfilename,d))
            end
        else
            d = [];
        end
 
        %-Update xyz information & widget strings
        %------------------------------------------------------------------
        UD.xyz = xyz; set(hFxyz,'UserData',UD)
        set(UD.hX,'String',sprintf('%.2f',xyz(1)))
        set(UD.hY,'String',sprintf('%.2f',xyz(2)))
        set(UD.hZ,'String',sprintf('%.2f',xyz(3)))
        swe_results_ui('UpdateSPMval',UD)
 
        %-Tell the registry, if we've not been called by the registry...
        %------------------------------------------------------------------
        if (~isempty(UD.hReg) && UD.hReg~=hC)
            spm_XYZreg('SetCoords',xyz,UD.hReg,hFxyz);
        end
 
        %-Return arguments
        %------------------------------------------------------------------
        varargout = {xyz,d};
 

    %======================================================================
    case 'findxyzframe'                                  % Find hFxyz frame
    %======================================================================
        % hFxyz = swe_results_ui('FindXYZframe',h)
        % Sorts out hFxyz handles
        if nargin<2, h='Interactive'; else, h=varargin{2}; end
        if ischar(h), h=spm_figure('FindWin',h); end
        if ~ishandle(h), error('invalid handle'), end
        if ~strcmp(get(h,'Tag'),'hFxyz'), h=findobj(h,'Tag','hFxyz'); end
        if isempty(h), error('XYZ frame not found'), end
        if length(h)>1, error('Multiple XYZ frames found'), end
        varargout = {h};


    %======================================================================
    case 'plotui'                               %-GUI for plot manipulation
    %======================================================================
        % swe_results_ui('PlotUi',hAx)
        if nargin<2, hAx=gca; else hAx=varargin{2}; end
 
        WS = spm('WinScale');
        FS = spm('FontSizes');
        Finter=spm_figure('FindWin','Interactive');
        figure(Finter)
 
        %-Check there aren't already controls!
        %------------------------------------------------------------------
        hGraphUI = findobj(Finter,'Tag','hGraphUI');
        if ~isempty(hGraphUI)           %-Controls exist
            hBs = get(hGraphUI,'UserData');
            if hAx==get(hBs(1),'UserData')  %-Controls linked to these axes
                return
            else                %-Old controls remain
                delete(findobj(Finter,'Tag','hGraphUIbg'))
            end
        end
 
        %-Frames & text
        %------------------------------------------------------------------
        hGraphUIbg = uicontrol(Finter,'Style','Frame','Tag','hGraphUIbg',...
            'BackgroundColor',spm('Colour'),...
            'Position',[001 196 400 055].*WS);
        hGraphUI   = uicontrol(Finter,'Style','Frame','Tag','hGraphUI',...
            'Position',[008 202 387 043].*WS);
        hGraphUIButtsF = uicontrol(Finter,'Style','Frame',...
            'Position',[010 205 380 030].*WS);
        hText = uicontrol(Finter,'Style','Text','String','plot controls',...
            'Position',[020 227 080 016].*WS,...
            'FontWeight','Normal',...
            'FontAngle','Italic','FontSize',FS(10),...
            'HorizontalAlignment','Left',...
            'ForegroundColor','w');
 
        %-Controls
        %------------------------------------------------------------------
        h1 = uicontrol(Finter,'Style','CheckBox','String','hold',...
            'ToolTipString','toggle hold to overlay plots',...
            'FontSize',FS(10),...
            'Value',strcmp(get(hAx,'NextPlot'),'add'),...
            'Callback',[...
            'if get(gcbo,''Value''), ',...
            'set(get(gcbo,''UserData''),''NextPlot'',''add''), ',...
            'else, ',...
            'set(get(gcbo,''UserData''),''NextPlot'',''replace''), ',...
            'end'],...
            'Interruptible','on','Enable','on',...
            'Tag','holdButton',...
            'Position',[015 210 070 020].*WS);
        set(findobj('Tag','plotButton'),'UserData',h1);
 
        h2 = uicontrol(Finter,'Style','CheckBox','String','grid',...
            'ToolTipString','toggle axes grid',...
            'FontSize',FS(10),...
            'Value',strcmp(get(hAx,'XGrid'),'on'),...
            'Callback',[...
            'if get(gcbo,''Value''), ',...
            'set(get(gcbo,''UserData''),''XGrid'',''on'','...
            '''YGrid'',''on'',''ZGrid'',''on''), ',...
            'else, ',...
            'set(get(gcbo,''UserData''),''XGrid'',''off'','...
            '''YGrid'',''off'',''ZGrid'',''off''), ',...
            'end'],...
            'Interruptible','on','Enable','on',...
            'Position',[090 210 070 020].*WS);
        h3 = uicontrol(Finter,'Style','CheckBox','String','Box',...
            'ToolTipString','toggle axes box',...
            'FontSize',FS(10),...
            'Value',strcmp(get(hAx,'Box'),'on'),...
            'Callback',[...
            'if get(gcbo,''Value''), ',...
            'set(get(gcbo,''UserData''),''Box'',''on''), ',...
            'else, ',...
            'set(get(gcbo,''UserData''),''Box'',''off''), ',...
            'end'],...
            'Interruptible','on','Enable','on',...
            'Position',[165 210 070 020].*WS);
        h4 = uicontrol(Finter,'Style','PopUp',...
            'ToolTipString','edit axis text annotations',...
            'FontSize',FS(10),...
            'String','text|Title|Xlabel|Ylabel',...
            'Callback','swe_results_ui(''PlotUiCB'')',...
            'Interruptible','on','Enable','on',...
            'Position',[240 210 070 020].*WS);
        h5 = uicontrol(Finter,'Style','PopUp',...
            'ToolTipString','change various axes attributes',...
            'FontSize',FS(10),...
            'String','attrib|LineWidth|XLim|YLim|handle',...
            'Callback','swe_results_ui(''PlotUiCB'')',...
            'Interruptible','off','Enable','on',...
            'Position',[315 210 070 020].*WS);
 
        %-Handle storage for linking, and DeleteFcns for linked deletion
        %------------------------------------------------------------------
        set(hGraphUI,'UserData',[h1,h2,h3,h4,h5])
        set([h1,h2,h3,h4,h5],'UserData',hAx)
 
        set(hGraphUIbg,'UserData',...
            [hGraphUI,hGraphUIButtsF,hText,h1,h2,h3,h4,h5],...
            'DeleteFcn','swe_results_ui(''Delete'',get(gcbo,''UserData''))')
        set(hAx,'UserData',hGraphUIbg,...
            'DeleteFcn','swe_results_ui(''Delete'',get(gcbo,''UserData''))')


    %======================================================================
    case 'plotuicb'
    %======================================================================
        % swe_results_ui('PlotUiCB')
        hPM = gcbo;
        v   = get(hPM,'Value');
        if v==1, return, end
        str = cellstr(get(hPM,'String'));
        str = str{v};
 
        hAx = get(hPM,'UserData');
        switch str
            case 'Title'
                h = get(hAx,'Title');
                set(h,'String',spm_input('Enter title:',-1,'s+',get(h,'String')))
            case 'Xlabel'
                h = get(hAx,'Xlabel');
                set(h,'String',spm_input('Enter X axis label:',-1,'s+',get(h,'String')))
            case 'Ylabel'
                h = get(hAx,'Ylabel');
                set(h,'String',spm_input('Enter Y axis label:',-1,'s+',get(h,'String')))
            case 'LineWidth'
                lw = spm_input('Enter LineWidth',-1,'e',get(hAx,'LineWidth'),1);
                set(hAx,'LineWidth',lw)
            case 'XLim'
                XLim = spm_input('Enter XLim',-1,'e',get(hAx,'XLim'),[1,2]);
                set(hAx,'XLim',XLim)
            case 'YLim'
                YLim = spm_input('Enter YLim',-1,'e',get(hAx,'YLim'),[1,2]);
                set(hAx,'YLim',YLim)
            case 'handle'
                varargout={hAx};
            otherwise
                warning(['Unknown action: ',str])
        end
 
        set(hPM,'Value',1)
 
 
    %======================================================================
    case 'clear'                                    %-Clear results subpane
    %======================================================================
        % Fgraph = swe_results_ui('Clear',F,mode)
        % mode 1 [default] usual, mode 0 - clear & hide Res stuff, 2 - RNP
 
        if nargin<3, mode=1; else, mode=varargin{3}; end
        if nargin<2, F='Graphics'; else, F=varargin{2}; end
        F = spm_figure('FindWin',F);
 
        %-Clear input objects from 'Interactive' window
        %------------------------------------------------------------------
        %spm_input('!DeleteInputObj')
 
 
        %-Get handles of objects in Graphics window & note permanent results objects
        %------------------------------------------------------------------
        H = get(F,'Children');                          %-Get contents of window
        H = findobj(H,'flat','HandleVisibility','on');  %-Drop GUI components
        h = findobj(H,'flat','Tag','PermRes');          %-Look for 'PermRes' object
 
        if ~isempty(h)
            %-Found 'PermRes' object
            % This has handles of permanent results objects in it's UserData
            tmp  = get(h,'UserData');
            HR   = tmp.H;
            HRv  = tmp.Hv;
        else
            %-No trace of permanent results objects
            HR   = [];
            HRv  = {};
        end
        H = setdiff(H,HR);              %-Drop permanent results obj
 
 
        %-Delete stuff as appropriate
        %------------------------------------------------------------------
        if mode==2  %-Don't delete axes with NextPlot 'add'
            H = setdiff(H,findobj(H,'flat','Type','axes','NextPlot','add'));
        end
 
        delete(H)
 
        if mode==0  %-Hide the permanent results section stuff
            set(HR,'Visible','off')
        else
            set(HR,{'Visible'},HRv)
        end
 
 
    %======================================================================
    case 'launchmp'                            %-Launch multiplanar toolbox
    %======================================================================
        % hMP = swe_results_ui('LaunchMP',M,DIM,hReg,hBmp)
        if nargin<5, hBmp = gcbo; else hBmp = varargin{5}; end
        hReg = varargin{4};
        DIM  = varargin{3};
        M    = varargin{2};
 
        %-Check for existing MultiPlanar toolbox
        hMP  = get(hBmp,'UserData');
        if ishandle(hMP)
            figure(ancestor(hMP,'figure'));
            varargout = {hMP};
            return
        end
 
        %-Initialise and cross-register MultiPlanar toolbox
        hMP = spm_XYZreg_Ex2('Create',M,DIM);
        spm_XYZreg('Xreg',hReg,hMP,'spm_XYZreg_Ex2');
 
        %-Setup automatic deletion of MultiPlanar on deletion of results controls
        set(hBmp,'Enable','on','UserData',hMP)
        set(hBmp,'DeleteFcn','swe_results_ui(''delete'',get(gcbo,''UserData''))')
 
        varargout = {hMP};
 
 
    %======================================================================
    case 'delete'                           %-Delete HandleGraphics objects
    %======================================================================
        % swe_results_ui('Delete',h)
        h = varargin{2};
        delete(h(ishandle(h)));
 
 
    %======================================================================
    otherwise
    %======================================================================
        error('Unknown action string')
 
end

%==========================================================================
function mychgcon(obj,evt,xSwE)
%==========================================================================
xSwE2.swd   = xSwE.swd;
try, xSwE2.units = xSwE.units; end
xSwE2.Ic    = getfield(get(obj,'UserData'),'Ic');
if isempty(xSwE2.Ic) || all(xSwE2.Ic == 0), xSwE2 = rmfield(xSwE2,'Ic'); end
xSwE2.Im    = xSwE.Im;
xSwE2.pm    = xSwE.pm;
xSwE2.Ex    = xSwE.Ex;
xSwE2.title = '';
if ~isempty(xSwE.thresDesc)
    td = regexp(xSwE.thresDesc,'p\D?(?<u>[\.\d]+) \((?<thresDesc>\S+)\)','names');
    if isempty(td)
        td = regexp(xSwE.thresDesc,'\w=(?<u>[\.\d]+)','names');
        td.thresDesc = 'none';
    end
    if strcmp(td.thresDesc,'unc.'), td.thresDesc = 'none'; end
    xSwE2.thresDesc = td.thresDesc;
    xSwE2.u     = str2double(td.u);
    xSwE2.k     = xSwE.k;
end
hReg = spm_XYZreg('FindReg',spm_figure('GetWin','Interactive'));
xyz  = spm_XYZreg('GetCoords',hReg);
[hReg,xSwE,SwE] = swe_results_ui('setup',xSwE2);
spm_XYZreg('SetCoords',xyz,hReg);
assignin('base','hReg',hReg);
assignin('base','xSwE',xSwE);
assignin('base','SwE',SwE);
figure(spm_figure('GetWin','Interactive'));
