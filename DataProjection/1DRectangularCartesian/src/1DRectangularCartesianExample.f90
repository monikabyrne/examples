!> Main program
PROGRAM DataProjection1DRectangularCartesian

  USE MPI
  USE OPENCMISS

#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Program parameters
  INTEGER(CMISSIntg),PARAMETER :: BasisUserNumber=1  
  INTEGER(CMISSIntg),PARAMETER :: CoordinateSystemDimension=3
  INTEGER(CMISSIntg),PARAMETER :: CoordinateSystemUserNumber=1
  INTEGER(CMISSIntg),PARAMETER :: DecompositionUserNumber=1
  INTEGER(CMISSIntg),PARAMETER :: FieldUserNumber=1  
  INTEGER(CMISSIntg),PARAMETER :: MeshUserNumber=1
  INTEGER(CMISSIntg),PARAMETER :: RegionUserNumber=1

  REAL(CMISSDP), PARAMETER :: CoordinateSystemOrigin(3)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/)  
  !Program types

  !Program variables   
  INTEGER(CMISSIntg) :: MeshComponentNumber=1
  INTEGER(CMISSIntg) :: MeshDimensions=1
  INTEGER(CMISSIntg) :: MeshNumberOfElements
  INTEGER(CMISSIntg) :: MeshNumberOfComponents=1
  INTEGER(CMISSIntg) :: NumberOfDomains=2
  INTEGER(CMISSIntg) :: NumberOfNodes
  INTEGER(CMISSIntg) :: NumberOfXi=1
  INTEGER(CMISSIntg) :: BasisInterpolation(1)=(/CMISSBasisCubicHermiteInterpolation/)
  INTEGER(CMISSIntg) :: WorldCoordinateSystemUserNumber
  INTEGER(CMISSIntg) :: WorldRegionUserNumber
  
  INTEGER(CMISSIntg) :: FieldNumberOfVariables=1
  INTEGER(CMISSIntg) :: FieldNumberOfComponents=3 
  

  INTEGER(CMISSIntg) :: np,el,xi,der_idx,node_idx,comp_idx
    
  REAL(CMISSDP), DIMENSION(5,3) :: DataPointValues !(number_of_data_points,dimension)
  INTEGER(CMISSIntg), DIMENSION(5,2) :: ElementUserNodes  
  REAL(CMISSDP), DIMENSION(2,6,3) :: FieldValues
        
#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

  !Generic CMISS and MPI variables
  INTEGER(CMISSIntg) :: Err
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_X_ELEMENTS=1 !<number of elements on x axis
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_Y_ELEMENTS=1 !<number of elements on y axis
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_Z_ELEMENTS=1 !<number of elements on z axis  
  INTEGER(CMISSIntg) :: NUMBER_OF_DOMAINS=1      
  INTEGER(CMISSIntg) :: MPI_IERROR  
  
#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif
    
  !Intialise data points
  DataPointValues(1,:)=(/20.5_CMISSDP,1.8_CMISSDP,0.0_CMISSDP/)
  DataPointValues(2,:)=(/33.2_CMISSDP,-4.8_CMISSDP,0.0_CMISSDP/)  
  DataPointValues(3,:)=(/9.6_CMISSDP,10.0_CMISSDP,0.0_CMISSDP/)  
  DataPointValues(4,:)=(/50.0_CMISSDP,-3.0_CMISSDP,6.0_CMISSDP/)  
  DataPointValues(5,:)=(/44.0_CMISSDP,10.0_CMISSDP,18.6_CMISSDP/)  
  
  ElementUserNodes(1,:)=(/1,2/)
  ElementUserNodes(2,:)=(/2,3/)
  ElementUserNodes(3,:)=(/3,4/)
  ElementUserNodes(4,:)=(/4,5/)
  ElementUserNodes(5,:)=(/5,6/)        
  
  FieldValues(1,1,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !no der, node 1
  FieldValues(2,1,:)=(/10.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !first der, node 1
  
  FieldValues(1,2,:)=(/10.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !no der, node 2
  FieldValues(2,2,:)=(/10.0_CMISSDP,-10.0_CMISSDP,0.0_CMISSDP/) !first der, node 2
  
  FieldValues(1,3,:)=(/20.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !no der, node 3
  FieldValues(2,3,:)=(/10.0_CMISSDP,20.0_CMISSDP,0.0_CMISSDP/) !first der, node 3
  
  FieldValues(1,4,:)=(/30.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !no der, node 4
  FieldValues(2,4,:)=(/10.0_CMISSDP,10.0_CMISSDP,0.0_CMISSDP/) !first der, node 4
  
  FieldValues(1,5,:)=(/40.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !no der, node 5
  FieldValues(2,5,:)=(/10.0_CMISSDP,-15.0_CMISSDP,0.0_CMISSDP/) !first der, node 5
  
  FieldValues(1,6,:)=(/50.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !no der, node 6
  FieldValues(2,6,:)=(/10.0_CMISSDP,-5.0_CMISSDP,0.0_CMISSDP/) !first der, node 6
  
  !Intialise cmiss
  CALL CMISSInitialise(WorldCoordinateSystemUserNumber,WorldRegionUserNumber,Err)
  !Broadcast the number of Elements in the X & Y directions and the number of partitions to the other computational nodes
  CALL MPI_BCAST(NUMBER_GLOBAL_X_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_BCAST(NUMBER_GLOBAL_Y_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_BCAST(NUMBER_GLOBAL_Z_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_BCAST(NUMBER_OF_DOMAINS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)

  !=========================================================================================================================
  !Create RC coordinate system
  CALL CMISSCoordinateSystemCreateStart(CoordinateSystemUserNumber,Err)
  CALL CMISSCoordinateSystemTypeSet(CoordinateSystemUserNumber,CMISSCoordinateRectangularCartesianType,Err)
  CALL CMISSCoordinateSystemDimensionSet(CoordinateSystemUserNumber,CoordinateSystemDimension,Err)
  CALL CMISSCoordinateSystemOriginSet(CoordinateSystemUserNumber,CoordinateSystemOrigin,Err)
  CALL CMISSCoordinateSystemCreateFinish(CoordinateSystemUserNumber,Err) 

  !=========================================================================================================================
  !Create Region and set CS to newly created 3D RC CS
  CALL CMISSRegionCreateStart(RegionUserNumber,WorldRegionUserNumber,Err)
  CALL CMISSRegionCoordinateSystemSet(RegionUserNumber,CoordinateSystemUserNumber,Err)
  CALL CMISSRegionCreateFinish(RegionUserNumber,Err)
    
  !=========================================================================================================================
  !Create Data Points and set the values
  CALL CMISSDataPointsCreateStart(RegionUserNumber,SIZE(DataPointValues,1),Err)
  DO np=1,SIZE(DataPointValues,1)
    CALL CMISSDataPointsValuesSet(RegionUserNumber,np,DataPointValues(np,:),Err)     
  ENDDO
  CALL CMISSDataPointsCreateFinish(RegionUserNumber,Err)  
  !=========================================================================================================================
  !Define basis function - 1D cubic hermite
  CALL CMISSBasisCreateStart(BasisUserNumber,Err)
  CALL CMISSBasisTypeSet(BasisUserNumber,CMISSBasisLagrangeHermiteTPType,Err)
  CALL CMISSBasisNumberOfXiSet(BasisUserNumber,NumberOfXi,Err)
  CALL CMISSBasisInterpolationXiSet(BasisUserNumber,BasisInterpolation,Err)
  CALL CMISSBasisCreateFinish(BasisUserNumber,Err)  
  !=========================================================================================================================
  !Create a mesh
  MeshNumberOfElements=SIZE(ElementUserNodes,1)
  CALL CMISSMeshCreateStart(MeshUserNumber,RegionUserNumber,MeshDimensions,Err)
  CALL CMISSMeshNumberOfComponentsSet(RegionUserNumber,MeshUserNumber,MeshNumberOfComponents,Err)
  CALL CMISSMeshNumberOfElementsSet(RegionUserNumber,MeshUserNumber,MeshNumberOfElements,Err)
  !define nodes for the mesh
  NumberOfNodes=SIZE(FieldValues,2)
  CALL CMISSNodesCreateStart(RegionUserNumber,NumberOfNodes,Err)
  CALL CMISSNodesCreateFinish(RegionUserNumber,Err)  
  !define elements for the mesh
  CALL CMISSMeshElementsCreateStart(RegionUserNumber,MeshUserNumber,MeshComponentNumber,BasisUserNumber,Err)
  Do el=1,MeshNumberOfElements
    CALL CMISSMeshElementsNodesSet(RegionUserNumber,MeshUserNumber,MeshComponentNumber,el,ElementUserNodes(el,:),Err)
  ENDDO
  CALL CMISSMeshElementsCreateFinish(RegionUserNumber,MeshUserNumber,MeshComponentNumber,Err)
  CALL CMISSMeshCreateFinish(RegionUserNumber,MeshUserNumber,Err)
  !=========================================================================================================================
  !Create a mesh decomposition 
  CALL CMISSDecompositionCreateStart(DecompositionUserNumber,RegionUserNumber,MeshUserNumber,Err)
  CALL CMISSDecompositionTypeSet(RegionUserNumber,MeshUserNumber,DecompositionUserNumber,CMISSDecompositionCalculatedType,Err)
  CALL CMISSDecompositionNumberOfDomainsSet(RegionUserNumber,MeshUserNumber,DecompositionUserNumber,NumberOfDomains,Err)
  CALL CMISSDecompositionCreateFinish(RegionUserNumber,MeshUserNumber,DecompositionUserNumber,Err)
  
  !=========================================================================================================================
  !Create a field to put the geometry
  CALL CMISSFieldCreateStart(FieldUserNumber,RegionUserNumber,Err)
  CALL CMISSFieldMeshDecompositionSet(RegionUserNumber,FieldUserNumber,MeshUserNumber,DecompositionUserNumber,Err)
  CALL CMISSFieldTypeSet(RegionUserNumber,FieldUserNumber,CMISSFieldGeometricType,Err)
  CALL CMISSFieldNumberOfVariablesSet(RegionUserNumber,FieldUserNumber,FieldNumberOfVariables,Err)
  CALL CMISSFieldNumberOfComponentsSet(RegionUserNumber,FieldUserNumber,CMISSFieldUVariableType,FieldNumberOfComponents,Err)
  DO xi=1,NumberOfXi
    CALL CMISSFieldComponentMeshComponentSet(RegionUserNumber,FieldUserNumber,CMISSFieldUVariableType,xi,xi,Err)
  ENDDO !xi    
  CALL CMISSFieldCreateFinish(RegionUserNumber,FieldUserNumber,Err)
  !node 1
  DO der_idx=1,SIZE(FieldValues,1)
    DO node_idx=1,SIZE(FieldValues,2)
      DO comp_idx=1,SIZE(FieldValues,3)
        CALL CMISSFieldParameterSetUpdateNode(RegionUserNumber,FieldUserNumber,CMISSFieldUVariableType,CMISSFieldValuesSetType, &
          & der_idx,node_idx,comp_idx,FieldValues(der_idx,node_idx,comp_idx),Err)
      ENDDO
    ENDDO
  ENDDO
  
  !=========================================================================================================================
  !Create a data projection
  
  CALL CMISSDataProjectionCreateStart(RegionUserNumber,FieldUserNumber,RegionUserNumber,Err)
  CALL CMISSDataProjectionCreateFinish(RegionUserNumber,Err)
  
  !=========================================================================================================================
  !Start data projection
  CALL CMISSDataProjectionEvaluate(RegionUserNumber,Err)
  
  !=========================================================================================================================
  !Destroy used types
  CALL CMISSDataProjectionDestroy(RegionUserNumber,Err)
  CALL CMISSDataPointsDestroy(RegionUserNumber,Err)
    
  CALL CMISSRegionDestroy(RegionUserNumber,Err)
  CALL CMISSCoordinateSystemDestroy(CoordinateSystemUserNumber,Err)  
  
  !=========================================================================================================================
  !Finishing program
  CALL CMISSFinalise(Err)
  WRITE(*,'(A)') "Program successfully completed."
  STOP  
  
END PROGRAM DataProjection1DRectangularCartesian
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  