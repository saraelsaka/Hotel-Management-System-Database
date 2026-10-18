/* =========================================================
   HOTEL MANAGEMENT SYSTEM
   SQL Server
   Run this script in a development database environment.
   ========================================================= */

IF DB_ID(N'HotelManagementSystem') IS NULL
BEGIN
    CREATE DATABASE HotelManagementSystem;
END;
GO

USE HotelManagementSystem;
GO

/* =========================================================
   1. ROLES AND USERS
   ========================================================= */

IF OBJECT_ID(N'dbo.Roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Roles
    (
        RoleID INT IDENTITY(1,1) CONSTRAINT PK_Roles PRIMARY KEY,
        RoleName NVARCHAR(30) NOT NULL
            CONSTRAINT UQ_Roles_RoleName UNIQUE
    );
END;
GO

IF OBJECT_ID(N'dbo.Users', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Users
    (
        UserID INT IDENTITY(1,1) CONSTRAINT PK_Users PRIMARY KEY,
        FullName NVARCHAR(100) NOT NULL,
        Email NVARCHAR(254) NOT NULL
            CONSTRAINT UQ_Users_Email UNIQUE,
        PasswordHash NVARCHAR(255) NOT NULL,
        RoleID INT NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Users_IsActive DEFAULT (1),
        CreatedAt DATETIME2(0) NOT NULL
            CONSTRAINT DF_Users_CreatedAt DEFAULT (SYSDATETIME()),

        CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleID)
            REFERENCES dbo.Roles(RoleID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Admin')
    INSERT INTO dbo.Roles (RoleName) VALUES (N'Admin');
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Receptionist')
    INSERT INTO dbo.Roles (RoleName) VALUES (N'Receptionist');
IF NOT EXISTS (SELECT 1 FROM dbo.Roles WHERE RoleName = N'Manager')
    INSERT INTO dbo.Roles (RoleName) VALUES (N'Manager');
GO

/* PasswordHash must contain a securely generated hash from the application.
   Never store plain-text passwords. */

/* =========================================================
   2. GUESTS
   ========================================================= */

IF OBJECT_ID(N'dbo.Guests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Guests
    (
        GuestID INT IDENTITY(1,1) CONSTRAINT PK_Guests PRIMARY KEY,
        FirstName NVARCHAR(50) NOT NULL,
        LastName NVARCHAR(50) NOT NULL,
        Email NVARCHAR(254) NULL,
        PhoneNumber NVARCHAR(20) NOT NULL,
        CreatedAt DATETIME2(0) NOT NULL
            CONSTRAINT DF_Guests_CreatedAt DEFAULT (SYSDATETIME()),

        CONSTRAINT CK_Guests_Email_NotEmpty
            CHECK (Email IS NULL OR LEN(LTRIM(RTRIM(Email))) > 0)
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Guests')
      AND name = N'UX_Guests_Email'
)
BEGIN
    CREATE UNIQUE INDEX UX_Guests_Email
        ON dbo.Guests(Email)
        WHERE Email IS NOT NULL;
END;
GO

/* =========================================================
   3. ROOM TYPES
   ========================================================= */

IF OBJECT_ID(N'dbo.RoomTypes', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.RoomTypes
    (
        RoomTypeID INT IDENTITY(1,1) CONSTRAINT PK_RoomTypes PRIMARY KEY,
        TypeName NVARCHAR(50) NOT NULL
            CONSTRAINT UQ_RoomTypes_TypeName UNIQUE,
        Description NVARCHAR(500) NULL,
        BasePricePerNight DECIMAL(10,2) NOT NULL,
        Capacity INT NOT NULL,

        CONSTRAINT CK_RoomTypes_BasePrice CHECK (BasePricePerNight > 0),
        CONSTRAINT CK_RoomTypes_Capacity CHECK (Capacity > 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.RoomTypes WHERE TypeName = N'Single')
    INSERT INTO dbo.RoomTypes (TypeName, Description, BasePricePerNight, Capacity)
    VALUES (N'Single', N'Single occupancy room', 50.00, 1);

IF NOT EXISTS (SELECT 1 FROM dbo.RoomTypes WHERE TypeName = N'Double')
    INSERT INTO dbo.RoomTypes (TypeName, Description, BasePricePerNight, Capacity)
    VALUES (N'Double', N'Double occupancy room', 80.00, 2);

IF NOT EXISTS (SELECT 1 FROM dbo.RoomTypes WHERE TypeName = N'Suite')
    INSERT INTO dbo.RoomTypes (TypeName, Description, BasePricePerNight, Capacity)
    VALUES (N'Suite', N'Suite room', 150.00, 4);
GO

/* =========================================================
   4. ROOMS
   ========================================================= */

IF OBJECT_ID(N'dbo.Rooms', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Rooms
    (
        RoomID INT IDENTITY(1,1) CONSTRAINT PK_Rooms PRIMARY KEY,
        RoomNumber NVARCHAR(10) NOT NULL
            CONSTRAINT UQ_Rooms_RoomNumber UNIQUE,
        RoomTypeID INT NOT NULL,
        PricePerNight DECIMAL(10,2) NOT NULL,
        RoomStatus NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Rooms_RoomStatus DEFAULT (N'Active'),
        CreatedAt DATETIME2(0) NOT NULL
            CONSTRAINT DF_Rooms_CreatedAt DEFAULT (SYSDATETIME()),

        CONSTRAINT CK_Rooms_Price CHECK (PricePerNight > 0),
        CONSTRAINT CK_Rooms_Status
            CHECK (RoomStatus IN (N'Active', N'Maintenance')),

        CONSTRAINT FK_Rooms_RoomTypes FOREIGN KEY (RoomTypeID)
            REFERENCES dbo.RoomTypes(RoomTypeID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    );
END;
GO

/* =========================================================
   5. BOOKINGS
   ========================================================= */

IF OBJECT_ID(N'dbo.Bookings', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Bookings
    (
        BookingID INT IDENTITY(1,1) CONSTRAINT PK_Bookings PRIMARY KEY,
        GuestID INT NOT NULL,
        RoomID INT NOT NULL,
        CheckInDate DATE NOT NULL,
        CheckOutDate DATE NOT NULL,
        NumberOfGuests INT NOT NULL
            CONSTRAINT DF_Bookings_NumberOfGuests DEFAULT (1),
        PricePerNight DECIMAL(10,2) NOT NULL,
        BookingStatus NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Bookings_BookingStatus DEFAULT (N'Confirmed'),
        CreatedAt DATETIME2(0) NOT NULL
            CONSTRAINT DF_Bookings_CreatedAt DEFAULT (SYSDATETIME()),
        CreatedByUserID INT NULL,

        CONSTRAINT CK_Bookings_Dates CHECK (CheckOutDate > CheckInDate),
        CONSTRAINT CK_Bookings_NumberOfGuests CHECK (NumberOfGuests > 0),
        CONSTRAINT CK_Bookings_Price CHECK (PricePerNight > 0),
        CONSTRAINT CK_Bookings_Status
            CHECK (BookingStatus IN
                (N'Confirmed', N'CheckedIn', N'CheckedOut', N'Cancelled')),

        CONSTRAINT FK_Bookings_Guests FOREIGN KEY (GuestID)
            REFERENCES dbo.Guests(GuestID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        CONSTRAINT FK_Bookings_Rooms FOREIGN KEY (RoomID)
            REFERENCES dbo.Rooms(RoomID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        CONSTRAINT FK_Bookings_Users FOREIGN KEY (CreatedByUserID)
            REFERENCES dbo.Users(UserID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Bookings')
      AND name = N'IX_Bookings_Room_Dates_Status'
)
BEGIN
    CREATE INDEX IX_Bookings_Room_Dates_Status
        ON dbo.Bookings(RoomID, CheckInDate, CheckOutDate, BookingStatus);
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Bookings')
      AND name = N'IX_Bookings_GuestID'
)
BEGIN
    CREATE INDEX IX_Bookings_GuestID
        ON dbo.Bookings(GuestID);
END;
GO

/* =========================================================
   6. PAYMENTS
   ========================================================= */

IF OBJECT_ID(N'dbo.Payments', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Payments
    (
        PaymentID INT IDENTITY(1,1) CONSTRAINT PK_Payments PRIMARY KEY,
        BookingID INT NOT NULL,
        PaymentAmount DECIMAL(10,2) NOT NULL,
        PaymentMethod NVARCHAR(30) NOT NULL
            CONSTRAINT DF_Payments_Method DEFAULT (N'Unspecified'),
        PaymentStatus NVARCHAR(20) NOT NULL
            CONSTRAINT DF_Payments_Status DEFAULT (N'Pending'),
        CreatedAt DATETIME2(0) NOT NULL
            CONSTRAINT DF_Payments_CreatedAt DEFAULT (SYSDATETIME()),
        CompletedAt DATETIME2(0) NULL,
        ExternalTransactionID NVARCHAR(100) NULL,

        CONSTRAINT CK_Payments_Amount CHECK (PaymentAmount > 0),
        CONSTRAINT CK_Payments_Method
            CHECK (PaymentMethod IN
                (N'Unspecified', N'Cash', N'Card', N'BankTransfer', N'Online')),
        CONSTRAINT CK_Payments_Status
            CHECK (PaymentStatus IN
                (N'Pending', N'Completed', N'Failed', N'PartiallyRefunded', N'Refunded')),

        CONSTRAINT CK_Payments_CompletedAt
            CHECK (PaymentStatus <> N'Completed' OR CompletedAt IS NOT NULL),

        CONSTRAINT FK_Payments_Bookings FOREIGN KEY (BookingID)
            REFERENCES dbo.Bookings(BookingID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.Payments')
      AND name = N'IX_Payments_BookingID_Status'
)
BEGIN
    CREATE INDEX IX_Payments_BookingID_Status
        ON dbo.Payments(BookingID, PaymentStatus);
END;
GO

/* =========================================================
   7. PAYMENT REFUNDS
   ========================================================= */

IF OBJECT_ID(N'dbo.PaymentRefunds', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PaymentRefunds
    (
        RefundID INT IDENTITY(1,1) CONSTRAINT PK_PaymentRefunds PRIMARY KEY,
        PaymentID INT NOT NULL,
        RefundAmount DECIMAL(10,2) NOT NULL,
        RefundStatus NVARCHAR(20) NOT NULL
            CONSTRAINT DF_PaymentRefunds_Status DEFAULT (N'Pending'),
        Reason NVARCHAR(250) NULL,
        CreatedAt DATETIME2(0) NOT NULL
            CONSTRAINT DF_PaymentRefunds_CreatedAt DEFAULT (SYSDATETIME()),
        CompletedAt DATETIME2(0) NULL,

        CONSTRAINT CK_PaymentRefunds_Amount CHECK (RefundAmount > 0),
        CONSTRAINT CK_PaymentRefunds_Status
            CHECK (RefundStatus IN (N'Pending', N'Completed', N'Failed')),

        CONSTRAINT CK_PaymentRefunds_CompletedAt
            CHECK (RefundStatus <> N'Completed' OR CompletedAt IS NOT NULL),

        CONSTRAINT FK_PaymentRefunds_Payments FOREIGN KEY (PaymentID)
            REFERENCES dbo.Payments(PaymentID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    );
END;
GO

/* =========================================================
   8. SERVICES
   ========================================================= */

IF OBJECT_ID(N'dbo.Services', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Services
    (
        ServiceID INT IDENTITY(1,1) CONSTRAINT PK_Services PRIMARY KEY,
        ServiceName NVARCHAR(100) NOT NULL
            CONSTRAINT UQ_Services_ServiceName UNIQUE,
        Description NVARCHAR(500) NULL,
        ServicePrice DECIMAL(10,2) NOT NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Services_IsActive DEFAULT (1),

        CONSTRAINT CK_Services_Price CHECK (ServicePrice >= 0)
    );
END;
GO

/* =========================================================
   9. BOOKING SERVICES
   ========================================================= */

IF OBJECT_ID(N'dbo.BookingServices', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.BookingServices
    (
        BookingServiceID INT IDENTITY(1,1)
            CONSTRAINT PK_BookingServices PRIMARY KEY,
        BookingID INT NOT NULL,
        ServiceID INT NOT NULL,
        Quantity INT NOT NULL
            CONSTRAINT DF_BookingServices_Quantity DEFAULT (1),
        UnitPrice DECIMAL(10,2) NOT NULL,
        CreatedAt DATETIME2(0) NOT NULL
            CONSTRAINT DF_BookingServices_CreatedAt DEFAULT (SYSDATETIME()),

        CONSTRAINT CK_BookingServices_Quantity CHECK (Quantity > 0),
        CONSTRAINT CK_BookingServices_UnitPrice CHECK (UnitPrice >= 0),

        CONSTRAINT UQ_BookingServices_Booking_Service
            UNIQUE (BookingID, ServiceID),

        CONSTRAINT FK_BookingServices_Bookings FOREIGN KEY (BookingID)
            REFERENCES dbo.Bookings(BookingID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION,

        CONSTRAINT FK_BookingServices_Services FOREIGN KEY (ServiceID)
            REFERENCES dbo.Services(ServiceID)
            ON DELETE NO ACTION
            ON UPDATE NO ACTION
    );
END;
GO

/* =========================================================
   10. VIEW: BOOKING FINANCIAL SUMMARY
   ========================================================= */

CREATE OR ALTER VIEW dbo.vw_BookingFinancialSummary
AS
SELECT
    b.BookingID,
    b.GuestID,
    b.RoomID,
    b.CheckInDate,
    b.CheckOutDate,
    b.BookingStatus,
    DATEDIFF(DAY, b.CheckInDate, b.CheckOutDate) AS Nights,
    CAST(
        DATEDIFF(DAY, b.CheckInDate, b.CheckOutDate) * b.PricePerNight
        + COALESCE(bs.ServicesTotal, 0)
        AS DECIMAL(12,2)
    ) AS BookingTotal,
    CAST(COALESCE(p.CompletedPayments, 0) AS DECIMAL(12,2)) AS CompletedPayments,
    CAST(COALESCE(r.CompletedRefunds, 0) AS DECIMAL(12,2)) AS CompletedRefunds,
    CAST(
        COALESCE(p.CompletedPayments, 0) - COALESCE(r.CompletedRefunds, 0)
        AS DECIMAL(12,2)
    ) AS NetPaid,
    CAST(
        DATEDIFF(DAY, b.CheckInDate, b.CheckOutDate) * b.PricePerNight
        + COALESCE(bs.ServicesTotal, 0)
        - COALESCE(p.CompletedPayments, 0)
        + COALESCE(r.CompletedRefunds, 0)
        AS DECIMAL(12,2)
    ) AS BalanceDue
FROM dbo.Bookings AS b
OUTER APPLY
(
    SELECT SUM(CONVERT(DECIMAL(12,2), s.Quantity * s.UnitPrice)) AS ServicesTotal
    FROM dbo.BookingServices AS s
    WHERE s.BookingID = b.BookingID
) AS bs
OUTER APPLY
(
    SELECT SUM(p.PaymentAmount) AS CompletedPayments
    FROM dbo.Payments AS p
    WHERE p.BookingID = b.BookingID
      AND p.PaymentStatus IN (N'Completed', N'PartiallyRefunded', N'Refunded')
) AS p
OUTER APPLY
(
    SELECT SUM(r.RefundAmount) AS CompletedRefunds
    FROM dbo.PaymentRefunds AS r
    INNER JOIN dbo.Payments AS p2 ON p2.PaymentID = r.PaymentID
    WHERE p2.BookingID = b.BookingID
      AND r.RefundStatus = N'Completed'
) AS r;
GO

/* =========================================================
   11. PROCEDURE: CREATE BOOKING
   Uses serializable isolation and update locks to prevent
   overlapping active bookings for the same room.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_CreateBooking
    @GuestID INT,
    @RoomID INT,
    @CheckInDate DATE,
    @CheckOutDate DATE,
    @NumberOfGuests INT = 1,
    @CreatedByUserID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CheckInDate IS NULL OR @CheckOutDate IS NULL
       OR @CheckOutDate <= @CheckInDate
    BEGIN
        THROW 50001, 'Check-out date must be after check-in date.', 1;
    END;

    IF @NumberOfGuests <= 0
    BEGIN
        THROW 50002, 'Number of guests must be positive.', 1;
    END;

    DECLARE @Price DECIMAL(10,2);
    DECLARE @Capacity INT;
    DECLARE @RoomStatus NVARCHAR(20);
    DECLARE @BookingID INT;

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM dbo.Guests WITH (UPDLOCK, HOLDLOCK)
                       WHERE GuestID = @GuestID)
            THROW 50003, 'Guest not found.', 1;

        SELECT
            @Price = r.PricePerNight,
            @Capacity = rt.Capacity,
            @RoomStatus = r.RoomStatus
        FROM dbo.Rooms AS r WITH (UPDLOCK, HOLDLOCK)
        INNER JOIN dbo.RoomTypes AS rt ON rt.RoomTypeID = r.RoomTypeID
        WHERE r.RoomID = @RoomID;

        IF @Price IS NULL
            THROW 50004, 'Room not found.', 1;

        IF @RoomStatus <> N'Active'
            THROW 50005, 'Room is not active for booking.', 1;

        IF @NumberOfGuests > @Capacity
            THROW 50006, 'Number of guests exceeds room capacity.', 1;

        IF EXISTS
        (
            SELECT 1
            FROM dbo.Bookings WITH (UPDLOCK, HOLDLOCK)
            WHERE RoomID = @RoomID
              AND BookingStatus IN (N'Confirmed', N'CheckedIn')
              AND CheckInDate < @CheckOutDate
              AND CheckOutDate > @CheckInDate
        )
            THROW 50007, 'Room is already booked for the selected dates.', 1;

        INSERT INTO dbo.Bookings
        (
            GuestID, RoomID, CheckInDate, CheckOutDate,
            NumberOfGuests, PricePerNight, BookingStatus, CreatedByUserID
        )
        VALUES
        (
            @GuestID, @RoomID, @CheckInDate, @CheckOutDate,
            @NumberOfGuests, @Price, N'Confirmed', @CreatedByUserID
        );

        SET @BookingID = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        SELECT @BookingID AS BookingID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   12. PROCEDURE: CANCEL BOOKING
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_CancelBooking
    @BookingID INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Status NVARCHAR(20);

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @Status = BookingStatus
        FROM dbo.Bookings WITH (UPDLOCK, HOLDLOCK)
        WHERE BookingID = @BookingID;

        IF @Status IS NULL
            THROW 50010, 'Booking not found.', 1;

        IF @Status IN (N'CheckedIn', N'CheckedOut')
            THROW 50011, 'Checked-in or checked-out bookings cannot be cancelled by this procedure.', 1;

        IF @Status = N'Cancelled'
            THROW 50012, 'Booking is already cancelled.', 1;

        UPDATE dbo.Bookings
        SET BookingStatus = N'Cancelled'
        WHERE BookingID = @BookingID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   13. PROCEDURE: CHANGE BOOKING STATUS
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_UpdateBookingStatus
    @BookingID INT,
    @NewStatus NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @NewStatus NOT IN (N'Confirmed', N'CheckedIn', N'CheckedOut', N'Cancelled')
        THROW 50020, 'Invalid booking status.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @CurrentStatus NVARCHAR(20);

        SELECT @CurrentStatus = BookingStatus
        FROM dbo.Bookings WITH (UPDLOCK, HOLDLOCK)
        WHERE BookingID = @BookingID;

        IF @CurrentStatus IS NULL
            THROW 50021, 'Booking not found.', 1;

        IF @CurrentStatus = N'Cancelled'
           AND @NewStatus <> N'Cancelled'
            THROW 50022, 'Cancelled bookings cannot be reactivated by this procedure.', 1;

        IF @NewStatus = N'CheckedIn'
           AND @CurrentStatus <> N'Confirmed'
            THROW 50023, 'Only confirmed bookings can be checked in.', 1;

        IF @NewStatus = N'CheckedOut'
           AND @CurrentStatus <> N'CheckedIn'
            THROW 50024, 'Only checked-in bookings can be checked out.', 1;

        UPDATE dbo.Bookings
        SET BookingStatus = @NewStatus
        WHERE BookingID = @BookingID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   14. PROCEDURE: RECORD PAYMENT
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_RecordPayment
    @BookingID INT,
    @PaymentAmount DECIMAL(10,2),
    @PaymentMethod NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @PaymentAmount <= 0
        THROW 50030, 'Payment amount must be positive.', 1;

    IF @PaymentMethod NOT IN (N'Cash', N'Card', N'BankTransfer', N'Online')
        THROW 50031, 'Invalid payment method.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Bookings WITH (UPDLOCK, HOLDLOCK)
            WHERE BookingID = @BookingID
              AND BookingStatus <> N'Cancelled'
        )
            THROW 50032, 'Booking not found or cancelled.', 1;

        INSERT INTO dbo.Payments
        (
            BookingID, PaymentAmount, PaymentMethod,
            PaymentStatus, CompletedAt
        )
        VALUES
        (
            @BookingID, @PaymentAmount, @PaymentMethod,
            N'Completed', SYSDATETIME()
        );

        DECLARE @PaymentID INT = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT @PaymentID AS PaymentID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   15. PROCEDURE: RECORD REFUND
   Validates total completed refunds against the payment amount.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_RecordRefund
    @PaymentID INT,
    @RefundAmount DECIMAL(10,2),
    @Reason NVARCHAR(250) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @RefundAmount <= 0
        THROW 50040, 'Refund amount must be positive.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @PaymentAmount DECIMAL(10,2);
        DECLARE @PaymentStatus NVARCHAR(20);
        DECLARE @ExistingRefunds DECIMAL(10,2);

        SELECT
            @PaymentAmount = PaymentAmount,
            @PaymentStatus = PaymentStatus
        FROM dbo.Payments WITH (UPDLOCK, HOLDLOCK)
        WHERE PaymentID = @PaymentID;

        IF @PaymentAmount IS NULL
            THROW 50041, 'Payment not found.', 1;

        IF @PaymentStatus NOT IN (N'Completed', N'PartiallyRefunded')
            THROW 50042, 'Only completed payments can be refunded.', 1;

        SELECT @ExistingRefunds = COALESCE(SUM(RefundAmount), 0)
        FROM dbo.PaymentRefunds WITH (UPDLOCK, HOLDLOCK)
        WHERE PaymentID = @PaymentID
          AND RefundStatus IN (N'Pending', N'Completed');

        IF @ExistingRefunds + @RefundAmount > @PaymentAmount
            THROW 50043, 'Total refunds cannot exceed the payment amount.', 1;

        INSERT INTO dbo.PaymentRefunds
        (
            PaymentID, RefundAmount, RefundStatus, Reason, CompletedAt
        )
        VALUES
        (
            @PaymentID, @RefundAmount, N'Completed', @Reason, SYSDATETIME()
        );

        DECLARE @TotalRefunded DECIMAL(10,2) =
        (
            SELECT SUM(RefundAmount)
            FROM dbo.PaymentRefunds
            WHERE PaymentID = @PaymentID
              AND RefundStatus = N'Completed'
        );

        UPDATE dbo.Payments
        SET PaymentStatus =
            CASE
                WHEN @TotalRefunded >= PaymentAmount THEN N'Refunded'
                ELSE N'PartiallyRefunded'
            END
        WHERE PaymentID = @PaymentID;

        DECLARE @RefundID INT = CONVERT(INT, SCOPE_IDENTITY());

        COMMIT TRANSACTION;

        SELECT @RefundID AS RefundID;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   16. PROCEDURE: ADD SERVICE TO BOOKING
   Saves the current service price as a historical snapshot.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_AddServiceToBooking
    @BookingID INT,
    @ServiceID INT,
    @Quantity INT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @Quantity <= 0
        THROW 50050, 'Quantity must be positive.', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS
        (
            SELECT 1
            FROM dbo.Bookings WITH (UPDLOCK, HOLDLOCK)
            WHERE BookingID = @BookingID
              AND BookingStatus IN (N'Confirmed', N'CheckedIn')
        )
            THROW 50051, 'Booking not found or not active.', 1;

        DECLARE @ServicePrice DECIMAL(10,2);

        SELECT @ServicePrice = ServicePrice
        FROM dbo.Services WITH (UPDLOCK, HOLDLOCK)
        WHERE ServiceID = @ServiceID
          AND IsActive = 1;

        IF @ServicePrice IS NULL
            THROW 50052, 'Service not found or inactive.', 1;

        IF EXISTS
        (
            SELECT 1 FROM dbo.BookingServices WITH (UPDLOCK, HOLDLOCK)
            WHERE BookingID = @BookingID AND ServiceID = @ServiceID
        )
        BEGIN
            UPDATE dbo.BookingServices
            SET Quantity = Quantity + @Quantity
            WHERE BookingID = @BookingID AND ServiceID = @ServiceID;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.BookingServices
                (BookingID, ServiceID, Quantity, UnitPrice)
            VALUES
                (@BookingID, @ServiceID, @Quantity, @ServicePrice);
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

/* =========================================================
   17. VIEW: ROOM AVAILABILITY FOR A DATE RANGE
   Use parameters in application queries or adapt this query.
   ========================================================= */

CREATE OR ALTER PROCEDURE dbo.usp_GetAvailableRooms
    @CheckInDate DATE,
    @CheckOutDate DATE,
    @NumberOfGuests INT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @CheckInDate IS NULL OR @CheckOutDate IS NULL
       OR @CheckOutDate <= @CheckInDate
        THROW 50060, 'Check-out date must be after check-in date.', 1;

    IF @NumberOfGuests <= 0
        THROW 50061, 'Number of guests must be positive.', 1;

    SELECT
        r.RoomID,
        r.RoomNumber,
        rt.TypeName AS RoomType,
        r.PricePerNight,
        rt.Capacity
    FROM dbo.Rooms AS r
    INNER JOIN dbo.RoomTypes AS rt ON rt.RoomTypeID = r.RoomTypeID
    WHERE r.RoomStatus = N'Active'
      AND rt.Capacity >= @NumberOfGuests
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.Bookings AS b
          WHERE b.RoomID = r.RoomID
            AND b.BookingStatus IN (N'Confirmed', N'CheckedIn')
            AND b.CheckInDate < @CheckOutDate
            AND b.CheckOutDate > @CheckInDate
      )
    ORDER BY r.RoomNumber;
END;
GO

/* =========================================================
   18. EXAMPLE QUERIES
   ========================================================= */

-- View all rooms and their types.
-- SELECT r.RoomID, r.RoomNumber, rt.TypeName, r.PricePerNight, r.RoomStatus
-- FROM dbo.Rooms AS r
-- INNER JOIN dbo.RoomTypes AS rt ON rt.RoomTypeID = r.RoomTypeID;

-- View the financial summary for all bookings.
-- SELECT * FROM dbo.vw_BookingFinancialSummary;

-- Find rooms available for a selected date range.
-- EXEC dbo.usp_GetAvailableRooms
--     @CheckInDate = '2026-11-10',
--     @CheckOutDate = '2026-11-15',
--     @NumberOfGuests = 2;

-- Create a booking after inserting a guest and a room.
-- EXEC dbo.usp_CreateBooking
--     @GuestID = 1,
--     @RoomID = 1,
--     @CheckInDate = '2026-11-10',
--     @CheckOutDate = '2026-11-15',
--     @NumberOfGuests = 2,
--     @CreatedByUserID = NULL;

-- Record a payment for a booking.
-- EXEC dbo.usp_RecordPayment
--     @BookingID = 1,
--     @PaymentAmount = 100.00,
--     @PaymentMethod = N'Cash';

-- Cancel a booking.
-- EXEC dbo.usp_CancelBooking @BookingID = 1;
GO
