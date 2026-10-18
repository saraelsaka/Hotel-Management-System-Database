# Hotel Management System Database

## Overview

This database is designed for a Hotel Management System using Microsoft SQL Server and T-SQL.

It manages hotel rooms, guests, bookings, payments, refunds, and additional services. It also includes stored procedures for handling booking operations and maintaining data integrity.

## Technologies Used

* Microsoft SQL Server
* T-SQL

## Database Structure

The database contains the following tables.

| Table             | Description                                                                      |
| ----------------- | -------------------------------------------------------------------------------- |
| `Roles`           | Stores user roles such as Admin, Receptionist, and Manager.                      |
| `Users`           | Stores user account information and role assignments.                            |
| `Guests`          | Stores guest information.                                                        |
| `RoomTypes`       | Stores room types, descriptions, prices, and capacities.                         |
| `Rooms`           | Stores room details, prices, and availability status.                            |
| `Bookings`        | Stores reservations, check-in and check-out dates, and booking status.           |
| `Payments`        | Stores payment transactions and their statuses.                                  |
| `PaymentRefunds`  | Stores refund records associated with payments.                                  |
| `Services`        | Stores additional hotel services and their prices.                               |
| `BookingServices` | Connects additional services to bookings and stores their quantities and prices. |

## Database Features

### 1. Data Integrity

* Primary keys and foreign keys define relationships between tables.
* Unique constraints prevent duplicate values where required.
* Check constraints validate dates, prices, quantities, capacities, and statuses.
* Default constraints provide initial values for selected columns.
* Indexes support common booking and payment queries.

### 2. Booking Management

The database supports:

* Creating bookings.
* Checking room availability for a date range.
* Preventing overlapping active bookings through the booking procedure.
* Validating guest counts against room capacity.
* Cancelling bookings.
* Updating booking statuses.

### 3. Payment Management

The database supports:

* Recording payments.
* Tracking payment statuses.
* Recording refunds.
* Validating refund amounts against the original payment amount.

### 4. Additional Services

* Defining hotel services and their prices.
* Adding services to bookings.
* Recording service quantities and prices at the time of booking.

### 5. Views and Stored Procedures

The database includes the following database objects.

#### View

* `vw_BookingFinancialSummary` — provides booking totals, completed payments, refunds, net payments, and outstanding balances.

#### Stored Procedures

* `usp_CreateBooking` — creates a booking after validating the room, guest, dates, capacity, and existing reservations.
* `usp_CancelBooking` — cancels eligible bookings.
* `usp_UpdateBookingStatus` — updates booking statuses according to the defined rules.
* `usp_RecordPayment` — records a payment for a booking.
* `usp_RecordRefund` — records a refund and updates the payment status.
* `usp_AddServiceToBooking` — adds a service to a booking.
* `usp_GetAvailableRooms` — returns rooms available for the requested dates and guest count.

## Getting Started

### Prerequisites

* Microsoft SQL Server
* SQL Server Management Studio (SSMS) or another compatible SQL Server client.

### Installation

1. Clone or download the repository.
2. Open SQL Server Management Studio.
3. Open `HotelManagementSystem.sql`.
4. Execute the script.
5. Verify that the `HotelManagementSystem` database and its objects were created successfully.

The script creates the database if it does not exist, creates missing tables, inserts default roles and room types when needed, and creates or updates the defined views and stored procedures.

**Note:** Review the script and test it in a development environment before running it against an existing database.

## Project Structure

```text
Database/
├── HotelManagementSystem.sql
└── README.md
```

## Purpose

This database demonstrates relational database design, data integrity constraints, indexing, transaction handling, stored procedures, and SQL Server programming for a hotel reservation system.