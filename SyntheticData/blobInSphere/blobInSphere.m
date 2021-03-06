function [ X, Y ] = blobInSphere(nBlob, nSphere, d, Opts)

blobMu = 0;
if ~isfield(Opts,'blobSigma')
    Opts.blobSigma = 0.5;
end
blob = normrnd(blobMu,Opts.blobSigma,d,nBlob);
blobLabels = zeros(1,nBlob);

sphere = normrnd(0,1,d,nSphere);
lengths = sqrt(sum(sphere.^2));
sphereRadius = 3;
for i=1:nSphere
    % convert to unit vector and scale by sphere radius
    sphere(:,i) = sphereRadius*sphere(:,i)/lengths(i);
end
sphereMu = 0;
if ~isfield(Opts,'sphereSigma')
    Opts.sphereSigma = 0.02;
end
sphere = sphere + normrnd(sphereMu,Opts.sphereSigma,d,nSphere);
sphereLabels = ones(1,nSphere);

Y = horzcat(blobLabels, sphereLabels);
X = horzcat(blob, sphere);

end

