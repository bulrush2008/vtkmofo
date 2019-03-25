MODULE vtk_datasets
    USE Precision
    USE vtk_cells, ONLY : vtkcell, vtkcell_list
    IMPLICIT NONE
    !! author: Ian Porter
    !! date: 12/1/2017
    !!
    !! This module contains the dataset formats for vtk format
    !!
    !! The following dataset formats are available:
    !! 1) Structured points
    !! 2) Structured grid
    !! 3) Rectilinear grid
    !! 4) Polygonal data
    !! 5) Unstructured grid
    !!
    PRIVATE
    PUBLIC :: dataset, struct_pts, struct_grid, rectlnr_grid, polygonal_data, unstruct_grid

    TYPE :: coordinates
        CHARACTER(LEN=:),        ALLOCATABLE :: datatype
        REAL(r8k), DIMENSION(:), ALLOCATABLE :: coord
    END TYPE coordinates

    TYPE, ABSTRACT :: dataset
        !! Abstract DT of dataset information
        PRIVATE
        CHARACTER(LEN=:), ALLOCATABLE :: name
        CHARACTER(LEN=:), ALLOCATABLE :: datatype
        INTEGER(i4k), DIMENSION(3)    :: dimensions = [ 0, 0, 0 ]
        LOGICAL, PUBLIC               :: firstcall = .TRUE.
    CONTAINS
        PROCEDURE(abs_read_formatted),   DEFERRED, PRIVATE :: read_formatted
        PROCEDURE(abs_read_unformatted), DEFERRED, PRIVATE :: read_unformatted
        GENERIC, PUBLIC :: READ(FORMATTED)   => read_formatted
        GENERIC, PUBLIC :: READ(UNFORMATTED) => read_unformatted
        PROCEDURE(abs_write_formatted),   DEFERRED, PRIVATE :: write_formatted
        PROCEDURE(abs_write_unformatted), DEFERRED, PRIVATE :: write_unformatted
        GENERIC, PUBLIC :: WRITE(FORMATTED)   => write_formatted
        GENERIC, PUBLIC :: WRITE(UNFORMATTED) => write_unformatted
        PROCEDURE, NON_OVERRIDABLE, PUBLIC :: init
        PROCEDURE, PRIVATE :: check_for_diffs
        GENERIC, PUBLIC :: OPERATOR(.diff.) => check_for_diffs
    END TYPE dataset

    TYPE, EXTENDS(dataset) :: struct_pts
        !! Structured points
        PRIVATE
        REAL(r8k), DIMENSION(3) :: origin  = [ 0.0_r8k, 0.0_r8k, 0.0_r8k ]
        REAL(r8k), DIMENSION(3) :: spacing = [ 0.0_r8k, 0.0_r8k, 0.0_r8k ]
    CONTAINS
        PROCEDURE :: read_formatted    => struct_pts_read_formatted
        PROCEDURE :: read_unformatted  => struct_pts_read_unformatted
        PROCEDURE :: write_formatted   => struct_pts_write_formatted
        PROCEDURE :: write_unformatted => struct_pts_write_unformatted
        PROCEDURE, PRIVATE :: setup => struct_pts_setup
        PROCEDURE :: check_for_diffs => check_for_diffs_struct_pts
    END TYPE struct_pts

    TYPE, EXTENDS(dataset) :: struct_grid
        !! Structured grid
        PRIVATE
        INTEGER(i4k)                           :: n_points = 0
        REAL(r8k), DIMENSION(:,:), ALLOCATABLE :: points
    CONTAINS
        PROCEDURE :: read_formatted    => struct_grid_read_formatted
        PROCEDURE :: read_unformatted  => struct_grid_read_unformatted
        PROCEDURE :: write_formatted   => struct_grid_write_formatted
        PROCEDURE :: write_unformatted => struct_grid_write_unformatted
        PROCEDURE, PRIVATE :: setup => struct_grid_setup
        PROCEDURE :: check_for_diffs => check_for_diffs_struct_grid
    END TYPE struct_grid

    TYPE, EXTENDS(dataset) :: rectlnr_grid
        !! Rectilinear grid
        PRIVATE
        TYPE (coordinates) :: x
        TYPE (coordinates) :: y
        TYPE (coordinates) :: z
    CONTAINS
        PROCEDURE :: read_formatted    => rectlnr_grid_read_formatted
        PROCEDURE :: read_unformatted  => rectlnr_grid_read_unformatted
        PROCEDURE :: write_formatted   => rectlnr_grid_write_formatted
        PROCEDURE :: write_unformatted => rectlnr_grid_write_unformatted
        PROCEDURE, PRIVATE :: setup => rectlnr_grid_setup
        PROCEDURE :: check_for_diffs => check_for_diffs_rectlnr_grid
    END TYPE rectlnr_grid

    TYPE, EXTENDS(dataset) :: polygonal_data
        !! Polygonal data
        PRIVATE
        INTEGER(i4k)                                :: n_points = 0
        REAL(r8k),      DIMENSION(:,:), ALLOCATABLE :: points
        CLASS(vtkcell), DIMENSION(:),   ALLOCATABLE :: vertices
        CLASS(vtkcell), DIMENSION(:),   ALLOCATABLE :: lines
        CLASS(vtkcell), DIMENSION(:),   ALLOCATABLE :: polygons
        CLASS(vtkcell), DIMENSION(:),   ALLOCATABLE :: triangles
    CONTAINS
        PROCEDURE :: read_formatted    => polygonal_data_read_formatted
        PROCEDURE :: read_unformatted  => polygonal_data_read_unformatted
        PROCEDURE :: write_formatted   => polygonal_data_write_formatted
        PROCEDURE :: write_unformatted => polygonal_data_write_unformatted
        PROCEDURE, PRIVATE :: setup => polygonal_data_setup
    END TYPE polygonal_data

    TYPE, EXTENDS(dataset) :: unstruct_grid
        !! Unstructured grid
        PRIVATE
        INTEGER(i4k) :: n_points     = 0
        INTEGER(i4k) :: n_cells      = 0
        INTEGER(i4k) :: n_cell_types = 0
        INTEGER(i4k) :: size         = 0
        REAL(r8k),          DIMENSION(:,:), ALLOCATABLE :: points
        TYPE(vtkcell_list), DIMENSION(:),   ALLOCATABLE :: cell_list
    CONTAINS
        PROCEDURE :: read_formatted    => unstruct_grid_read_formatted
        PROCEDURE :: read_unformatted  => unstruct_grid_read_unformatted
        PROCEDURE :: write_formatted   => unstruct_grid_write_formatted
        PROCEDURE :: write_unformatted => unstruct_grid_write_unformatted
        PROCEDURE :: unstruct_grid_setup
        PROCEDURE :: unstruct_grid_setup_multiclass
        GENERIC, PRIVATE :: setup => unstruct_grid_setup, unstruct_grid_setup_multiclass
    END TYPE unstruct_grid

    INTERFACE
! ****************
! Abstract dataset
! ****************
        MODULE SUBROUTINE abs_read_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract read for formatted file
        !!
        CLASS(dataset),   INTENT(INOUT) :: me
        INTEGER(i4k),     INTENT(IN)    :: unit
        CHARACTER(LEN=*), INTENT(IN)    :: iotype
        INTEGER(i4k),     DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),     INTENT(OUT)   :: iostat
        CHARACTER(LEN=*), INTENT(INOUT) :: iomsg

        END SUBROUTINE abs_read_formatted

        MODULE SUBROUTINE abs_read_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract read for unformatted file
        !!
        CLASS(dataset),   INTENT(INOUT) :: me
        INTEGER(i4k),     INTENT(IN)    :: unit
        INTEGER(i4k),     INTENT(OUT)   :: iostat
        CHARACTER(LEN=*), INTENT(INOUT) :: iomsg

        END SUBROUTINE abs_read_unformatted

        MODULE SUBROUTINE abs_write_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract write for formatted file
        !!
        CLASS(dataset),   INTENT(IN)    :: me
        INTEGER(i4k),     INTENT(IN)    :: unit
        CHARACTER(LEN=*), INTENT(IN)    :: iotype
        INTEGER(i4k),     DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),     INTENT(OUT)   :: iostat
        CHARACTER(LEN=*), INTENT(INOUT) :: iomsg

        END SUBROUTINE abs_write_formatted

        MODULE SUBROUTINE abs_write_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract write for unformatted file
        !!
        CLASS(dataset),   INTENT(IN)    :: me
        INTEGER(i4k),     INTENT(IN)    :: unit
        INTEGER(i4k),     INTENT(OUT)   :: iostat
        CHARACTER(LEN=*), INTENT(INOUT) :: iomsg

        END SUBROUTINE abs_write_unformatted

        MODULE SUBROUTINE init (me, datatype, dims, origin, spacing, points, cells, cell_list, &
          &                     x_coords, y_coords, z_coords, vertices, lines, polygons, triangles)
        !! initializes the dataset
        CLASS (dataset),                     INTENT(OUT)          :: me
        CLASS(vtkcell),      DIMENSION(:),   INTENT(IN), OPTIONAL :: vertices
        CLASS(vtkcell),      DIMENSION(:),   INTENT(IN), OPTIONAL :: lines
        CLASS(vtkcell),      DIMENSION(:),   INTENT(IN), OPTIONAL :: polygons
        CLASS(vtkcell),      DIMENSION(:),   INTENT(IN), OPTIONAL :: triangles
        CLASS(vtkcell),      DIMENSION(:),   INTENT(IN), OPTIONAL :: cells      !! DT of same cell types
        TYPE(vtkcell_list),  DIMENSION(:),   INTENT(IN), OPTIONAL :: cell_list  !! DT of different cell types
        CHARACTER(LEN=*),                    INTENT(IN), OPTIONAL :: datatype   !! Type of data (floating, integer, etc.)
        INTEGER(i4k),        DIMENSION(3),   INTENT(IN), OPTIONAL :: dims
        REAL(r8k),           DIMENSION(3),   INTENT(IN), OPTIONAL :: origin
        REAL(r8k),           DIMENSION(3),   INTENT(IN), OPTIONAL :: spacing
        REAL(r8k),           DIMENSION(:),   INTENT(IN), OPTIONAL :: x_coords
        REAL(r8k),           DIMENSION(:),   INTENT(IN), OPTIONAL :: y_coords
        REAL(r8k),           DIMENSION(:),   INTENT(IN), OPTIONAL :: z_coords
        REAL(r8k),           DIMENSION(:,:), INTENT(IN), OPTIONAL :: points

        END SUBROUTINE init

        MODULE FUNCTION check_for_diffs (me, you) RESULT (diffs)
        !!
        !! Function checks for differences in a dataset
        !!
        CLASS(dataset), INTENT(IN) :: me, you
        LOGICAL :: diffs

        END FUNCTION check_for_diffs
! *****************
! Structured Points
! *****************
        MODULE SUBROUTINE struct_pts_read_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract read for formatted file
        !!
        CLASS(struct_pts), INTENT(INOUT) :: me
        INTEGER(i4k),      INTENT(IN)    :: unit
        CHARACTER(LEN=*),  INTENT(IN)    :: iotype
        INTEGER(i4k),      DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),      INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),  INTENT(INOUT) :: iomsg

        END SUBROUTINE struct_pts_read_formatted

        MODULE SUBROUTINE struct_pts_read_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract read for unformatted file
        !!
        CLASS(struct_pts), INTENT(INOUT) :: me
        INTEGER(i4k),      INTENT(IN)    :: unit
        INTEGER(i4k),      INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),  INTENT(INOUT) :: iomsg

        END SUBROUTINE struct_pts_read_unformatted

        MODULE SUBROUTINE struct_pts_write_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract write for formatted file
        !!
        CLASS(struct_pts), INTENT(IN)    :: me
        INTEGER(i4k),      INTENT(IN)    :: unit
        CHARACTER(LEN=*),  INTENT(IN)    :: iotype
        INTEGER(i4k),      DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),      INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),  INTENT(INOUT) :: iomsg

        END SUBROUTINE struct_pts_write_formatted

        MODULE SUBROUTINE struct_pts_write_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract write for unformatted file
        !!
        CLASS(struct_pts), INTENT(IN)    :: me
        INTEGER(i4k),      INTENT(IN)    :: unit
        INTEGER(i4k),      INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),  INTENT(INOUT) :: iomsg

        END SUBROUTINE struct_pts_write_unformatted

        MODULE SUBROUTINE struct_pts_setup (me, dims, origin, spacing)
        !!
        !! Sets up the structured points dataset with information
        CLASS (struct_pts),         INTENT(OUT) :: me
        INTEGER(i4k), DIMENSION(3), INTENT(IN)  :: dims
        REAL(r8k),    DIMENSION(3), INTENT(IN)  :: origin, spacing

        END SUBROUTINE struct_pts_setup

        MODULE FUNCTION check_for_diffs_struct_pts (me, you) RESULT (diffs)
        !!
        !! Function checks for differences in a structured points dataset
        CLASS(struct_pts), INTENT(IN) :: me
        CLASS(dataset),    INTENT(IN) :: you
        LOGICAL                       :: diffs

        END FUNCTION check_for_diffs_struct_pts
! ***************
! Structured Grid
! ***************
        MODULE SUBROUTINE struct_grid_read_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract read for formatted file
        !!
        CLASS(struct_grid), INTENT(INOUT) :: me
        INTEGER(i4k),       INTENT(IN)    :: unit
        CHARACTER(LEN=*),   INTENT(IN)    :: iotype
        INTEGER(i4k),       DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),       INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),   INTENT(INOUT) :: iomsg

        END SUBROUTINE struct_grid_read_formatted

        MODULE SUBROUTINE struct_grid_read_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract read for unformatted file
        !!
        CLASS(struct_grid), INTENT(INOUT) :: me
        INTEGER(i4k),       INTENT(IN)    :: unit
        INTEGER(i4k),       INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),   INTENT(INOUT) :: iomsg

        END SUBROUTINE struct_grid_read_unformatted

        MODULE SUBROUTINE struct_grid_write_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract write for formatted file
        !!
        CLASS(struct_grid), INTENT(IN)    :: me
        INTEGER(i4k),       INTENT(IN)    :: unit
        CHARACTER(LEN=*),   INTENT(IN)    :: iotype
        INTEGER(i4k),       DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),       INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),   INTENT(INOUT) :: iomsg

        END SUBROUTINE struct_grid_write_formatted

        MODULE SUBROUTINE struct_grid_write_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract write for unformatted file
        !!
        CLASS(struct_grid), INTENT(IN)    :: me
        INTEGER(i4k),       INTENT(IN)    :: unit
        INTEGER(i4k),       INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),   INTENT(INOUT) :: iomsg

        END SUBROUTINE struct_grid_write_unformatted

        MODULE SUBROUTINE struct_grid_setup (me, dims, points)
        !!
        !! Sets up the structured grid dataset with information
        CLASS (struct_grid),          INTENT(OUT) :: me
        INTEGER(i4k), DIMENSION(3),   INTENT(IN)  :: dims
        REAL(r8k),    DIMENSION(:,:), INTENT(IN)  :: points

        END SUBROUTINE struct_grid_setup

        MODULE FUNCTION check_for_diffs_struct_grid (me, you) RESULT (diffs)
        !!
        !! Function checks for differences in a structured grid dataset
        CLASS(struct_grid), INTENT(IN) :: me
        CLASS(dataset),     INTENT(IN) :: you
        LOGICAL                        :: diffs

        END FUNCTION check_for_diffs_struct_grid
! ****************
! Rectilinear Grid
! ****************
        MODULE SUBROUTINE rectlnr_grid_read_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract read for formatted file
        !!
        CLASS(rectlnr_grid), INTENT(INOUT) :: me
        INTEGER(i4k),        INTENT(IN)    :: unit
        CHARACTER(LEN=*),    INTENT(IN)    :: iotype
        INTEGER(i4k),        DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),        INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),    INTENT(INOUT) :: iomsg

        END SUBROUTINE rectlnr_grid_read_formatted

        MODULE SUBROUTINE rectlnr_grid_read_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract read for unformatted file
        !!
        CLASS(rectlnr_grid), INTENT(INOUT) :: me
        INTEGER(i4k),        INTENT(IN)    :: unit
        INTEGER(i4k),        INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),    INTENT(INOUT) :: iomsg

        END SUBROUTINE rectlnr_grid_read_unformatted

        MODULE SUBROUTINE rectlnr_grid_write_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract write for formatted file
        !!
        CLASS(rectlnr_grid), INTENT(IN)    :: me
        INTEGER(i4k),        INTENT(IN)    :: unit
        CHARACTER(LEN=*),    INTENT(IN)    :: iotype
        INTEGER(i4k),        DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),        INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),    INTENT(INOUT) :: iomsg

        END SUBROUTINE rectlnr_grid_write_formatted

        MODULE SUBROUTINE rectlnr_grid_write_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract write for unformatted file
        !!
        CLASS(rectlnr_grid), INTENT(IN)    :: me
        INTEGER(i4k),        INTENT(IN)    :: unit
        INTEGER(i4k),        INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),    INTENT(INOUT) :: iomsg

        END SUBROUTINE rectlnr_grid_write_unformatted

        MODULE SUBROUTINE rectlnr_grid_setup (me, dims, x_coords, y_coords, z_coords, datatype)
        !!
        !! Sets up the rectilinear grid dataset with information
        CLASS (rectlnr_grid),       INTENT(OUT) :: me         !! Rectilinear grid DT
        INTEGER(i4k), DIMENSION(3), INTENT(IN)  :: dims       !! # of dimensions in (x,y,z) direction
        REAL(r8k),    DIMENSION(:), INTENT(IN)  :: x_coords   !! X coordinates
        REAL(r8k),    DIMENSION(:), INTENT(IN)  :: y_coords   !! Y coordinates
        REAL(r8k),    DIMENSION(:), INTENT(IN)  :: z_coords   !! Z coordinates
        CHARACTER(LEN=*),           INTENT(IN)  :: datatype   !! Type of data (floating, integer, etc.)

        END SUBROUTINE rectlnr_grid_setup

        MODULE FUNCTION check_for_diffs_rectlnr_grid (me, you) RESULT (diffs)
        !!
        !! Function checks for differences in a rectilinear grid dataset
        CLASS(rectlnr_grid), INTENT(IN) :: me
        CLASS(dataset),      INTENT(IN) :: you
        LOGICAL                         :: diffs

        END FUNCTION check_for_diffs_rectlnr_grid
! **************
! Polygonal Data
! **************
        MODULE SUBROUTINE polygonal_data_read_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract read for formatted file
        !!
        CLASS(polygonal_data), INTENT(INOUT) :: me
        INTEGER(i4k),          INTENT(IN)    :: unit
        CHARACTER(LEN=*),      INTENT(IN)    :: iotype
        INTEGER(i4k),          DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),          INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),      INTENT(INOUT) :: iomsg

        END SUBROUTINE polygonal_data_read_formatted

        MODULE SUBROUTINE polygonal_data_read_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract read for unformatted file
        !!
        CLASS(polygonal_data), INTENT(INOUT) :: me
        INTEGER(i4k),          INTENT(IN)    :: unit
        INTEGER(i4k),          INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),      INTENT(INOUT) :: iomsg

        END SUBROUTINE polygonal_data_read_unformatted

        MODULE SUBROUTINE polygonal_data_write_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract write for formatted file
        !!
        CLASS(polygonal_data), INTENT(IN)    :: me
        INTEGER(i4k),          INTENT(IN)    :: unit
        CHARACTER(LEN=*),      INTENT(IN)    :: iotype
        INTEGER(i4k),          DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),          INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),      INTENT(INOUT) :: iomsg

        END SUBROUTINE polygonal_data_write_formatted

        MODULE SUBROUTINE polygonal_data_write_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract write for unformatted file
        !!
        CLASS(polygonal_data), INTENT(IN)    :: me
        INTEGER(i4k),          INTENT(IN)    :: unit
        INTEGER(i4k),          INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),      INTENT(INOUT) :: iomsg

        END SUBROUTINE polygonal_data_write_unformatted

        MODULE SUBROUTINE polygonal_data_setup (me, points, vertices, lines, polygons, triangles)
        !!
        !! Sets up the polygonal data dataset with information
        CLASS (polygonal_data),       INTENT(OUT)          :: me
        REAL(r8k),    DIMENSION(:,:), INTENT(IN)           :: points
        CLASS(vtkcell), DIMENSION(:), INTENT(IN), OPTIONAL :: vertices
        CLASS(vtkcell), DIMENSION(:), INTENT(IN), OPTIONAL :: lines
        CLASS(vtkcell), DIMENSION(:), INTENT(IN), OPTIONAL :: polygons
        CLASS(vtkcell), DIMENSION(:), INTENT(IN), OPTIONAL :: triangles

        END SUBROUTINE polygonal_data_setup
! *****************
! Unstructured Grid
! *****************
        MODULE SUBROUTINE unstruct_grid_read_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract read for formatted file
        !!
        CLASS(unstruct_grid), INTENT(INOUT) :: me
        INTEGER(i4k),         INTENT(IN)    :: unit
        CHARACTER(LEN=*),     INTENT(IN)    :: iotype
        INTEGER(i4k),         DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),         INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),     INTENT(INOUT) :: iomsg

        END SUBROUTINE unstruct_grid_read_formatted

        MODULE SUBROUTINE unstruct_grid_read_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract read for unformatted file
        !!
        CLASS(unstruct_grid), INTENT(INOUT) :: me
        INTEGER(i4k),         INTENT(IN)    :: unit
        INTEGER(i4k),         INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),     INTENT(INOUT) :: iomsg

        END SUBROUTINE unstruct_grid_read_unformatted

        MODULE SUBROUTINE unstruct_grid_write_formatted (me, unit, iotype, v_list, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/4/2019
        !!
        !! Abstract write for formatted file
        !!
        CLASS(unstruct_grid), INTENT(IN)    :: me
        INTEGER(i4k),         INTENT(IN)    :: unit
        CHARACTER(LEN=*),     INTENT(IN)    :: iotype
        INTEGER(i4k),         DIMENSION(:), INTENT(IN) :: v_list
        INTEGER(i4k),         INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),     INTENT(INOUT) :: iomsg

        END SUBROUTINE unstruct_grid_write_formatted

        MODULE SUBROUTINE unstruct_grid_write_unformatted (me, unit, iostat, iomsg)
        !! author: Ian Porter
        !! date: 3/25/2019
        !!
        !! Abstract write for unformatted file
        !!
        CLASS(unstruct_grid), INTENT(IN)    :: me
        INTEGER(i4k),         INTENT(IN)    :: unit
        INTEGER(i4k),         INTENT(OUT)   :: iostat
        CHARACTER(LEN=*),     INTENT(INOUT) :: iomsg

        END SUBROUTINE unstruct_grid_write_unformatted

        MODULE SUBROUTINE unstruct_grid_setup (me, points, cells)
        !! Sets up the unstructured grid dataset with information for a single class of cells
        !!
        CLASS(unstruct_grid),           INTENT(OUT) :: me      !! DT
        REAL(r8k),      DIMENSION(:,:), INTENT(IN)  :: points  !!
        CLASS(vtkcell), DIMENSION(:),   INTENT(IN)  :: cells   !! DT of same cell types

        END SUBROUTINE unstruct_grid_setup

        MODULE SUBROUTINE unstruct_grid_setup_multiclass (me, points, cell_list)
        !! Sets up the unstructured grid dataset with information for a list of different classes of cells
        !!
        CLASS(unstruct_grid),               INTENT(OUT) :: me         !! DT
        REAL(r8k),          DIMENSION(:,:), INTENT(IN)  :: points     !!
        TYPE(vtkcell_list), DIMENSION(:),   INTENT(IN)  :: cell_list  !! DT of different cell types

        END SUBROUTINE unstruct_grid_setup_multiclass

    END INTERFACE

END MODULE vtk_datasets
