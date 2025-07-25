# Task Management Smart Contract

A Clarity smart contract for managing task-based work agreements between clients and contractors with milestone-based payment releases.

## Overview

This smart contract facilitates a structured workflow for task management where clients can create tasks, assign contractors, and release payments based on completed and verified work phases. The contract ensures secure milestone-based payments and proper authorization controls.

## Key Features

- **Task Creation**: Clients can create new tasks with detailed specifications
- **Contractor Assignment**: Secure assignment of contractors to specific tasks
- **Phase-based Progress**: Work is divided into manageable phases/milestones
- **Approval Workflow**: Client verification required before payment release
- **Payment Security**: Payments are only released after phase verification
- **Progress Tracking**: Real-time tracking of completed vs total phases

## Contract Structure

### Data Storage

**Tasks Map:**
- `task-id` → Task details including client, contractor, budget, and progress
- Tracks: name, details, total amount, phase count, completion status

**Phase Info Map:**
- `{task-id, phase-id}` → Individual phase details
- Tracks: description, verification status, payment status

### Core Functions

#### Public Functions

1. **`create-task`**
   - Creates a new task with specified parameters
   - Only contract admin can create tasks
   - Returns: new task ID

2. **`assign-contractor`**
   - Assigns a contractor principal to an existing task
   - Only task client can assign contractors
   - Returns: success confirmation

3. **`submit-phase`**
   - Contractor submits completed work for a specific phase
   - Only assigned contractor can submit phases
   - Returns: success confirmation

4. **`verify-phase`**
   - Client verifies and approves completed phase work
   - Only task client can verify phases
   - Automatically increments completed phase counter
   - Returns: success confirmation

5. **`release-payment`**
   - Releases payment for a verified phase
   - Only task client can release payments
   - Phase must be verified before payment release
   - Returns: success confirmation

6. **`complete-task`**
   - Marks entire task as finished
   - Only available when all phases are completed
   - Only task client can mark completion
   - Returns: success confirmation

#### Read-Only Functions

- **`get-task-details`**: Retrieve complete task information
- **`get-phase-details`**: Retrieve specific phase information

## Workflow

1. **Task Creation**: Admin creates a task with name, details, budget, and total phases
2. **Contractor Assignment**: Client assigns a contractor to the task
3. **Phase Submission**: Contractor submits work for individual phases
4. **Phase Verification**: Client reviews and verifies completed phases
5. **Payment Release**: Client releases payment for verified phases
6. **Task Completion**: Once all phases are complete, task is marked as finished

## Security Features

- **Authorization Controls**: Role-based access for all operations
- **State Validation**: Prevents duplicate approvals and payments
- **Progress Tracking**: Ensures all phases are completed before task closure
- **Error Handling**: Comprehensive error codes for debugging

## Error Codes

- `u100`: Not authorized for this operation
- `u101`: Task not found
- `u102`: Phase not found  
- `u103`: Invalid contractor (not assigned to task)
- `u104`: Phase already verified
- `u105`: Phase already paid
- `u106`: Task already finished

## Usage Example

```clarity
;; Create a new task
(create-task "Website Development" "Build responsive website" u1000 u5)

;; Assign contractor
(assign-contractor u1 'SP1234...CONTRACTOR)

;; Submit phase work
(submit-phase u1 u1 "Homepage design completed")

;; Verify phase
(verify-phase u1 u1)

;; Release payment
(release-payment u1 u1)
```
