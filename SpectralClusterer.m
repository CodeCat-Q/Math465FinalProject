function [ Clusters, G,Times] = SpectralClusterer(X,Y,Opts)
%%X is the DxN input data. Y is a N element array of the true labels.
%Opts is an array of optional options as follows:
%       auto: boolean representing whether to use AutoTuneLaplacianBuilder to make
%            Laplacian graph. If not present, false.
%       LaplacianType: Specifies how to find eigenvalues of Laplacian:
%                      values: 'unnormalized', 'ng-normalized',
%                      'shi-normalized'
%       NumberNeighbors = number of neighbors to use for KNN
%       NumClusters =  number of clusters to segment data
%       NSDistance = distance metric. See knnsearch 'Distance' for options.
%                    defaults to 'Eucledian'   
%%

%=========================== Read the options =======================%
times = zeros(5,1);
Opts.times = times;

auto = 0;
if isfield(Opts, 'auto')
    auto = getfield(Opts, 'auto');
end
if auto
    G = AutoTuneLaplacianBuilder(X,Opts);
else
    [G,Opts] = LaplacianBuilder(X,Opts);
end
Clusters = {};

laplacianType = 'unnormalized';
if isfield(Opts, 'LaplacianType')
    laplacianType = getfield(Opts, 'LaplacianType');
end



%===================  Preform the spectral projection ====================%
tic
if strcmp(laplacianType,'shi-normalized')
     %[EigenVec,EigenVal] = eig(G.LRW);
     %Use eigs for speed increase
     [EigenVec,EigenVal] = eigs(G.LRW,Opts.NumClusters,'sm');
     EigenVec = fliplr(EigenVec);
     EigenVal = fliplr(EigenVal);
     U = EigenVec(:,1:Opts.NumClusters);
     
elseif strcmp(laplacianType,'ng-normalized')
     %Use eigs for speed increase
     %[EigenVec,EigenVal] = eig(G.LNormalized);
     [EigenVec,EigenVal] = eigs(G.LNormalized,Opts.NumClusters,'sm');
     T = EigenVec(:,1:Opts.NumClusters);
     for row = 1:length(T(:,1))
        T(row,:) = T(row,:)/norm(T(row,:));
     end
     U = T;
else 
    %[EigenVec,EigenVal] = eig(G.L); 
     [EigenVec,EigenVal] = eigs(G.L,Opts.NumClusters,'sm');
     %EigenVec = fliplr(EigenVec).*-1;
     %EigenVal = fliplr(EigenVal).*-1;
     U = EigenVec(:,1:Opts.NumClusters);
end

Opts.times(3) = toc;

%===========Compute the clusters on the projection with K-means=========%
tic
clusters = kmeans(U, Opts.NumClusters);
Opts.times(4) = toc;


%===========Combine the clusters if predominant label is the same=======%
tic
merged = zeros(Opts.NumClusters);
newClusters = zeros(length(clusters),1);
clusterPurities = ClusterPurity(clusters,Y, Opts.NumClusters);
nextClusterNum = 1;


for clusterNum = 1:Opts.NumClusters
    if merged(clusterNum)
        continue 
    end
    clusterLabel = clusterPurities(clusterNum,2);
    %Set that this cluster has been merged
    merged(clusterNum) = 1;
    relabel(clusterNum, nextClusterNum);
    for cluserTwoNum = clusterNum+1:Opts.NumClusters
        secondClusterLabel = clusterPurities(cluserTwoNum,2);
        if secondClusterLabel == clusterLabel
            relabel(cluserTwoNum, clusterNum);
            merged(cluserTwoNum) = 1;
        end
    end
    nextClusterNum = nextClusterNum +1;   
end


function relabel(oldCluster,newCluster)
    for c = 1:length(clusters)
        if(clusters(c) == oldCluster)
            newClusters(c) = newCluster;
        end
    end     
end


%Group the data into clusters
numClustersCollapsed = nextClusterNum -1;
clusterSets = cell(1,numClustersCollapsed);

for i = 1:length(newClusters)
    clusterSet =  clusterSets{1,newClusters(i)};
    clusterSets{1,newClusters(i)} = [clusterSet X(:,i)];
end

Opts.times(5) = toc;



Clusters.Merged = newClusters;
Clusters.Unmerged = clusters;
Clusters.Sets = clusterSets;
Clusters.G = G;
Clusters.U = U;
Times = Opts.times;
%Clusters.ClusterSets = clusterSet

end

