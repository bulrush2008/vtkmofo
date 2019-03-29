SUBMODULE (vtk_attributes) vtk_attributes_implementation
    USE Precision
    USE Misc, ONLY : def_len
    IMPLICIT NONE
    !! author: Ian Porter
    !! date: 12/13/2017
    !!
    !! This module contains the dataset attributes for vtk format
    !!
    !! The following dataset attributes are available:
    !! 1) scalars
    !! 2) vectors
    !! 3) normals
    !! 4) texture coordinates (1D, 2D & 3D)
    !! 5) 3x3 tensors
    !! 6) field data
    !!
    !! Possible data types:
    !! bit, unsigned_char, char, unsigned_short, short, unsigned_int, int,
    !! unsigned_long, long, float, or double.
    CHARACTER(LEN=*), PARAMETER :: default = 'default'     !! Default table name

    CONTAINS

        MODULE PROCEDURE abs_read_formatted
        !! author: Ian Porter
        !! date: 03/25/2019
        !!
        !! Deferred procedure for formatted read
        !!
        CHARACTER(LEN=def_len) :: line

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE DEFAULT
            ERROR STOP 'Should not be in abs_read_formatted. This procedure is only here b/c Intel requires it'
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
        END SELECT

100     FORMAT((a))
        END PROCEDURE abs_read_formatted

        MODULE PROCEDURE abs_read_unformatted
        !! author: Ian Porter
        !! date: 03/25/2019
        !!
        !! Deferred procedure for unformatted read
        !!
        CHARACTER(LEN=def_len) :: line

        ERROR STOP 'Should not be in abs_read_unformatted. This procedure is only here b/c Intel requires it'
        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
100     FORMAT((a))
        END PROCEDURE abs_read_unformatted

        MODULE PROCEDURE abs_write_formatted
        !! author: Ian Porter
        !! date: 03/25/2019
        !!
        !! Deferred procedure for formatted write
        !!
        CHARACTER(LEN=def_len) :: line

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE DEFAULT
            ERROR STOP 'Should not be in abs_write_formatted. This procedure is only here b/c Intel requires it'
        END SELECT

        WRITE(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
100     FORMAT((a))
        END PROCEDURE abs_write_formatted

        MODULE PROCEDURE abs_write_unformatted
        !! author: Ian Porter
        !! date: 03/25/2019
        !!
        !! Deferred procedure for unformatted write
        !!
        CHARACTER(LEN=def_len) :: line

        ERROR STOP 'Should not be in abs_write_unformatted. This procedure is only here b/c Intel requires it'
        WRITE(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
100     FORMAT((a))
        END PROCEDURE abs_write_unformatted

        MODULE PROCEDURE initialize
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Abstract for performing the set-up of an attribute
        !!
        INTEGER(i4k) :: my_numcomp
        CHARACTER(LEN=:), ALLOCATABLE :: my_datatype, my_tablename

        IF (PRESENT(datatype)) THEN
            my_datatype = datatype
        ELSE IF (PRESENT(ints1d)) THEN
            my_datatype = 'int'
        ELSE
            my_datatype = 'double'
        END IF
        SELECT TYPE (me)
        CLASS IS (scalar)
            IF (PRESENT(numcomp)) THEN
                my_numcomp = numcomp
            ELSE
                my_numcomp = 1
            END IF
            IF (PRESENT(tablename)) THEN
                my_tablename = tablename
            ELSE
                my_tablename = default
            END IF
            CALL me%setup(dataname, my_datatype, my_numcomp, my_tablename, ints1d, values1d)
        CLASS IS (vector)
            CALL me%setup(dataname, datatype, values2d)
        CLASS IS (normal)
            CALL me%setup(dataname, datatype, values2d)
        CLASS IS (texture)
            CALL me%setup(dataname, datatype, values2d)
        CLASS IS (tensor)
            CALL me%setup(dataname, datatype, values3d)
        CLASS IS (field)
            CALL me%setup(dataname, datatype, field_arrays)
        CLASS DEFAULT
            ERROR STOP 'Generic class not defined for vtkmofo class attribute'
        END SELECT

        END PROCEDURE initialize

        MODULE PROCEDURE check_for_diffs
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Function checks for differences in an attribute
        !!
        diffs = .FALSE.
        IF      (.NOT. SAME_TYPE_AS(me,you))  THEN
            diffs = .TRUE.
        ELSE IF (me%dataname /= you%dataname) THEN
            diffs = .TRUE.
        END IF

        END PROCEDURE check_for_diffs
!********
! Scalars
!********
        MODULE PROCEDURE scalar_read_formatted
        USE Misc, ONLY : interpret_string, to_lowercase
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the read for a scalar attribute
        !!
        INTEGER(i4k)           :: i
        LOGICAL                :: end_of_file
        CHARACTER(LEN=def_len) :: line
        INTEGER(i4k),     DIMENSION(:), ALLOCATABLE :: ints
        REAL(r8k),        DIMENSION(:), ALLOCATABLE :: reals, dummy
        CHARACTER(LEN=:), DIMENSION(:), ALLOCATABLE :: chars

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line

            CALL interpret_string (line=line, datatype=[ 'C','C','I' ], ignore='SCALARS ', separator=' ', &
              &                    ints=ints, chars=chars)
            me%numcomp = ints(1); me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2))
            DEALLOCATE(ints)

            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line

            CALL interpret_string (line=line, datatype=[ 'C' ], ignore='LOOKUP_TABLE ', separator=' ', chars=chars)
            me%tablename = TRIM(chars(1))

            me%datatype = to_lowercase(me%datatype)
            SELECT CASE (me%datatype)
            CASE ('unsigned_int', 'int')
                ALLOCATE(me%ints(0))
            CASE ('float', 'double')
                ALLOCATE(me%reals(0))
            CASE DEFAULT
                ERROR STOP 'datatype not supported in scalar_read'
            END SELECT

            i = 0
            get_scalars: DO
                READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                end_of_file = (is_iostat_end(iostat))
                IF (end_of_file) THEN
                    EXIT get_scalars
                ELSE IF (TRIM(line) == '') THEN
                    CYCLE     !! Skip blank lines
                ELSE
                    SELECT CASE (TRIM(me%datatype))
                    CASE ('unsigned_int', 'int')
                        ALLOCATE(ints(1:UBOUND(me%ints,DIM=1)+1),source=0_i4k)
                        IF (i > 0) ints(1:UBOUND(me%ints,DIM=1)) = me%ints
                        CALL MOVE_ALLOC(ints, me%ints)
                        i = i + 1

                        CALL interpret_string (line=line, datatype=[ 'I' ], separator=' ', ints=ints)
                        me%ints(i) = ints(1)
                        DEALLOCATE(ints)
                    CASE ('float', 'double')
                        ALLOCATE(dummy(1:UBOUND(me%reals,DIM=1)+1),source=0.0_r8k)
                        IF (i > 0) dummy(1:UBOUND(me%reals,DIM=1)) = me%reals
                        CALL MOVE_ALLOC(dummy, me%reals)
                        i = i + 1

                        CALL interpret_string (line=line, datatype=[ 'R' ], separator=' ', reals=reals)
                        me%reals(i) = reals(1)
                    CASE DEFAULT
                        ERROR STOP 'datatype not supported in scalar_read'
                    END SELECT
                END IF
            END DO get_scalars
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in scalar_read_formatted'
        END SELECT

100     FORMAT((a))
        END PROCEDURE scalar_read_formatted

        MODULE PROCEDURE scalar_read_unformatted
        USE Misc, ONLY : interpret_string, to_lowercase
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the read for a scalar attribute
        !!
        INTEGER(i4k)           :: i
        LOGICAL                :: end_of_file
        CHARACTER(LEN=def_len) :: line
        INTEGER(i4k),     DIMENSION(:), ALLOCATABLE :: ints
        REAL(r8k),        DIMENSION(:), ALLOCATABLE :: reals, dummy
        CHARACTER(LEN=:), DIMENSION(:), ALLOCATABLE :: chars

        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
write(0,*) 'line= ',line
        CALL interpret_string (line=line, datatype=[ 'C','C','I' ], ignore='SCALARS ', separator=' ', &
          &                    ints=ints, chars=chars)
        me%numcomp = ints(1); me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2))
        DEALLOCATE(ints)

        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line

        CALL interpret_string (line=line, datatype=[ 'C' ], ignore='LOOKUP_TABLE ', separator=' ', chars=chars)
        me%tablename = TRIM(chars(1))

        me%datatype = to_lowercase(me%datatype)
        write(0,*) 'me%datatype= ',me%datatype
        SELECT CASE (me%datatype)
        CASE ('unsigned_int', 'int')
            ALLOCATE(me%ints(0))
        CASE ('float', 'double')
            ALLOCATE(me%reals(0))
        CASE DEFAULT
            ERROR STOP 'datatype not supported in scalar_read'
        END SELECT

        i = 0

        get_scalars: DO
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            end_of_file = (is_iostat_end(iostat))
            IF (end_of_file) THEN
                EXIT get_scalars
            ELSE IF (TRIM(line) == '') THEN
                CYCLE     !! Skip blank lines
            ELSE
                SELECT CASE (me%datatype)
                CASE ('unsigned_int', 'int')
                    ALLOCATE(ints(1:UBOUND(me%ints,DIM=1)+1),source=0_i4k)
                    IF (i > 0) ints(1:UBOUND(me%ints,DIM=1)) = me%ints
                    CALL MOVE_ALLOC(ints, me%ints)
                    i = i + 1

                    CALL interpret_string (line=line, datatype=[ 'I' ], separator=' ', ints=ints)
                    me%ints(i) = ints(1)
                    DEALLOCATE(ints)
                CASE ('float', 'double')
                    ALLOCATE(dummy(1:UBOUND(me%reals,DIM=1)+1),source=0.0_r8k)
                    IF (i > 0) dummy(1:UBOUND(me%reals,DIM=1)) = me%reals
                    CALL MOVE_ALLOC(dummy, me%reals)
                    i = i + 1

                    CALL interpret_string (line=line, datatype=[ 'R' ], separator=' ', reals=reals)
                    me%reals(i) = reals(1)
                CASE DEFAULT
                    ERROR STOP 'datatype not supported in scalar_read'
                END SELECT
            END IF
        END DO get_scalars

100     FORMAT((a))
        END PROCEDURE scalar_read_unformatted

        MODULE PROCEDURE scalar_write_formatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a scalar attribute
        !!
        INTEGER(i4k) :: i

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, me%datatype, me%numcomp, new_line('(a)')
            WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, me%datatype, me%numcomp, new_line('(a)')
            WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%tablename, new_line('a')
            IF (ALLOCATED(me%reals)) THEN
                DO i = 1, SIZE(me%reals)
                    WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) me%reals(i), new_line('a')
                END DO
            ELSE IF (ALLOCATED(me%ints)) THEN
                DO i = 1, SIZE(me%ints)
                    WRITE(unit,103,IOSTAT=iostat,IOMSG=iomsg) me%ints(i), new_line('a')
                END DO
            ELSE
                ERROR STOP 'Neither real or integer arrays are allocated for scalar_write'
            END IF
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in scalar_write_formatted'
        END SELECT

100     FORMAT('SCALARS ',(a),' ',(a),' ',(i1),(a))
101     FORMAT('LOOKUP_TABLE ',(a),(a))
102     FORMAT(es13.6,(a))
103     FORMAT(i0,(a))

        END PROCEDURE scalar_write_formatted

        MODULE PROCEDURE scalar_write_unformatted
        !! author: Ian Porter
        !! date: 2/11/2018
        !!
        !! Subroutine performs the unformatted write for a scalar attribute
        !!
        INTEGER(i4k) :: i

!        WRITE(unit) 'SCALARS ' // me%dataname // ', ' // me%datatype // ', ' // me%numcomp
        WRITE(unit,IOSTAT=iostat,IOMSG=iomsg) 'LOOKUP_TABLE ' // me%tablename // new_line('a')
        IF (ALLOCATED(me%reals)) THEN
            DO i = 1, SIZE(me%reals)
!                WRITE(unit,102) me%reals(i)
WRITE(unit,IOSTAT=iostat,IOMSG=iomsg) me%reals(i)
                WRITE(unit,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
            END DO
        ELSE IF (ALLOCATED(me%ints)) THEN
            DO i = 1, SIZE(me%ints)
                WRITE(unit,103,IOSTAT=iostat,IOMSG=iomsg) me%ints(i)
                WRITE(unit,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
            END DO
        ELSE
            ERROR STOP 'Neither real or integer arrays are allocated for scalar_write'
        END IF

!100     FORMAT('SCALARS ',(a),' ',(a),' ',(i1),/)
!101     FORMAT('LOOKUP_TABLE ',(a),/)
102     FORMAT(es13.6,/)
103     FORMAT(i0,/)

        END PROCEDURE scalar_write_unformatted

        MODULE PROCEDURE scalar_setup
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the set-up for a scalar attribute
        !!
        me%dataname = dataname
        me%datatype = datatype
        me%numcomp = numcomp
        me%tablename = tablename
        SELECT CASE (datatype)
        CASE ('int')
            IF (.NOT. PRESENT(ints1d) .OR. .NOT. (SIZE(ints1d) > 0)) THEN
                ERROR STOP 'Must have input array of integers. Terminated in scalar_setup'
            END IF
            me%ints = ints1d
        CASE ('double')
            IF (.NOT. PRESENT(values1d) .OR. .NOT. (SIZE(values1d) > 0)) THEN
                ERROR STOP 'Must have input array of reals. Terminated in scalar_setup'
            END IF
            me%reals = values1d
        CASE DEFAULT
            ERROR STOP 'Unsupported datatype in scalar_setup'
        END SELECT

        END PROCEDURE scalar_setup

        MODULE PROCEDURE check_for_diffs_scalar
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Function checks for differences in a scalar attribute
        !!
        INTEGER(i4k) :: i

        diffs = .FALSE.
        IF (.NOT. SAME_TYPE_AS(me,you)) THEN
            diffs = .TRUE.
        ELSE
            SELECT TYPE (you)
            CLASS IS (scalar)
                IF (me%dataname /= you%dataname)        THEN
                    diffs = .TRUE.
                ELSE IF (me%datatype /= you%datatype)   THEN
                    diffs = .TRUE.
                ELSE IF (me%numcomp /= you%numcomp)     THEN
                    diffs = .TRUE.
                ELSE IF (me%tablename /= you%tablename) THEN
                    diffs = .TRUE.
                ELSE IF (ALLOCATED(me%reals))           THEN
                    IF (SIZE(me%reals) /= SIZE(you%reals)) THEN
                        diffs = .TRUE.
                    ELSE
                        DO i = 1, UBOUND(me%reals,DIM=1)
                            IF (me%reals(i) /= you%reals(i))THEN
                                diffs = .TRUE.
                            END IF
                        END DO
                    END IF
                ELSE IF (ALLOCATED(me%ints))            THEN
                    IF (SIZE(me%ints) /= SIZE(you%ints)) THEN
                        diffs = .TRUE.
                    ELSE
                        DO i = 1, UBOUND(me%ints,DIM=1)
                            IF (me%ints(i) /= you%ints(i))THEN
                                diffs = .TRUE.
                            END IF
                        END DO
                    END IF
                END IF
            END SELECT
        END IF

        END PROCEDURE check_for_diffs_scalar
!********
! Vectors
!********
        MODULE PROCEDURE vector_read_formatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a vector attribute
        !!
        INTEGER(i4k)            :: i
        INTEGER(i4k), PARAMETER :: dim = 3
        LOGICAL                 :: end_of_file
        CHARACTER(LEN=def_len)  :: line
        REAL(r8k),        DIMENSION(:),   ALLOCATABLE :: reals
        CHARACTER(LEN=:), DIMENSION(:),   ALLOCATABLE :: chars
        REAL(r8k),        DIMENSION(:,:), ALLOCATABLE :: dummy

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            CALL interpret_string (line=line, datatype=[ 'C','C' ], ignore='VECTORS ', separator=' ', chars=chars)
            me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2))

            ALLOCATE(me%vectors(0,0)); i = 0

            get_vectors: DO
                READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                end_of_file = (is_iostat_end(iostat))
                IF (end_of_file) THEN
                    EXIT get_vectors
                ELSE IF (TRIM(line) == '') THEN
                    CYCLE     !! Skip blank lines
                ELSE
                    ALLOCATE(dummy(1:dim,1:UBOUND(me%vectors,DIM=2)+1),source=0.0_r8k)
                    IF (i > 0) dummy(1:dim,1:UBOUND(me%vectors,DIM=2)) = me%vectors
                    CALL MOVE_ALLOC(dummy, me%vectors)
                    i = i + 1

                    CALL interpret_string (line=line, datatype=[ 'R','R','R' ], separator=' ', reals=reals)
                    me%vectors(1:dim,i) = reals(1:dim)
                END IF
            END DO get_vectors
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in vector_read_formatted'
        END SELECT

100     FORMAT((a))
        END PROCEDURE vector_read_formatted

        MODULE PROCEDURE vector_read_unformatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a vector attribute
        !!
        INTEGER(i4k)            :: i
        INTEGER(i4k), PARAMETER :: dim = 3
        LOGICAL                 :: end_of_file
        CHARACTER(LEN=def_len)  :: line
        REAL(r8k),        DIMENSION(:),   ALLOCATABLE :: reals
        CHARACTER(LEN=:), DIMENSION(:),   ALLOCATABLE :: chars
        REAL(r8k),        DIMENSION(:,:), ALLOCATABLE :: dummy

        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
        CALL interpret_string (line=line, datatype=[ 'C','C' ], ignore='VECTORS ', separator=' ', chars=chars)
        me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2))

        ALLOCATE(me%vectors(0,0)); i = 0

        get_vectors: DO
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            end_of_file = (is_iostat_end(iostat))
            IF (end_of_file) THEN
                EXIT get_vectors
            ELSE IF (TRIM(line) == '') THEN
                CYCLE     !! Skip blank lines
            ELSE
                ALLOCATE(dummy(1:dim,1:UBOUND(me%vectors,DIM=2)+1),source=0.0_r8k)
                IF (i > 0) dummy(1:dim,1:UBOUND(me%vectors,DIM=2)) = me%vectors
                CALL MOVE_ALLOC(dummy, me%vectors)
                i = i + 1

                CALL interpret_string (line=line, datatype=[ 'R','R','R' ], separator=' ', reals=reals)
                me%vectors(1:dim,i) = reals(1:dim)
            END IF
        END DO get_vectors

100     FORMAT((a))
        END PROCEDURE vector_read_unformatted

        MODULE PROCEDURE vector_write_formatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a vector attribute
        !!
        INTEGER(i4k) :: i

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, me%datatype, new_line('a')
            DO i = 1, SIZE(me%vectors,DIM=2)
                WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%vectors(1:3,i)
                WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
            END DO
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in vector_write_formatted'
        END SELECT

100     FORMAT('VECTORS ',(a),' ',(a),(a))
101     FORMAT(*(es13.6,' '))
102     FORMAT((a))
        END PROCEDURE vector_write_formatted

        MODULE PROCEDURE vector_write_unformatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a vector attribute
        !!
        INTEGER(i4k) :: i

        WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, me%datatype, new_line('a')
        DO i = 1, SIZE(me%vectors,DIM=2)
            WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%vectors(1:3,i)
            WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
        END DO

100     FORMAT('VECTORS ',(a),' ',(a),(a))
101     FORMAT(*(es13.6,' '))
102     FORMAT((a))
        END PROCEDURE vector_write_unformatted

        MODULE PROCEDURE vector_setup
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the set-up for a vector attribute
        !!
        me%dataname = dataname
        IF (PRESENT(datatype)) THEN
            me%datatype = datatype
        ELSE
            me%datatype = 'double'
        END IF
        me%vectors = values2d

        END PROCEDURE vector_setup

        MODULE PROCEDURE check_for_diffs_vector
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Function checks for differences in a vector attribute
        !!
        INTEGER(i4k) :: i, j

        diffs = .FALSE.
        IF (.NOT. SAME_TYPE_AS(me,you)) THEN
            diffs = .TRUE.
        ELSE
            SELECT TYPE (you)
            CLASS IS (vector)
                IF (me%dataname /= you%dataname)        THEN
                    diffs = .TRUE.
                ELSE IF (me%datatype /= you%datatype)   THEN
                    diffs = .TRUE.
                ELSE IF (SIZE(me%vectors,DIM=1) /= SIZE(you%vectors,DIM=1)) THEN
                     diffs = .TRUE.
                ELSE IF (SIZE(me%vectors,DIM=2) /= SIZE(you%vectors,DIM=2)) THEN
                     diffs = .TRUE.
                ELSE
                    DO i = 1, UBOUND(me%vectors,DIM=1)
                        DO j = 1, UBOUND(me%vectors,DIM=2)
                            IF (me%vectors(i,j) /= you%vectors(i,j))     THEN
                                diffs = .TRUE.
                            END IF
                        END DO
                    END DO
                END IF
            END SELECT
        END IF

        END PROCEDURE check_for_diffs_vector
!********
! Normals
!********
        MODULE PROCEDURE normal_read_formatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a normal attribute
        !!
        INTEGER(i4k)            :: i
        INTEGER(i4k), PARAMETER :: dim = 3
        LOGICAL                 :: end_of_file
        CHARACTER(LEN=def_len)  :: line
        REAL(r8k),        DIMENSION(:),   ALLOCATABLE :: reals
        CHARACTER(LEN=:), DIMENSION(:),   ALLOCATABLE :: chars
        REAL(r8k),        DIMENSION(:,:), ALLOCATABLE :: dummy

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            CALL interpret_string (line=line, datatype=[ 'C','C' ], ignore='NORMALS ', separator=' ', chars=chars)
            me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2))

            ALLOCATE(me%normals(0,0)); i = 0

            get_normals: DO
                READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                end_of_file = (is_iostat_end(iostat))
                IF (end_of_file) THEN
                    EXIT get_normals
                ELSE IF (TRIM(line) == '') THEN
                    CYCLE     !! Skip blank lines
                ELSE
                    ALLOCATE(dummy(1:dim,1:UBOUND(me%normals,DIM=2)+1),source=0.0_r8k)
                    IF (i > 0) dummy(1:dim,1:UBOUND(me%normals,DIM=2)) = me%normals
                    CALL MOVE_ALLOC(dummy, me%normals)
                    i = i + 1

                    CALL interpret_string (line=line, datatype=[ 'R','R','R' ], separator=' ', reals=reals)
                    me%normals(1:dim,i) = reals(1:dim)
                END IF
            END DO get_normals
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in normal_read_formatted'
        END SELECT

100     FORMAT((a))
        END PROCEDURE normal_read_formatted

        MODULE PROCEDURE normal_read_unformatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a normal attribute
        !!
        INTEGER(i4k)            :: i
        INTEGER(i4k), PARAMETER :: dim = 3
        LOGICAL                 :: end_of_file
        CHARACTER(LEN=def_len)  :: line
        REAL(r8k),        DIMENSION(:),   ALLOCATABLE :: reals
        CHARACTER(LEN=:), DIMENSION(:),   ALLOCATABLE :: chars
        REAL(r8k),        DIMENSION(:,:), ALLOCATABLE :: dummy

        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
        CALL interpret_string (line=line, datatype=[ 'C','C' ], ignore='NORMALS ', separator=' ', chars=chars)
        me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2))

        ALLOCATE(me%normals(0,0)); i = 0

        get_normals: DO
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            end_of_file = (is_iostat_end(iostat))
            IF (end_of_file) THEN
                EXIT get_normals
            ELSE IF (TRIM(line) == '') THEN
                CYCLE     !! Skip blank lines
            ELSE
                ALLOCATE(dummy(1:dim,1:UBOUND(me%normals,DIM=2)+1),source=0.0_r8k)
                IF (i > 0) dummy(1:dim,1:UBOUND(me%normals,DIM=2)) = me%normals
                CALL MOVE_ALLOC(dummy, me%normals)
                i = i + 1

                CALL interpret_string (line=line, datatype=[ 'R','R','R' ], separator=' ', reals=reals)
                me%normals(1:dim,i) = reals(1:dim)
            END IF
        END DO get_normals

100     FORMAT((a))
        END PROCEDURE normal_read_unformatted

        MODULE PROCEDURE normal_write_formatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a normal attribute
        !!
        INTEGER(i4k) :: i

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, me%datatype, new_line('a')
            DO i = 1, SIZE(me%normals,DIM=2)
                WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%normals(1:3,i)
                WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
            END DO
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in normal_write_formatted'
        END SELECT

100     FORMAT('NORMALS ',(a),' ',(a),(a))
101     FORMAT(*(es13.6,' '))
102     FORMAT((a))
        END PROCEDURE normal_write_formatted

        MODULE PROCEDURE normal_write_unformatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a normal attribute
        !!
        INTEGER(i4k) :: i

        WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, me%datatype, new_line('a')
        DO i = 1, SIZE(me%normals,DIM=2)
            WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%normals(1:3,i)
            WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
        END DO

100     FORMAT('NORMALS ',(a),' ',(a),(a))
101     FORMAT(*(es13.6,' '))
102     FORMAT((a))
        END PROCEDURE normal_write_unformatted

        MODULE PROCEDURE normal_setup
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the set-up for a normal attribute
        !!
        me%dataname = dataname
        IF (PRESENT(datatype)) THEN
            me%datatype = datatype
        ELSE
            me%datatype = 'double'
        END IF
        me%normals = values2d

        END PROCEDURE normal_setup

        MODULE PROCEDURE check_for_diffs_normal
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Function checks for differences in a normal attribute
        !!
        INTEGER(i4k) :: i, j

        diffs = .FALSE.
        IF (.NOT. SAME_TYPE_AS(me,you)) THEN
            diffs = .TRUE.
        ELSE
            SELECT TYPE (you)
            CLASS IS (normal)
                IF (me%dataname /= you%dataname)        THEN
                    diffs = .TRUE.
                ELSE IF (me%datatype /= you%datatype)   THEN
                    diffs = .TRUE.
                ELSE IF (SIZE(me%normals,DIM=1) /= SIZE(you%normals,DIM=1)) THEN
                     diffs = .TRUE.
                ELSE IF (SIZE(me%normals,DIM=2) /= SIZE(you%normals,DIM=2)) THEN
                     diffs = .TRUE.
                ELSE
                    DO i = 1, UBOUND(me%normals,DIM=1)
                        DO j = 1, UBOUND(me%normals,DIM=2)
                            IF (me%normals(i,j) /= you%normals(i,j))     THEN
                                diffs = .TRUE.
                            END IF
                        END DO
                    END DO
                END IF
            END SELECT
        END IF

        END PROCEDURE check_for_diffs_normal
!*********
! Textures
!*********
        MODULE PROCEDURE texture_read_formatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a texture attribute
        !!
        INTEGER(i4k)           :: i, dim
        LOGICAL                :: end_of_file
        CHARACTER(LEN=def_len) :: line
        INTEGER(i4k),     DIMENSION(:),   ALLOCATABLE :: ints
        REAL(r8k),        DIMENSION(:),   ALLOCATABLE :: reals
        CHARACTER(LEN=:), DIMENSION(:),   ALLOCATABLE :: chars
        REAL(r8k),        DIMENSION(:,:), ALLOCATABLE :: dummy
        CHARACTER(LEN=1), DIMENSION(3),   PARAMETER   :: datatype = [ 'R','R','R' ]

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            CALL interpret_string (line=line, datatype=[ 'C','I','C' ], ignore='TEXTURE_COORDINATES ', separator=' ', &
              &                    ints=ints, chars=chars)
            me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2)); dim = ints(1)

            ALLOCATE(me%textures(0,0)); i = 0

            get_textures: DO
                READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                end_of_file = (is_iostat_end(iostat))
                IF (end_of_file) THEN
                    EXIT get_textures
                ELSE IF (TRIM(line) == '') THEN
                    CYCLE     !! Skip blank lines
                ELSE
                    ALLOCATE(dummy(1:dim,1:UBOUND(me%textures,DIM=2)+1),source=0.0_r8k)
                    IF (i > 0) dummy(1:dim,1:UBOUND(me%textures,DIM=2)) = me%textures
                    CALL MOVE_ALLOC(dummy, me%textures)
                    i = i + 1

                    CALL interpret_string (line=line, datatype=datatype(1:dim), separator=' ', reals=reals)
                    me%textures(1:dim,i) = reals(1:dim)
                END IF
            END DO get_textures
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in texture_read_formatted'
        END SELECT

100     FORMAT((a))
        END PROCEDURE texture_read_formatted

        MODULE PROCEDURE texture_read_unformatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a texture attribute
        !!
        INTEGER(i4k)           :: i, dim
        LOGICAL                :: end_of_file
        CHARACTER(LEN=def_len) :: line
        INTEGER(i4k),     DIMENSION(:),   ALLOCATABLE :: ints
        REAL(r8k),        DIMENSION(:),   ALLOCATABLE :: reals
        CHARACTER(LEN=:), DIMENSION(:),   ALLOCATABLE :: chars
        REAL(r8k),        DIMENSION(:,:), ALLOCATABLE :: dummy
        CHARACTER(LEN=1), DIMENSION(3),   PARAMETER   :: datatype = [ 'R','R','R' ]

        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
        CALL interpret_string (line=line, datatype=[ 'C','I','C' ], ignore='TEXTURE_COORDINATES ', separator=' ', &
          &                    ints=ints, chars=chars)
        me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2)); dim = ints(1)

        ALLOCATE(me%textures(0,0)); i = 0

        get_textures: DO
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            end_of_file = (is_iostat_end(iostat))
            IF (end_of_file) THEN
                EXIT get_textures
            ELSE IF (TRIM(line) == '') THEN
                CYCLE     !! Skip blank lines
            ELSE
                ALLOCATE(dummy(1:dim,1:UBOUND(me%textures,DIM=2)+1),source=0.0_r8k)
                IF (i > 0) dummy(1:dim,1:UBOUND(me%textures,DIM=2)) = me%textures
                CALL MOVE_ALLOC(dummy, me%textures)
                i = i + 1

                CALL interpret_string (line=line, datatype=datatype(1:dim), separator=' ', reals=reals)
                me%textures(1:dim,i) = reals(1:dim)
            END IF
        END DO get_textures

100     FORMAT((a))
        END PROCEDURE texture_read_unformatted

        MODULE PROCEDURE texture_write_formatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a texture attribute
        !!
        INTEGER(i4k) :: i

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, SIZE(me%textures,DIM=2), me%datatype, new_line('a')
            DO i = 1, SIZE(me%textures,DIM=2)
                WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%textures(:,i)
                WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
            END DO
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in texture_write_formatted'
        END SELECT

100     FORMAT('TEXTURE_COORDINATES ',(a),' ',(i1),' ',(a),(a))
101     FORMAT(*(es13.6,' '))
102     FORMAT((a))
        END PROCEDURE texture_write_formatted

        MODULE PROCEDURE texture_write_unformatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a texture attribute
        !!
        INTEGER(i4k) :: i

        WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, SIZE(me%textures,DIM=2), me%datatype, new_line('a')
        DO i = 1, SIZE(me%textures,DIM=2)
            WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%textures(:,i)
            WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
        END DO

100     FORMAT('TEXTURE_COORDINATES ',(a),' ',(i1),' ',(a),(a))
101     FORMAT(*(es13.6,' '))
102     FORMAT((a))
        END PROCEDURE texture_write_unformatted

        MODULE PROCEDURE texture_setup
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the set-up for a texture attribute
        !!
        me%dataname = dataname
        IF (PRESENT(datatype)) THEN
            me%datatype = datatype
        ELSE
            me%datatype = 'double'
        END IF
        me%textures = values2d

        END PROCEDURE texture_setup

        MODULE PROCEDURE check_for_diffs_texture
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Function checks for differences in a texture attribute
        !!
        INTEGER(i4k) :: i, j

        diffs = .FALSE.
        IF (.NOT. SAME_TYPE_AS(me,you)) THEN
            diffs = .TRUE.
        ELSE
            SELECT TYPE (you)
            CLASS IS (texture)
                IF (me%dataname /= you%dataname)        THEN
                    diffs = .TRUE.
                ELSE IF (me%datatype /= you%datatype)   THEN
                    diffs = .TRUE.
                ELSE IF (SIZE(me%textures,DIM=1) /= SIZE(you%textures,DIM=1)) THEN
                     diffs = .TRUE.
                ELSE IF (SIZE(me%textures,DIM=2) /= SIZE(you%textures,DIM=2)) THEN
                     diffs = .TRUE.
                ELSE
                    DO i = 1, UBOUND(me%textures,DIM=1)
                        DO j = 1, UBOUND(me%textures,DIM=2)
                            IF (me%textures(i,j) /= you%textures(i,j))     THEN
                                diffs = .TRUE.
                            END IF
                        END DO
                    END DO
                END IF
            END SELECT
        END IF

        END PROCEDURE check_for_diffs_texture
!********
! Tensors
!********
        MODULE PROCEDURE tensor_read_formatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a tensor attribute
        !!
        INTEGER(i4k)           :: i, j
        LOGICAL                :: end_of_file
        CHARACTER(LEN=def_len) :: line
        REAL(r8k),          DIMENSION(:), ALLOCATABLE :: reals
        CHARACTER(LEN=:),   DIMENSION(:), ALLOCATABLE :: chars
        TYPE(tensor_array), DIMENSION(:), ALLOCATABLE :: dummy

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            CALL interpret_string (line=line, datatype=[ 'C','C' ], ignore='TENSORS ', separator=' ', &
              &                    chars=chars)
            me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2))

            ALLOCATE(me%tensors(0)); i = 0

            get_tensors: DO
                READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                end_of_file = (is_iostat_end(iostat))
                IF (end_of_file) THEN
                    EXIT get_tensors
                ELSE IF (TRIM(line) == '') THEN
                    CYCLE      !! Skip blank lines
                ELSE
                    ALLOCATE(dummy(1:UBOUND(me%tensors,DIM=1)+1))
                    dummy(1:UBOUND(me%tensors,DIM=1)) = me%tensors
                    CALL MOVE_ALLOC(dummy, me%tensors)
                    i = i + 1

                    DO j = 1, UBOUND(me%tensors(i)%val,DIM=1)
                        IF (j > 1) READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                        CALL interpret_string (line=line, datatype=[ 'R','R','R' ], separator=' ', reals=reals)
                        me%tensors(i)%val(1:3,j) = reals(1:3)
                    END DO

                END IF
            END DO get_tensors
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in tensor_read_formatted'
        END SELECT

100     FORMAT((a))
        END PROCEDURE tensor_read_formatted

        MODULE PROCEDURE tensor_read_unformatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a tensor attribute
        !!
        INTEGER(i4k)           :: i, j
        LOGICAL                :: end_of_file
        CHARACTER(LEN=def_len) :: line
        REAL(r8k),          DIMENSION(:), ALLOCATABLE :: reals
        CHARACTER(LEN=:),   DIMENSION(:), ALLOCATABLE :: chars
        TYPE(tensor_array), DIMENSION(:), ALLOCATABLE :: dummy

        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
        CALL interpret_string (line=line, datatype=[ 'C','C' ], ignore='TENSORS ', separator=' ', &
          &                    chars=chars)
        me%dataname = TRIM(chars(1)); me%datatype = TRIM(chars(2))

        ALLOCATE(me%tensors(0)); i = 0

        get_tensors: DO
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            end_of_file = (is_iostat_end(iostat))
            IF (end_of_file) THEN
                EXIT get_tensors
            ELSE IF (TRIM(line) == '') THEN
                CYCLE      !! Skip blank lines
            ELSE
                ALLOCATE(dummy(1:UBOUND(me%tensors,DIM=1)+1))
                dummy(1:UBOUND(me%tensors,DIM=1)) = me%tensors
                CALL MOVE_ALLOC(dummy, me%tensors)
                i = i + 1

                DO j = 1, UBOUND(me%tensors(i)%val,DIM=1)
                    IF (j > 1) READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                    CALL interpret_string (line=line, datatype=[ 'R','R','R' ], separator=' ', reals=reals)
                    me%tensors(i)%val(1:3,j) = reals(1:3)
                END DO

            END IF
        END DO get_tensors

100     FORMAT((a))
        END PROCEDURE tensor_read_unformatted

        MODULE PROCEDURE tensor_write_formatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a tensor attribute
        !!
        INTEGER(i4k) :: i, j
!        CHARACTER(LEN=:), ALLOCATABLE :: string_to_write

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, me%datatype, new_line('a')
            DO i = 1, SIZE(me%tensors,DIM=1)
                DO j = 1, SIZE(me%tensors(i)%val,DIM=2)
    !                ALLOCATE(string_to_write(1:14*SIZE(me%tensors(i)%val,DIM=2)))
    !                WRITE(string_to_write,101) me%tensors(i)%val(j,:)
    WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%tensors(i)%val(:,j)
    !                WRITE(unit,101) string_to_write, new_line('a')
                    WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
    !                DEALLOCATE(string_to_write)
                END DO
                WRITE(unit,102) new_line('a')
            END DO
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in tensor_write_formatted'
        END SELECT

100     FORMAT('TENSORS ',(a),' ',(a),(a))
101     FORMAT(*(es13.6,' '),(a))
102     FORMAT((a))
        END PROCEDURE tensor_write_formatted

        MODULE PROCEDURE tensor_write_unformatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a tensor attribute
        !!
        INTEGER(i4k) :: i, j
!        CHARACTER(LEN=:), ALLOCATABLE :: string_to_write

        WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, me%datatype, new_line('a')
        DO i = 1, SIZE(me%tensors,DIM=1)
            DO j = 1, SIZE(me%tensors(i)%val,DIM=2)
!                ALLOCATE(string_to_write(1:14*SIZE(me%tensors(i)%val,DIM=2)))
!                WRITE(string_to_write,101) me%tensors(i)%val(j,:)
WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%tensors(i)%val(:,j)
!                WRITE(unit,101) string_to_write, new_line('a')
                WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
!                DEALLOCATE(string_to_write)
            END DO
            WRITE(unit,102) new_line('a')
        END DO

100     FORMAT('TENSORS ',(a),' ',(a),(a))
101     FORMAT(*(es13.6,' '),(a))
102     FORMAT((a))
        END PROCEDURE tensor_write_unformatted

        MODULE PROCEDURE tensor_setup
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the set-up for a tensor attribute
        !!
        INTEGER(i4k) :: i

        me%dataname = dataname
        IF (PRESENT(datatype)) THEN
            me%datatype = datatype
        ELSE
            me%datatype = 'double'
        END IF
        IF (SIZE(values3d,DIM=2) /= 3 .OR. SIZE(values3d,DIM=3) /= 3) THEN
            ERROR STOP 'Tensors can only be 3x3'
        ELSE
            ALLOCATE(me%tensors(1:UBOUND(values3d,DIM=1)))
            DO i = 1, UBOUND(values3d,DIM=1)
                me%tensors(i)%val(1:3,1:3) = values3d(i,1:3,1:3)
            END DO
        END IF

        END PROCEDURE tensor_setup

        MODULE PROCEDURE check_for_diffs_tensor
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Function checks for differences in a tensor attribute
        !!
        INTEGER(i4k) :: i, j, k

        diffs = .FALSE.
        IF (.NOT. SAME_TYPE_AS(me,you)) THEN
            diffs = .TRUE.
        ELSE
            SELECT TYPE (you)
            CLASS IS (tensor)
                IF (me%dataname /= you%dataname)        THEN
                    diffs = .TRUE.
                ELSE IF (me%datatype /= you%datatype)   THEN
                    diffs = .TRUE.
                ELSE IF (SIZE(me%tensors,DIM=1) /= SIZE(you%tensors,DIM=1)) THEN
                     diffs = .TRUE.
                ELSE
                    DO i = 1, UBOUND(me%tensors,DIM=1)
                        IF (SIZE(me%tensors(i)%val,DIM=1) /= SIZE(you%tensors(i)%val,DIM=1)) THEN
                            diffs = .TRUE.
                        ELSE IF (SIZE(me%tensors(i)%val,DIM=2) /= SIZE(you%tensors(i)%val,DIM=2)) THEN
                            diffs = .TRUE.
                        ELSE
                            DO j = 1, UBOUND(me%tensors(i)%val,DIM=1)
                                DO k = 1, UBOUND(me%tensors(i)%val,DIM=2)
                                    IF (me%tensors(i)%val(j,k) /= you%tensors(i)%val(j,k)) THEN
                                        diffs = .TRUE.
                                    END IF
                                END DO
                            END DO
                        END IF
                    END DO
                END IF
            END SELECT
        END IF

        END PROCEDURE check_for_diffs_tensor
!********
! Fields
!********
        MODULE PROCEDURE field_read_formatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a field attribute
        !!
        INTEGER(i4k)                :: i, j, dim
        LOGICAL                     :: end_of_file
        CHARACTER(LEN=def_len)      :: line
        CHARACTER(LEN=*), PARAMETER :: real_char = 'R'
        REAL(r8k),        DIMENSION(:), ALLOCATABLE :: reals
        INTEGER(i4k),     DIMENSION(:), ALLOCATABLE :: ints
        CHARACTER(LEN=:), DIMENSION(:), ALLOCATABLE :: chars
        CHARACTER(LEN=1), DIMENSION(:), ALLOCATABLE :: datatype
!        TYPE(field_data_array), DIMENSION(:), ALLOCATABLE :: dummy

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            CALL interpret_string (line=line, datatype=[ 'C','I' ], ignore='FIELD ', separator=' ', &
              &                    ints=ints, chars=chars)
            me%dataname = TRIM(chars(1)); dim = ints(1)

            ALLOCATE(me%array(1:dim)); i = 0

            get_fields: DO
                READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                end_of_file = (is_iostat_end(iostat))
                IF (end_of_file) THEN
                    EXIT get_fields
                ELSE IF (TRIM(line) == '') THEN
                    CYCLE      !! Skip blank lines
                ELSE
    !                ALLOCATE(dummy(1:UBOUND(me%array,DIM=1)))
    !                dummy(1:UBOUND(me%array,DIM=1)) = me%array
    !                CALL MOVE_ALLOC(dummy, me%array)
                    i = i + 1

                    CALL interpret_string (line=line, datatype=[ 'C','I','I','C' ], separator=' ', chars=chars, ints=ints)
                    me%array(i)%name = TRIM(chars(1)); me%array(i)%numComponents = ints(1)
                    me%array(i)%numTuples = ints(2); me%array(i)%datatype = chars(2)
                    ALLOCATE(datatype(1:me%array(i)%numComponents),source=real_char)
                    ALLOCATE(me%array(i)%data(1:me%array(i)%numComponents,1:me%array(i)%numTuples),source=0.0_r8k)

                    DO j = 1, me%array(i)%numTuples
                        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                        CALL interpret_string (line=line, datatype=datatype, separator=' ', reals=reals)
                        me%array(i)%data(:,j) = reals(:)
                    END DO
                    DEALLOCATE(datatype)

                END IF
            END DO get_fields
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in field_read_formatted'
        END SELECT

100     FORMAT((a))
        END PROCEDURE field_read_formatted

        MODULE PROCEDURE field_read_unformatted
        USE Misc, ONLY : interpret_string
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the read for a field attribute
        !!
        INTEGER(i4k)                :: i, j, dim
        LOGICAL                     :: end_of_file
        CHARACTER(LEN=def_len)      :: line
        CHARACTER(LEN=*), PARAMETER :: real_char = 'R'
        REAL(r8k),        DIMENSION(:), ALLOCATABLE :: reals
        INTEGER(i4k),     DIMENSION(:), ALLOCATABLE :: ints
        CHARACTER(LEN=:), DIMENSION(:), ALLOCATABLE :: chars
        CHARACTER(LEN=1), DIMENSION(:), ALLOCATABLE :: datatype
!        TYPE(field_data_array), DIMENSION(:), ALLOCATABLE :: dummy

        READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
        CALL interpret_string (line=line, datatype=[ 'C','I' ], ignore='FIELD ', separator=' ', &
          &                    ints=ints, chars=chars)
        me%dataname = TRIM(chars(1)); dim = ints(1)

        ALLOCATE(me%array(1:dim)); i = 0

        get_fields: DO
            READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
            end_of_file = (is_iostat_end(iostat))
            IF (end_of_file) THEN
                EXIT get_fields
            ELSE IF (TRIM(line) == '') THEN
                CYCLE      !! Skip blank lines
            ELSE
!                ALLOCATE(dummy(1:UBOUND(me%array,DIM=1)))
!                dummy(1:UBOUND(me%array,DIM=1)) = me%array
!                CALL MOVE_ALLOC(dummy, me%array)
                i = i + 1

                CALL interpret_string (line=line, datatype=[ 'C','I','I','C' ], separator=' ', chars=chars, ints=ints)
                me%array(i)%name = TRIM(chars(1)); me%array(i)%numComponents = ints(1)
                me%array(i)%numTuples = ints(2); me%array(i)%datatype = chars(2)
                ALLOCATE(datatype(1:me%array(i)%numComponents),source=real_char)
                ALLOCATE(me%array(i)%data(1:me%array(i)%numComponents,1:me%array(i)%numTuples),source=0.0_r8k)

                DO j = 1, me%array(i)%numTuples
                    READ(unit,FMT=100,IOSTAT=iostat,IOMSG=iomsg) line
                    CALL interpret_string (line=line, datatype=datatype, separator=' ', reals=reals)
                    me%array(i)%data(:,j) = reals(:)
                END DO
                DEALLOCATE(datatype)

            END IF
        END DO get_fields

100     FORMAT((a))
        END PROCEDURE field_read_unformatted

        MODULE PROCEDURE field_write_formatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a field attribute
        !!
        INTEGER(i4k) :: i, j

        IF (SIZE(v_list) > 0) THEN
            !! At some point, do something with v_list
        END IF

        SELECT CASE (iotype)
        CASE ('DT')
            WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, SIZE(me%array,DIM=1), new_line('a')
            DO i = 1, SIZE(me%array,DIM=1)
                WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%array(i)%name, me%array(i)%numComponents, &
                  &                                        me%array(i)%numTuples, me%array(i)%datatype, new_line('a')
                DO j = 1, me%array(i)%numTuples
                    WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) me%array(i)%data(:,j)
                    WRITE(unit,103,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
                END DO
                WRITE(unit,103,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
            END DO
        CASE DEFAULT
            ERROR STOP 'iotype not supported. Terminated in field_write_formatted'
        END SELECT

100     FORMAT('FIELD ',(a),' ',(i0),(a))
101     FORMAT((a),' ',(i0),' ',(i0),' ',(a),(a))
102     FORMAT(*(es13.6,' '))
103     FORMAT((a))
        END PROCEDURE field_write_formatted

        MODULE PROCEDURE field_write_unformatted
        !! author: Ian Porter
        !! date: 12/13/2017
        !!
        !! Subroutine performs the write for a field attribute
        !!
        INTEGER(i4k) :: i, j

        WRITE(unit,100,IOSTAT=iostat,IOMSG=iomsg) me%dataname, SIZE(me%array,DIM=1), new_line('a')
        DO i = 1, SIZE(me%array,DIM=1)
            WRITE(unit,101,IOSTAT=iostat,IOMSG=iomsg) me%array(i)%name, me%array(i)%numComponents, &
              &                                        me%array(i)%numTuples, me%array(i)%datatype, new_line('a')
            DO j = 1, me%array(i)%numTuples
                WRITE(unit,102,IOSTAT=iostat,IOMSG=iomsg) me%array(i)%data(:,j)
                WRITE(unit,103,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
            END DO
            WRITE(unit,103,IOSTAT=iostat,IOMSG=iomsg) new_line('a')
        END DO

100     FORMAT('FIELD ',(a),' ',(i0),(a))
101     FORMAT((a),' ',(i0),' ',(i0),' ',(a),(a))
102     FORMAT(*(es13.6,' '))
103     FORMAT((a))
        END PROCEDURE field_write_unformatted

        MODULE PROCEDURE field_setup
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Subroutine performs the set-up for a field attribute
        !!
        me%dataname = dataname
        IF (PRESENT(datatype)) THEN
            me%datatype = datatype
        ELSE
            me%datatype = 'double'
        END IF
        me%array = field_arrays

        END PROCEDURE field_setup

        MODULE PROCEDURE check_for_diffs_field
        !! author: Ian Porter
        !! date: 12/14/2017
        !!
        !! Function checks for differences in a field attribute
        !!
        INTEGER(i4k) :: i, j, k

        diffs = .FALSE.
        IF (.NOT. SAME_TYPE_AS(me,you)) THEN
            diffs = .TRUE.
        ELSE
            SELECT TYPE (you)
            CLASS IS (field)
                IF      (me%dataname /= you%dataname) THEN
                    diffs = .TRUE.
                ELSE
                    DO i = 1, UBOUND(me%array,DIM=1)
                        IF      (me%array(i)%name          /= you%array(i)%name         ) THEN
                            diffs = .TRUE.
                        ELSE IF (me%array(i)%numComponents /= you%array(i)%numComponents) THEN
                            diffs = .TRUE.
                        ELSE IF (me%array(i)%numTuples     /= you%array(i)%numTuples    ) THEN
                            diffs = .TRUE.
                        ELSE IF (me%array(i)%datatype      /= you%array(i)%datatype     ) THEN
                            diffs = .TRUE.
                        ELSE
                            DO j = 1, UBOUND(me%array(i)%data,DIM=1)
                                DO k = 1, UBOUND(me%array(i)%data,DIM=2)
                                    IF (me%array(i)%data(j,k) /= me%array(i)%data(j,k)) THEN
                                        diffs = .TRUE.
                                    END IF
                                END DO
                            END DO
                        END IF
                    END DO
                END IF
            END SELECT
        END IF

        END PROCEDURE check_for_diffs_field

END SUBMODULE vtk_attributes_implementation
