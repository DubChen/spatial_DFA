#' @export
Rotate_Fn = function( L_pj, Psi, RotationMethod="Varimax", testcutoff=1e-10 ){

  # Local functions
  approx_equal = function(m1,m2,d=1e-10) (2*abs(m1-m2)/mean(m1+m2)) < d
  trunc_machineprec = function(n) ifelse(n<1e-10,0,n)
  Nknots = dim(Psi)[1]
  Nfactors = dim(Psi)[2]

  # Varimax
  if( RotationMethod=="Varimax" ){
    Hinv = varimax( L_pj, normalize=FALSE )
      L_pj_rot = L_pj %*% Hinv$rotmat
    Psi_rot = array(NA, dim=dim(Psi))
    for( n in 1:Nknots ) Psi_rot[n,,] = solve(Hinv$rotmat) %*% Psi[n,,]
  }

  # PCA
  if( RotationMethod=="PCA" ){
    Eigen = eigen(L_pj%*%t(L_pj))
    Eigen$values_proportion = Eigen$values / sum(Eigen$values)
    Eigen$values_cumulative_proportion = cumsum(Eigen$values) / sum(Eigen$values)
    # Check decomposition
    #all(approx_equal( Eigen$vectors%*%diag(Eigen$values)%*%t(Eigen$vectors), L_pj%*%t(L_pj)))
    # My attempt at new loadings matrix
    L_pj_rot = (Eigen$vectors%*%diag(sqrt(trunc_machineprec(Eigen$values))))[,1:Nfactors,drop=FALSE]
    rownames(L_pj_rot) = rownames(L_pj)
    # My new factors
    Hinv = list("rotmat"=corpcor::pseudoinverse(L_pj_rot)%*%L_pj)
    Psi_rot = array(NA, dim=dim(Psi))
    if(length(dim(Psi_rot))==3) for( n in 1:Nknots ) Psi_rot[n,,] = Hinv$rotmat %*% Psi[n,,]
    if(length(dim(Psi_rot))==2) for( n in 1:Nknots ) Psi_rot[n,] = Hinv$rotmat %*% Psi[n,]
  }

  # Check for errors
  # Check covariance matrix
    # Should be identical for rotated and unrotated
  if( !is.na(testcutoff) ){
    if( !all(approx_equal(L_pj%*%t(L_pj),L_pj_rot%*%t(L_pj_rot), d=testcutoff)) ) stop("Covariance matrix is changed by rotation")
    # Check linear predictor
      # Should give identical predictions as unrotated
    for(i in 1:dim(Psi)[[1]]){
    for(j in 1:dim(Psi)[[length(dim(Psi))]]){
      if( !all(approx_equal(L_pj%*%Psi[i,,j],L_pj_rot%*%Psi_rot[i,,j], d=testcutoff)) ) stop(paste0("Linear predictor is wrong for site ",i," and time ",j))
    }}
    # Check rotation matrix
      # Should be orthogonal (R %*% transpose = identity matrix) with determinant one
      # Doesn't have det(R) = 1; determinant(Hinv$rotmat)!=1 ||
    if( !all(approx_equal(Hinv$rotmat%*%t(Hinv$rotmat),diag(Nfactors), d=testcutoff)) ) stop("Rotation matrix is not a rotation")
  }

  # Return stuff
  Return = list( "L_pj_rot"=L_pj_rot, "Psi_rot"=Psi_rot, "Hinv"=Hinv )
  if(RotationMethod=="PCA") Return[["Eigen"]] = Eigen
  return( Return )
}
