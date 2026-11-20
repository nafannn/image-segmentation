classdef SegmentationApp < matlab.apps.AppBase
    %SEGMENTATIONAPP IF4073 Tugas 3 -- Segmentasi Citra. Satu GUI, tiga tab:
    %     Tab 1 - Edge Detection   (B: Laplace, LoG, Sobel, Prewitt, Roberts, Canny
    %                               + segmentasi objek berbasis tepi)
    %     Tab 2 - Split & Merge    (C: quadtree split + region merge)
    %     Tab 3 - Semantic (CNN)   (D: panggil segmentSemantic(img) di src/d-semantic)

    properties (Access = public)
        UIFigure
        TabGroup
        EdgeTab
        SMTab
        SemTab

        % ---- Tab 1: Deteksi Tepi ----
        E_DatasetDropDown
        E_BrowseButton
        E_ImageInfoLabel
        E_MethodDropDown
        E_ParamGrid
        E_ThrModeDropDown
        E_ThrValueField
        E_ThrHintLabel
        E_SegGrid
        E_RunButton
        E_ResetButton
        E_ExportButton
        E_Axes              % 1x6: asli, respons, tepi, mask, segmentasi, overlay
        E_StatusLabel

        % ---- Tab 2: Split & Merge ----
        S_DatasetDropDown
        S_BrowseButton
        S_ImageInfoLabel
        S_PredicateDropDown
        S_ParamGrid
        S_StatsLabel
        S_RunButton
        S_ResetButton
        S_ExportButton
        S_Axes              % 1x6: asli, grid split, mean split, mean merge, label, batas
        S_StatusLabel

        % ---- Tab 3: Semantik (CNN) ----
        D_DatasetDropDown
        D_BrowseButton
        D_ImageInfoLabel
        D_LegendGrid
        D_RunButton
        D_ResetButton
        D_ExportButton
        D_Axes              % 1x3: masukan, label, overlay
        D_StatusLabel
    end

    properties (Access = private)
        EdgeRegistry
        EdgeSegSpecs
        SMRegistry
        E_ParamControls     % containers.Map: nama param -> uieditfield
        E_SegControls
        S_ParamControls

        E_Image = []
        S_Image = []
        D_Image = []
    end

    % ---------------------------------------------------------------------
    %  Tema tampilan (gelap, satu warna aksen). Ubah warna hanya di sini.
    % ---------------------------------------------------------------------
    properties (Constant, Access = private)
        Font      = 'Segoe UI'
        ColBg     = [0.075 0.082 0.106]   % latar jendela
        ColPanel  = [0.114 0.125 0.161]   % sidebar / header
        ColCard   = [0.141 0.153 0.196]   % card citra
        ColInput  = [0.090 0.098 0.129]   % edit field / dropdown
        ColText   = [0.925 0.933 0.953]
        ColMuted  = [0.580 0.616 0.698]
        ColAccent = [0.427 0.506 0.980]   % indigo
        ColAccent2= [0.196 0.776 0.659]   % teal (berhasil)
        ColWarn   = [0.976 0.733 0.278]
        ColError  = [0.957 0.400 0.427]
        DatasetPlaceholder = '-- pilih citra --'
    end

    % =====================================================================
    %  Builder kecil yang dipakai ulang + helper pengaturan gaya
    % =====================================================================
    methods (Access = private)

        function c = styleText(app, c, size, weight, color)
            c.FontName = app.Font;
            c.FontSize = size;
            c.FontWeight = weight;
            c.FontColor = color;
        end

        function b = makeButton(app, parent, text, kind)
            b = uibutton(parent, 'push');
            b.Text = text;
            b.FontName = app.Font;
            b.FontSize = 12;
            switch kind
                case 'primary'
                    b.BackgroundColor = app.ColAccent;
                    b.FontColor = [1 1 1];
                    b.FontWeight = 'bold';
                    b.FontSize = 13;
                otherwise   % selain primary: gaya secondary
                    b.BackgroundColor = app.ColCard;
                    b.FontColor = app.ColText;
            end
        end

        function dd = makeDropDown(app, parent)
            dd = uidropdown(parent);
            dd.FontName = app.Font;
            dd.FontSize = 12;
            dd.BackgroundColor = app.ColInput;
            dd.FontColor = app.ColText;
        end

        function ef = makeNumberField(app, parent, value, limits)
            ef = uieditfield(parent, 'numeric');
            ef.Value = value;
            ef.Limits = limits;
            ef.FontName = app.Font;
            ef.FontSize = 12;
            ef.BackgroundColor = app.ColInput;
            ef.FontColor = app.ColText;
            ef.HorizontalAlignment = 'center';
        end

        function lbl = makeSection(app, parent, row, text)
            lbl = uilabel(parent);
            lbl.Text = upper(text);
            app.styleText(lbl, 10, 'bold', app.ColAccent);
            lbl.Layout.Row = row;
            lbl.Layout.Column = 1;
            lbl.VerticalAlignment = 'bottom';
        end

        function lbl = makeMuted(app, parent, row, text)
            lbl = uilabel(parent);
            lbl.Text = text;
            lbl.WordWrap = 'on';
            app.styleText(lbl, 11, 'normal', app.ColMuted);
            lbl.Layout.Row = row;
            lbl.Layout.Column = 1;
        end

        function g = makeGrid(app, parent, rows, cols)
            g = uigridlayout(parent);
            g.RowHeight = rows;
            g.ColumnWidth = cols;
            g.Padding = [0 0 0 0];
            g.RowSpacing = 6;
            g.ColumnSpacing = 6;
            g.BackgroundColor = parent.BackgroundColor;
        end

        function ax = buildImageCard(app, parent, row, col, titleText)
            % Card = panel seperti kartu, ada judul + axes tanpa border
            p = uipanel(parent);
            p.Layout.Row = row;
            p.Layout.Column = col;
            p.BackgroundColor = app.ColCard;
            p.BorderType = 'none';

            g = uigridlayout(p);
            g.RowHeight = {20, '1x'};
            g.ColumnWidth = {'1x'};
            g.Padding = [10 8 10 8];
            g.RowSpacing = 4;
            g.BackgroundColor = app.ColCard;

            lbl = uilabel(g);
            lbl.Text = titleText;
            app.styleText(lbl, 12, 'bold', app.ColText);
            lbl.Layout.Row = 1;
            lbl.Layout.Column = 1;

            ax = uiaxes(g);
            ax.Layout.Row = 2;
            ax.Layout.Column = 1;
            app.styleAxes(ax);
            app.showOn(ax, []);
        end

        function styleAxes(app, ax)
            ax.Color = app.ColCard;
            ax.XColor = 'none';
            ax.YColor = 'none';
            ax.XTick = [];
            ax.YTick = [];
            ax.Toolbar.Visible = 'off';
            disableDefaultInteractivity(ax);
        end

        function showOn(app, ax, img)
            % Tampilkan img di ax, atau placeholder redup kalau kosong
            if isempty(img)
                cla(ax);
                ax.XLim = [0 1];
                ax.YLim = [0 1];
                text(ax, 0.5, 0.5, 'belum ada citra', ...
                    'HorizontalAlignment', 'center', 'FontName', app.Font, ...
                    'FontSize', 11, 'Color', app.ColMuted);
            else
                % Placeholder sudah kunci limit ke [0 1]; citra atur ulang
                ax.XLimMode = 'auto';
                ax.YLimMode = 'auto';
                showImageOnAxes(ax, img);
                axis(ax, 'image');
            end
            app.styleAxes(ax);
        end

        function [sidebar, main, status] = buildTabFrame(app, tab, sidebarRows)
            % Layout umum: sidebar (kiri) | card citra (kanan) / status bar
            tab.BackgroundColor = app.ColBg;
            tab.ForegroundColor = app.ColText;

            g = uigridlayout(tab);
            g.RowHeight = {'1x', 30};
            g.ColumnWidth = {320, '1x'};
            g.Padding = [12 12 12 10];
            g.RowSpacing = 10;
            g.ColumnSpacing = 12;
            g.BackgroundColor = app.ColBg;

            sp = uipanel(g);
            sp.Layout.Row = 1;
            sp.Layout.Column = 1;
            sp.BackgroundColor = app.ColPanel;
            sp.BorderType = 'none';
            sp.Scrollable = 'on';
            sidebar = uigridlayout(sp);
            sidebar.RowHeight = sidebarRows;
            sidebar.ColumnWidth = {'1x'};
            sidebar.Padding = [14 14 14 14];
            sidebar.RowSpacing = 6;
            sidebar.BackgroundColor = app.ColPanel;
            sidebar.Scrollable = 'on';

            main = uigridlayout(g);
            main.Layout.Row = 1;
            main.Layout.Column = 2;
            main.Padding = [0 0 0 0];
            main.RowSpacing = 12;
            main.ColumnSpacing = 12;
            main.BackgroundColor = app.ColBg;

            status = uilabel(g);
            status.Layout.Row = 2;
            status.Layout.Column = [1 2];
            status.BackgroundColor = app.ColPanel;
            app.styleText(status, 11, 'normal', app.ColMuted);
            status.Text = '';
        end

        function [dd, browse, info] = buildInputSection(app, sidebar, startRow, datasetSubdir)
            % Judul section + [dropdown dataset | Browse] + info citra
            app.makeSection(sidebar, startRow, 'Citra masukan');

            row = app.makeGrid(sidebar, {30}, {'1x', 80});
            row.Layout.Row = startRow + 1;
            row.Layout.Column = 1;
            dd = app.makeDropDown(row);
            dd.Layout.Column = 1;
            names = app.listDatasetImages(datasetSubdir);
            dd.Items = [{app.DatasetPlaceholder}, names];
            dd.Value = app.DatasetPlaceholder;
            dd.Tooltip = ['Citra dari data/' datasetSubdir];
            browse = app.makeButton(row, 'Browse...', 'secondary');
            browse.Layout.Column = 2;

            info = app.makeMuted(sidebar, startRow + 2, 'Pilih citra dari dataset atau Browse.');
        end

        function [run, reset, export] = buildActionSection(app, sidebar, startRow)
            run = app.makeButton(sidebar, 'Run', 'primary');
            run.Layout.Row = startRow;
            run.Layout.Column = 1;

            row = app.makeGrid(sidebar, {30}, {'1x', '1x'});
            row.Layout.Row = startRow + 1;
            row.Layout.Column = 1;
            reset = app.makeButton(row, 'Reset', 'secondary');
            reset.Layout.Column = 1;
            export = app.makeButton(row, 'Export View', 'secondary');
            export.Layout.Column = 2;
        end

        function map = buildParamPanel(app, paramGrid, specs)
            % Bangun ulang grid 2 kolom [label | field angka] dari registry
            delete(paramGrid.Children);
            map = containers.Map('KeyType', 'char', 'ValueType', 'any');
            if isempty(specs)
                paramGrid.RowHeight = {22};
                paramGrid.ColumnWidth = {'1x'};
                lbl = uilabel(paramGrid);
                lbl.Text = 'Tidak ada parameter tambahan.';
                app.styleText(lbl, 11, 'normal', app.ColMuted);
                return;
            end
            n = numel(specs);
            paramGrid.RowHeight = repmat({28}, 1, n);
            paramGrid.ColumnWidth = {'1.4x', '1x'};
            for i = 1:n
                spec = specs(i);
                lbl = uilabel(paramGrid);
                lbl.Text = spec.Label;
                app.styleText(lbl, 12, 'normal', app.ColText);
                lbl.Layout.Row = i;
                lbl.Layout.Column = 1;

                ef = app.makeNumberField(paramGrid, spec.Default, [spec.Min spec.Max]);
                ef.Layout.Row = i;
                ef.Layout.Column = 2;
                map(spec.Name) = ef;
            end
        end

        function s = collectParams(~, map)
            s = struct();
            ks = map.keys;
            for i = 1:numel(ks)
                s.(ks{i}) = map(ks{i}).Value;
            end
        end

        function setStatus(app, lbl, msg, level)
            switch level
                case 'ok',    c = app.ColAccent2; prefix = char(10003);   % tanda centang
                case 'warn',  c = app.ColWarn;    prefix = '!';
                case 'error', c = app.ColError;   prefix = char(10007);   % tanda silang
                case 'busy',  c = app.ColAccent;  prefix = char(8987);    % jam pasir
                otherwise,    c = app.ColMuted;   prefix = char(8226);    % titik
            end
            lbl.FontColor = c;
            lbl.Text = sprintf('  %s  %s', prefix, msg);
            drawnow limitrate;
        end

        function handleRunError(app, lbl, ME)
            % Bagian yang belum jadi cukup warning, gagal asli baru error
            if endsWith(ME.identifier, ':notImplemented')
                app.setStatus(lbl, ME.message, 'warn');
            else
                app.setStatus(lbl, ['Gagal: ' ME.message], 'error');
                uialert(app.UIFigure, ME.message, 'Run Error');
            end
        end

        % ------------------------- helper data -------------------------
        function folder = dataFolder(~, subdir)
            rootFolder = fileparts(fileparts(mfilename('fullpath')));
            folder = fullfile(rootFolder, 'data', subdir);
        end

        function names = listDatasetImages(app, subdir)
            names = {};
            folder = app.dataFolder(subdir);
            if ~exist(folder, 'dir')
                return;
            end
            exts = {'*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tif', '*.tiff'};
            for k = 1:numel(exts)
                d = dir(fullfile(folder, exts{k}));
                names = [names, {d.name}]; %#ok<AGROW>
            end
            names = unique(names);
        end

        function [img, name] = loadFromDropDown(app, dd, subdir)
            img = [];
            name = dd.Value;
            if strcmp(name, app.DatasetPlaceholder)
                return;
            end
            img = imread(fullfile(app.dataFolder(subdir), name));
        end

        function [img, name] = loadFromBrowse(app, subdir)
            img = [];
            name = '';
            startFolder = app.dataFolder(subdir);
            if ~exist(startFolder, 'dir')
                startFolder = pwd;
            end
            [file, folder] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif;*.tiff', 'Image Files'}, ...
                'Pilih citra', fullfile(startFolder, filesep));
            figure(app.UIFigure);   % bawa app ke depan lagi setelah dialog
            if isequal(file, 0)
                return;
            end
            img = imread(fullfile(folder, file));
            name = file;
        end

        function txt = imageInfo(~, img, name)
            if size(img, 3) == 3
                kind = 'RGB';
            else
                kind = 'Grayscale';
            end
            txt = sprintf('%s  %s  %d x %d px  %s  %s', name, char(183), ...
                size(img, 2), size(img, 1), char(183), kind);
        end

    end

    % =====================================================================
    %  Pembuatan komponen
    % =====================================================================
    methods (Access = private)

        function createComponents(app)
            app.UIFigure = uifigure('Name', 'IF4073 Tugas 3 - Image Segmentation Studio', ...
                'Visible', 'off');
            app.UIFigure.Position = [60 40 1400 860];
            app.UIFigure.Color = app.ColBg;

            root = uigridlayout(app.UIFigure);
            root.RowHeight = {64, '1x'};
            root.ColumnWidth = {'1x'};
            root.Padding = [0 0 0 0];
            root.RowSpacing = 0;
            root.BackgroundColor = app.ColBg;

            app.buildHeader(root);

            app.TabGroup = uitabgroup(root);
            app.TabGroup.Layout.Row = 2;
            app.TabGroup.Layout.Column = 1;

            app.EdgeTab = uitab(app.TabGroup, 'Title', '  Edge Detection  ');
            app.SMTab   = uitab(app.TabGroup, 'Title', '  Split & Merge  ');
            app.SemTab  = uitab(app.TabGroup, 'Title', '  Semantic (CNN)  ');

            app.buildEdgeTab();
            app.buildSplitMergeTab();
            app.buildSemanticTab();

            app.UIFigure.CloseRequestFcn = @(~, ~) delete(app);
            app.UIFigure.Visible = 'on';
        end

        function buildHeader(app, root)
            hp = uipanel(root);
            hp.Layout.Row = 1;
            hp.Layout.Column = 1;
            hp.BackgroundColor = app.ColPanel;
            hp.BorderType = 'none';

            hg = uigridlayout(hp);
            hg.RowHeight = {26, 18};
            hg.ColumnWidth = {6, '1x', 'fit'};
            hg.Padding = [16 10 20 8];
            hg.RowSpacing = 0;
            hg.ColumnSpacing = 12;
            hg.BackgroundColor = app.ColPanel;

            % Bar aksen di kiri judul
            bar = uilabel(hg);
            bar.Text = '';
            bar.BackgroundColor = app.ColAccent;
            bar.Layout.Row = [1 2];
            bar.Layout.Column = 1;

            t = uilabel(hg);
            t.Text = 'Image Segmentation Studio';
            app.styleText(t, 19, 'bold', app.ColText);
            t.Layout.Row = 1;
            t.Layout.Column = 2;

            s = uilabel(hg);
            s.Text = ['IF4073 Pemrosesan Citra Digital  ' char(183) '  Tugas 3  ' char(183) ...
                '  Edge Detection, Split & Merge, Semantic Segmentation'];
            app.styleText(s, 11, 'normal', app.ColMuted);
            s.Layout.Row = 2;
            s.Layout.Column = 2;

            chip = uilabel(hg);
            chip.Text = '  MATLAB  ';
            chip.BackgroundColor = app.ColCard;
            app.styleText(chip, 11, 'bold', app.ColAccent2);
            chip.HorizontalAlignment = 'center';
            chip.Layout.Row = [1 2];
            chip.Layout.Column = 3;
        end

        % ---------------------------- TAB 1 ----------------------------
        function buildEdgeTab(app)
            rows = {18, 30, 'fit', ...        % 1-3  masukan
                    22, 30, 'fit', ...        % 4-6  operator + param
                    22, 30, 'fit', ...        % 7-9  threshold
                    22, 'fit', ...            % 10-11 mask objek
                    '1x', 40, 30};            % 12-14 spacer + aksi
            [sb, main, app.E_StatusLabel] = app.buildTabFrame(app.EdgeTab, rows);

            [app.E_DatasetDropDown, app.E_BrowseButton, app.E_ImageInfoLabel] = ...
                app.buildInputSection(sb, 1, 'bsds500');
            app.E_DatasetDropDown.ValueChangedFcn = @(~, ~) app.onEdgeDatasetPicked();
            app.E_BrowseButton.ButtonPushedFcn = @(~, ~) app.onEdgeBrowse();

            % Operator + parameternya
            app.makeSection(sb, 4, 'Operator deteksi tepi');
            app.E_MethodDropDown = app.makeDropDown(sb);
            app.E_MethodDropDown.Layout.Row = 5;
            app.E_MethodDropDown.Layout.Column = 1;
            app.E_MethodDropDown.ValueChangedFcn = @(~, ~) app.onEdgeMethodChanged();
            app.E_ParamGrid = app.makeGrid(sb, {22}, {'1x'});
            app.E_ParamGrid.Layout.Row = 6;
            app.E_ParamGrid.Layout.Column = 1;

            % Threshold (hanya operator orde satu/dua)
            app.makeSection(sb, 7, 'Thresholding');
            tg = app.makeGrid(sb, {30}, {'1.4x', '1x'});
            tg.Layout.Row = 8;
            tg.Layout.Column = 1;
            app.E_ThrModeDropDown = app.makeDropDown(tg);
            app.E_ThrModeDropDown.Items = {'Otsu (otomatis)', 'Percentile', 'Manual'};
            app.E_ThrModeDropDown.ItemsData = {'otsu', 'percentile', 'manual'};
            app.E_ThrModeDropDown.Value = 'otsu';
            app.E_ThrModeDropDown.ValueChangedFcn = @(~, ~) app.onEdgeThrModeChanged();
            app.E_ThrValueField = app.makeNumberField(tg, 90, [0 100]);
            app.E_ThrHintLabel = app.makeMuted(sb, 9, '');

            % Peta tepi -> mask objek
            app.makeSection(sb, 10, 'Pra-proses & segmentasi objek');
            app.E_SegGrid = app.makeGrid(sb, {22}, {'1x'});
            app.E_SegGrid.Layout.Row = 11;
            app.E_SegGrid.Layout.Column = 1;

            [app.E_RunButton, app.E_ResetButton, app.E_ExportButton] = app.buildActionSection(sb, 13);
            app.E_RunButton.ButtonPushedFcn = @(~, ~) app.onEdgeRun();
            app.E_ResetButton.ButtonPushedFcn = @(~, ~) app.onEdgeReset();
            app.E_ExportButton.ButtonPushedFcn = @(~, ~) app.onExportView(app.E_StatusLabel);

            % Card citra 2 x 3
            main.RowHeight = {'1x', '1x'};
            main.ColumnWidth = {'1x', '1x', '1x'};
            titles = {'Citra Asli', 'Respons Operator', 'Peta Tepi (biner)', ...
                      'Mask Objek', 'Hasil Segmentasi', 'Kontur Objek'};
            app.E_Axes = gobjects(1, 6);
            for k = 1:6
                app.E_Axes(k) = app.buildImageCard(main, ceil(k / 3), mod(k - 1, 3) + 1, titles{k});
            end

            % Isi dropdown + panel parameter dari registry
            [app.EdgeRegistry, app.EdgeSegSpecs] = edgeRegistry();
            app.E_MethodDropDown.Items = {app.EdgeRegistry.Label};
            app.E_MethodDropDown.ItemsData = {app.EdgeRegistry.Key};
            app.E_MethodDropDown.Value = 'sobel';
            app.E_SegControls = app.buildParamPanel(app.E_SegGrid, app.EdgeSegSpecs);
            app.onEdgeMethodChanged();
            app.setStatus(app.E_StatusLabel, 'Siap. Pilih citra lalu tekan Run.', 'info');
        end

        % ---------------------------- TAB 2 ----------------------------
        function buildSplitMergeTab(app)
            rows = {18, 30, 'fit', ...        % 1-3  masukan
                    22, 30, 'fit', ...        % 4-6  predikat + param
                    22, 'fit', ...            % 7-8  statistik
                    '1x', 40, 30};            % 9-11 spacer + aksi
            [sb, main, app.S_StatusLabel] = app.buildTabFrame(app.SMTab, rows);

            [app.S_DatasetDropDown, app.S_BrowseButton, app.S_ImageInfoLabel] = ...
                app.buildInputSection(sb, 1, 'bsds500');
            app.S_DatasetDropDown.ValueChangedFcn = @(~, ~) app.onSMDatasetPicked();
            app.S_BrowseButton.ButtonPushedFcn = @(~, ~) app.onSMBrowse();

            app.makeSection(sb, 4, 'Predikat homogenitas');
            app.S_PredicateDropDown = app.makeDropDown(sb);
            app.S_PredicateDropDown.Layout.Row = 5;
            app.S_PredicateDropDown.Layout.Column = 1;
            app.S_PredicateDropDown.ValueChangedFcn = @(~, ~) app.onSMPredicateChanged();
            app.S_ParamGrid = app.makeGrid(sb, {22}, {'1x'});
            app.S_ParamGrid.Layout.Row = 6;
            app.S_ParamGrid.Layout.Column = 1;

            app.makeSection(sb, 7, 'Statistik');
            app.S_StatsLabel = app.makeMuted(sb, 8, 'Belum dijalankan.');

            [app.S_RunButton, app.S_ResetButton, app.S_ExportButton] = app.buildActionSection(sb, 10);
            app.S_RunButton.ButtonPushedFcn = @(~, ~) app.onSMRun();
            app.S_ResetButton.ButtonPushedFcn = @(~, ~) app.onSMReset();
            app.S_ExportButton.ButtonPushedFcn = @(~, ~) app.onExportView(app.S_StatusLabel);

            main.RowHeight = {'1x', '1x'};
            main.ColumnWidth = {'1x', '1x', '1x'};
            titles = {'Citra Asli', 'Grid Quadtree (split)', 'Hasil Split (mean)', ...
                      'Hasil Merge (mean)', 'Label Region', 'Batas Region'};
            app.S_Axes = gobjects(1, 6);
            for k = 1:6
                app.S_Axes(k) = app.buildImageCard(main, ceil(k / 3), mod(k - 1, 3) + 1, titles{k});
            end

            app.SMRegistry = splitMergeRegistry();
            app.S_PredicateDropDown.Items = {app.SMRegistry.Label};
            app.S_PredicateDropDown.ItemsData = {app.SMRegistry.Key};
            app.S_PredicateDropDown.Value = app.SMRegistry(1).Key;
            app.onSMPredicateChanged();
            app.setStatus(app.S_StatusLabel, 'Siap. Pilih citra lalu tekan Run.', 'info');
        end

        % ---------------------------- TAB 3 ----------------------------
        function buildSemanticTab(app)
            rows = {18, 30, 'fit', ...        % 1-3  masukan
                    22, 'fit', ...            % 4-5  info model
                    22, 'fit', ...            % 6-7  legenda
                    '1x', 40, 30};            % 8-10 spacer + aksi
            [sb, main, app.D_StatusLabel] = app.buildTabFrame(app.SemTab, rows);

            [app.D_DatasetDropDown, app.D_BrowseButton, app.D_ImageInfoLabel] = ...
                app.buildInputSection(sb, 1, 'camvid');
            app.D_DatasetDropDown.ValueChangedFcn = @(~, ~) app.onSemDatasetPicked();
            app.D_BrowseButton.ButtonPushedFcn = @(~, ~) app.onSemBrowse();

            app.makeSection(sb, 4, 'Model');
            app.makeMuted(sb, 5, ['Pretrained CNN di-fine-tune pada CamVid (11 kelas). ' ...
                'Dipanggil lewat segmentSemantic(img) di src/d-semantic.']);

            app.makeSection(sb, 6, 'Legenda kelas');
            app.D_LegendGrid = app.makeGrid(sb, {22}, {'1x'});
            app.D_LegendGrid.Layout.Row = 7;
            app.D_LegendGrid.Layout.Column = 1;
            app.buildLegend({}, []);

            [app.D_RunButton, app.D_ResetButton, app.D_ExportButton] = app.buildActionSection(sb, 9);
            app.D_RunButton.ButtonPushedFcn = @(~, ~) app.onSemRun();
            app.D_ResetButton.ButtonPushedFcn = @(~, ~) app.onSemReset();
            app.D_ExportButton.ButtonPushedFcn = @(~, ~) app.onExportView(app.D_StatusLabel);

            main.RowHeight = {'1x'};
            main.ColumnWidth = {'1x', '1x', '1x'};
            titles = {'Citra Masukan', 'Label Semantik', 'Overlay'};
            app.D_Axes = gobjects(1, 3);
            for k = 1:3
                app.D_Axes(k) = app.buildImageCard(main, 1, k, titles{k});
            end
            app.setStatus(app.D_StatusLabel, 'Siap. Pilih citra CamVid lalu tekan Run.', 'info');
        end

        function buildLegend(app, classNames, cmap)
            % Legenda dua kolom: [kotak warna | nama kelas]
            delete(app.D_LegendGrid.Children);
            if isempty(classNames)
                app.D_LegendGrid.RowHeight = {22};
                app.D_LegendGrid.ColumnWidth = {'1x'};
                lbl = uilabel(app.D_LegendGrid);
                lbl.Text = 'Muncul setelah segmentasi dijalankan.';
                app.styleText(lbl, 11, 'normal', app.ColMuted);
                return;
            end
            n = numel(classNames);
            app.D_LegendGrid.RowHeight = repmat({20}, 1, n);
            app.D_LegendGrid.ColumnWidth = {28, '1x'};
            app.D_LegendGrid.RowSpacing = 4;
            for k = 1:n
                sw = uilabel(app.D_LegendGrid);
                sw.Text = '';
                sw.BackgroundColor = cmap(k, :);
                sw.Layout.Row = k;
                sw.Layout.Column = 1;
                nm = uilabel(app.D_LegendGrid);
                nm.Text = classNames{k};
                app.styleText(nm, 12, 'normal', app.ColText);
                nm.Layout.Row = k;
                nm.Layout.Column = 2;
            end
        end

    end

    % =====================================================================
    %  Callback Tab 1 (Edge Detection)
    % =====================================================================
    methods (Access = private)

        function setEdgeImage(app, img, name)
            if isempty(img)
                return;
            end
            app.E_Image = img;
            app.showOn(app.E_Axes(1), img);
            for k = 2:6
                app.showOn(app.E_Axes(k), []);
            end
            app.E_ImageInfoLabel.Text = app.imageInfo(img, name);
            app.setStatus(app.E_StatusLabel, ['Citra dimuat: ' name], 'ok');
        end

        function onEdgeDatasetPicked(app)
            [img, name] = app.loadFromDropDown(app.E_DatasetDropDown, 'bsds500');
            app.setEdgeImage(img, name);
        end

        function onEdgeBrowse(app)
            [img, name] = app.loadFromBrowse('bsds500');
            app.setEdgeImage(img, name);
        end

        function entry = currentEdgeEntry(app)
            entry = app.EdgeRegistry(strcmp({app.EdgeRegistry.Key}, app.E_MethodDropDown.Value));
        end

        function onEdgeMethodChanged(app)
            entry = app.currentEdgeEntry();
            app.E_ParamControls = app.buildParamPanel(app.E_ParamGrid, entry.Params);
            % Canny punya threshold ganda sendiri -> matikan yang generik
            enable = matlab.lang.OnOffSwitchState(entry.UsesThreshold);
            app.E_ThrModeDropDown.Enable = enable;
            app.E_ThrValueField.Enable = enable;
            app.onEdgeThrModeChanged();
        end

        function onEdgeThrModeChanged(app)
            entry = app.currentEdgeEntry();
            if ~entry.UsesThreshold
                app.E_ThrHintLabel.Text = 'Canny memakai threshold ganda T1/T2 (hysteresis) di atas.';
                return;
            end
            switch app.E_ThrModeDropDown.Value
                case 'otsu'
                    app.E_ThrValueField.Enable = 'off';
                    app.E_ThrHintLabel.Text = 'T dihitung otomatis dengan metode Otsu pada histogram respons.';
                case 'percentile'
                    app.E_ThrValueField.Enable = 'on';
                    app.E_ThrValueField.Limits = [0 100];
                    app.E_ThrValueField.Value = 90;
                    app.E_ThrHintLabel.Text = 'Piksel di atas persentil ke-p dianggap tepi (mis. 90).';
                case 'manual'
                    app.E_ThrValueField.Enable = 'on';
                    app.E_ThrValueField.Limits = [0 1];
                    app.E_ThrValueField.Value = 0.2;
                    app.E_ThrHintLabel.Text = 'T dalam fraksi respons maksimum (0 - 1).';
            end
        end

        function onEdgeRun(app)
            if isempty(app.E_Image)
                app.setStatus(app.E_StatusLabel, 'Pilih citra terlebih dahulu.', 'warn');
                return;
            end
            entry = app.currentEdgeEntry();
            params = app.collectParams(app.E_ParamControls);
            segParams = app.collectParams(app.E_SegControls);
            thr = struct('Mode', app.E_ThrModeDropDown.Value, 'Value', app.E_ThrValueField.Value);

            app.setStatus(app.E_StatusLabel, ['Memproses ' entry.Label ' ...'], 'busy');
            try
                tStart = tic;
                [R, info] = applyEdgeSegmentation(app.E_Image, entry.Key, params, thr, segParams);
                elapsed = toc(tStart);
            catch ME
                app.handleRunError(app.E_StatusLabel, ME);
                return;
            end
            views = {R.Response, R.Edges, R.Mask, R.Segmented, R.Overlay};
            for k = 1:5
                app.showOn(app.E_Axes(k + 1), views{k});
            end
            app.setStatus(app.E_StatusLabel, sprintf('%s  |  %s  |  %.2f s', ...
                info.Label, info.ParamStr, elapsed), 'ok');
        end

        function onEdgeReset(app)
            app.E_Image = [];
            for k = 1:6
                app.showOn(app.E_Axes(k), []);
            end
            app.E_DatasetDropDown.Value = app.DatasetPlaceholder;
            app.E_ImageInfoLabel.Text = 'Pilih citra dari dataset atau Browse.';
            app.E_MethodDropDown.Value = 'sobel';
            app.E_ThrModeDropDown.Value = 'otsu';
            app.E_SegControls = app.buildParamPanel(app.E_SegGrid, app.EdgeSegSpecs);
            app.onEdgeMethodChanged();
            app.setStatus(app.E_StatusLabel, 'Siap. Pilih citra lalu tekan Run.', 'info');
        end

    end

    % =====================================================================
    %  Callback Tab 2 (Split & Merge)
    % =====================================================================
    methods (Access = private)

        function setSMImage(app, img, name)
            if isempty(img)
                return;
            end
            app.S_Image = img;
            app.showOn(app.S_Axes(1), img);
            for k = 2:6
                app.showOn(app.S_Axes(k), []);
            end
            app.S_ImageInfoLabel.Text = app.imageInfo(img, name);
            app.S_StatsLabel.Text = 'Belum dijalankan.';
            app.setStatus(app.S_StatusLabel, ['Citra dimuat: ' name], 'ok');
        end

        function onSMDatasetPicked(app)
            [img, name] = app.loadFromDropDown(app.S_DatasetDropDown, 'bsds500');
            app.setSMImage(img, name);
        end

        function onSMBrowse(app)
            [img, name] = app.loadFromBrowse('bsds500');
            app.setSMImage(img, name);
        end

        function onSMPredicateChanged(app)
            entry = app.SMRegistry(strcmp({app.SMRegistry.Key}, app.S_PredicateDropDown.Value));
            app.S_ParamControls = app.buildParamPanel(app.S_ParamGrid, entry.Params);
        end

        function onSMRun(app)
            if isempty(app.S_Image)
                app.setStatus(app.S_StatusLabel, 'Pilih citra terlebih dahulu.', 'warn');
                return;
            end
            key = app.S_PredicateDropDown.Value;
            params = app.collectParams(app.S_ParamControls);

            app.setStatus(app.S_StatusLabel, 'Memproses split and merge ...', 'busy');
            try
                tStart = tic;
                [R, info] = applySplitMerge(app.S_Image, key, params);
                elapsed = toc(tStart);
            catch ME
                app.handleRunError(app.S_StatusLabel, ME);
                return;
            end
            views = {R.SplitGrid, R.SplitMean, R.MergedMean, R.LabelColor, R.Boundary};
            for k = 1:5
                app.showOn(app.S_Axes(k + 1), views{k});
            end
            app.S_StatsLabel.Text = info.Summary;
            app.setStatus(app.S_StatusLabel, sprintf('%s  |  %s  |  %.2f s', ...
                info.Label, info.ParamStr, elapsed), 'ok');
        end

        function onSMReset(app)
            app.S_Image = [];
            for k = 1:6
                app.showOn(app.S_Axes(k), []);
            end
            app.S_DatasetDropDown.Value = app.DatasetPlaceholder;
            app.S_ImageInfoLabel.Text = 'Pilih citra dari dataset atau Browse.';
            app.S_StatsLabel.Text = 'Belum dijalankan.';
            app.S_PredicateDropDown.Value = app.SMRegistry(1).Key;
            app.onSMPredicateChanged();
            app.setStatus(app.S_StatusLabel, 'Siap. Pilih citra lalu tekan Run.', 'info');
        end

    end

    % =====================================================================
    %  Callback Tab 3 (CNN semantik, diisi oleh Bagian D)
    % =====================================================================
    methods (Access = private)

        function setSemImage(app, img, name)
            if isempty(img)
                return;
            end
            if size(img, 3) == 1
                img = repmat(img, 1, 1, 3);   % CNN butuh 3 kanal
            end
            app.D_Image = img;
            app.showOn(app.D_Axes(1), img);
            app.showOn(app.D_Axes(2), []);
            app.showOn(app.D_Axes(3), []);
            app.D_ImageInfoLabel.Text = app.imageInfo(img, name);
            app.setStatus(app.D_StatusLabel, ['Citra dimuat: ' name], 'ok');
        end

        function onSemDatasetPicked(app)
            [img, name] = app.loadFromDropDown(app.D_DatasetDropDown, 'camvid');
            app.setSemImage(img, name);
        end

        function onSemBrowse(app)
            [img, name] = app.loadFromBrowse('camvid');
            app.setSemImage(img, name);
        end

        function onSemRun(app)
            if isempty(app.D_Image)
                app.setStatus(app.D_StatusLabel, 'Pilih citra terlebih dahulu.', 'warn');
                return;
            end
            app.setStatus(app.D_StatusLabel, 'Menjalankan model CNN ...', 'busy');
            try
                tStart = tic;
                [L, classNames, cmap] = segmentSemantic(app.D_Image);
                elapsed = toc(tStart);
            catch ME
                app.handleRunError(app.D_StatusLabel, ME);
                return;
            end

            % Terima label kategorikal atau numerik; undefined/NaN -> 0
            if iscategorical(L)
                if isempty(classNames)
                    classNames = categories(L)';
                end
                L = double(L);
            end
            L(isnan(L)) = 0;
            [h, w, ~] = size(app.D_Image);
            if ~isequal(size(L), [h w])
                L = imresize(L, [h w], 'nearest');   % kembalikan ke resolusi masukan
            end

            labelRgb = labelToRgb(L, cmap);
            overlay = 0.5 * im2double(app.D_Image) + 0.5 * labelRgb;
            app.showOn(app.D_Axes(2), labelRgb);
            app.showOn(app.D_Axes(3), overlay);
            app.buildLegend(classNames, cmap);
            app.setStatus(app.D_StatusLabel, sprintf('Segmentasi semantik selesai  |  %d kelas  |  %.2f s', ...
                numel(classNames), elapsed), 'ok');
        end

        function onSemReset(app)
            app.D_Image = [];
            for k = 1:3
                app.showOn(app.D_Axes(k), []);
            end
            app.D_DatasetDropDown.Value = app.DatasetPlaceholder;
            app.D_ImageInfoLabel.Text = 'Pilih citra dari dataset atau Browse.';
            app.buildLegend({}, []);
            app.setStatus(app.D_StatusLabel, 'Siap. Pilih citra CamVid lalu tekan Run.', 'info');
        end

    end

    % =====================================================================
    %  Shared: ekspor seluruh jendela jadi PNG (folder default: results/)
    % =====================================================================
    methods (Access = private)

        function onExportView(app, statusLabel)
            rootFolder = fileparts(fileparts(mfilename('fullpath')));
            defaultName = fullfile(rootFolder, 'results', ...
                ['gui_snapshot_' char(datetime('now', 'Format', 'yyyyMMdd_HHmmss')) '.png']);
            [file, folder] = uiputfile('*.png', 'Simpan tampilan', defaultName);
            figure(app.UIFigure);
            if isequal(file, 0)
                return;
            end
            try
                exportapp(app.UIFigure, fullfile(folder, file));
                app.setStatus(statusLabel, ['Tersimpan: ' fullfile(folder, file)], 'ok');
            catch ME
                app.setStatus(statusLabel, ['Export gagal: ' ME.message], 'error');
            end
        end

    end

    % =====================================================================
    %  Konstruktor / destruktor
    % =====================================================================
    methods (Access = public)

        function app = SegmentationApp()
            srcRoot = fileparts(mfilename('fullpath'));
            addpath(genpath(srcRoot));   % core/, b-*/, c-*/, d-*/

            createComponents(app);
            registerApp(app, app.UIFigure);
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            delete(app.UIFigure);
        end

    end
end
