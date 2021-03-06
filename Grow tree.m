%% Grow a classification tree 构造一棵树
load ionosphere
tc = fitctree(X,Y)

% control the depth of the trees 控制树的深度
% default：－－－－MaxNumSplits：n－1（n：＃samples）
%          －－－－MinLeafSize：1
%          －－－－MinParentSize：10
rng(1); % For reproducibility
MdlDefault = fitctree(X,Y,'CrossVal','on');
numBranches = @(x)sum(x.IsBranch);
% 10折交叉里面每一折的用了哪些特征做分隔
mdlDefaultNumSplits = cellfun(numBranches, MdlDefault.Trained);
figure;
histogram(mdlDefaultNumSplits)
% 观察决策树结构
view(MdlDefault.Trained{1},'Mode','graph')
% 自定义树的最大深度为7
Mdl7 = fitctree(X,Y,'MaxNumSplits',7,'CrossVal','on');
view(Mdl7.Trained{1},'Mode','graph')
% 比较模型的分类错误率
classErrorDefault = kfoldLoss(MdlDefault)
classError7 = kfoldLoss(Mdl7)

%% 自动优化超参数
load fisheriris
X = meas;
Y = species;
Mdl = fitctree(X,Y,'OptimizeHyperparameters','auto')

%% 无偏预测重要性估计（特征重要性排序）
load census1994
X = adultdata(:,{'age','workClass','education_num','marital_status','race',...
    'sex','capital_gain','capital_loss','hours_per_week','salary'});
summary(X)
Mdl = fitctree(X,'salary','PredictorSelection','curvature',...
    'Surrogate','on');
imp = predictorImportance(Mdl);

figure;
bar(imp);
title('Predictor Importance Estimates');
ylabel('Estimates');
xlabel('Predictors');
h = gca;
h.XTickLabel = Mdl.PredictorNames;
h.XTickLabelRotation = 45;
h.TickLabelInterpreter = 'none';

%%  高维数组自动优化分类树的超参数（文件太大的数组）
ds = datastore('airlinesmall.csv');
ds.SelectedVariableNames = {'Month','DayofMonth','DayOfWeek',...
                            'DepTime','ArrDelay','Distance','DepDelay'};
ds.TreatAsMissing = 'NA';
tt  = tall(ds) % Tall table
Y = tt.DepDelay > 10 % Class labels
X = tt{:,1:end-1} % Predictor data
R = rmmissing([X Y]); % Data with missing entries removed
X = R(:,1:end-1); 
Y = R(:,end); 
Z = zscore(X);
rng('default') 
tallrng('default')
[Mdl,FitInfo,HyperparameterOptimizationResults] = fitctree(Z,Y,...
    'OptimizeHyperparameters','auto',...
    'HyperparameterOptimizationOptions',struct('Holdout',0.3,...
    'AcquisitionFunctionName','expected-improvement-plus'))

%% 参数设置 
% 'AlgorithmForCategorical'－－－'Exact' | 'PullLeft' | 'PCA' | 'OVAbyClass'
% 'CategoricalPredictors' －－－'categorical array' | 'character array' | 'string array' | 'logical vector' | 'numeric vector' | 'cell array' 
% 'Cost'－－－'square matrix' | 'structure'
% 'MaxDepth'－－－树深度一般不默认
% 'MaxNumCategories'－－－默认10（精确计算的最大类别数）
% 'MergeLeaves'－－－是否剪枝 默认'on' | 'off'
% 'MinParentSize'－－－分支节点观察的最小样本 默认10
% 'PredictorNames'－－－预测变量名称 默认全部
% 'PredictorSelection'－－－分割节点算法 'allsplits' (default) | 'curvature' | 'interaction-curvature'
% 'Prior'类的先验概率找出异常样本－－－'empirical' (default) | 'uniform' | vector of scalar values | structure
% 'Prune' 估计已修剪子树的最佳序列的标志－－－'on' (default) | 'off'
% 'PruneCriterion'－－－剪枝标准 'error' (default) | 'impurity'
% 'Reproducible' －－－要不要繁殖 false(default) | true 
% 'ScoreTransform'－－－转移函数 默认none
                    % 'doublelogit'	1/(1 + e?2x)
                    % 'invlogit'	log(x / (1 ? x))
                    % 'ismax'	Sets the score for the class with the largest score to 1, and sets the scores for all other classes to 0
                    % 'logit'	1/(1 + e?x)
                    % 'none' or 'identity'	x (no transformation)
                    % 'sign'	?1 for x < 0  0 for x = 0  1 for x > 0
                    % 'symmetric'	2x ? 1
                    % 'symmetricismax'	Sets the score for the class with the largest score to 1, and sets the scores for all other classes to ?1
                    % 'symmetriclogit'	2/(1 + e?x) ? 1
% 'Weights'观测权重－－－默认ones(size(x,1),1)
% 'CrossVal'是否要交叉验证－－－默认'off'| 'on'
% 'Holdout'－－－一部分训练，一部分测试 Example: 'Holdout',0.1
% 'KFold'－－－折数 默认10
% 'MaxNumSplits' －－－最大树枝数目 
% 'MinLeafSize' －－－最小叶子数 默认1
% 'numvariablestosample'－－－每个分支可选择的特征数 'all' (default)
% 'SplitCriterion' 分隔标准－－－'gdi' (default) | 'twoing' | 'deviance'   －－基尼系数／Twoing指标／交叉熵
% 'HyperparameterOptimizationOptions'－－－优化器选择 'HyperparameterOptimizationOptions',struct('MaxObjectiveEvaluations',60)

%% testing
load ionosphere
length=size(X,1);
rng(1);
indices = crossvalind('Kfold', length, 5);
i=1; 
test = (indices == i);
train = ~test;
X_train=X(train, :);
Y_train=Y(train, :);
X_test=X(test, :);
Y_test=Y(test, :);
Mdl = fitctree(X_train,Y_train)
rules_num=(Mdl.IsBranchNode==1);
rules_num=sum(rules_num);
view(Mdl,'Mode','graph');
lab=predict(Mdl,X_test);

%% [label,score,node,cnum] = predict(___) 
load fisheriris
n = size(meas,1);
rng(1) % For reproducibility
idxTrn = false(n,1);
idxTrn(randsample(n,round(0.5*n))) = true; % Training set logical indices
idxVal = idxTrn == false;   
Mdl = fitctree(meas(idxTrn,:),species(idxTrn));
[label,score,node,cnum] = predict(Mdl,meas(idxVal,:));
label(randsample(numel(label),5)) % Display several predicted labels
numMisclass = sum(~strcmp(label,species(idxVal)))
err_rate= numMisclass/length(label)
%'Subtrees' — Pruning level 修剪的级别 'all'是全修剪
% tree1 = prune(tree,'Level',1); 剪枝等级
% view(tree1,'Mode','Graph')
[~,Posterior] = predict(Mdl,meas(idxVal,:),'SubTrees',[1 3]);
Mdl.ClassNames

%% [E,SE,Nleaf,BestLevel] = cvloss(tree)
% E分类错误率 SE标准误差 Nleaf叶子个数 BestLevel树的最佳修剪级别
load ionosphere
tree = fitctree(X,Y);
% [E,SE,Nleaf,BestLevel] = cvloss(tree)
[E,SE,Nleaf,BestLevel] = cvloss(tree,'TreeSize','se','KFold' ,10)

%% 寻找最佳剪枝
load ionosphere
Mdl = fitctree(X,Y);
view(Mdl,'Mode','graph')
rng(1); % For reproducibility
m = max(Mdl.PruneList) - 1
[E,~,~,bestLevel] = cvloss(Mdl,'SubTrees',0:m,'KFold',5)
MdlPrune = prune(Mdl,'Level',bestLevel);
view(MdlPrune,'Mode','graph')



